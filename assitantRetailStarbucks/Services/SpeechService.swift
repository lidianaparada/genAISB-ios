import Foundation
import Speech
import AVFoundation
import Combine

class SpeechService: NSObject, ObservableObject {
    
    @Published var isListening = false
    @Published var recognizedText = ""
    @Published var statusMessage = "Listo"
    @Published var isAuthorized = false
    
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "es-MX"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    // Timer para timeout
    private var listeningTimer: Timer?
    private let maxListeningDuration: TimeInterval = 15.0 // 15 segundos máximo
    
    var onFinalResult: ((String) -> Void)?
    
    override init() {
        super.init()
        requestAuthorization()
        checkMicrophonePermission()
    }
    
    // MARK: - Authorization
    func requestAuthorization() {
        SFSpeechRecognizer.requestAuthorization { [weak self] authStatus in
            DispatchQueue.main.async {
                switch authStatus {
                case .authorized:
                    self?.isAuthorized = true
                    print("✅ Permiso de voz concedido")
                case .denied:
                    self?.isAuthorized = false
                    print("❌ Permiso de voz denegado")
                case .restricted:
                    self?.isAuthorized = false
                    print("❌ Voz restringida en este dispositivo")
                case .notDetermined:
                    self?.isAuthorized = false
                    print("⚠️ Permiso de voz no determinado")
                @unknown default:
                    self?.isAuthorized = false
                }
            }
        }
        
        // Permisos de audio
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            print(granted ? "✅ Permiso de audio concedido" : "❌ Permiso de audio denegado")
        }
    }
    
    // MARK: - Helper para verificar permisos
    func checkMicrophonePermission() {
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            if granted {
                print("✅ Permiso de micrófono OK")
            } else {
                print("❌ Permiso de micrófono denegado")
            }
        }
    }
    
    // MARK: - Start Listening
    func startListening() {
        guard isAuthorized else {
            print("❌ No hay permisos de voz")
            return
        }
        
        // Cancelar cualquier reconocimiento anterior
        if recognitionTask != nil {
            recognitionTask?.cancel()
            recognitionTask = nil
        }
        
        // Configurar sesión de audio
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("❌ Error configurando audio: \(error)")
            return
        }
        
        // Crear request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            print("❌ No se pudo crear request")
            return
        }
        
        let inputNode = audioEngine.inputNode
        
        // Configuración mejorada
        recognitionRequest.shouldReportPartialResults = true
        
        // Configurar para detectar mejor el final del habla
        if #available(iOS 13, *) {
            recognitionRequest.requiresOnDeviceRecognition = false
        }
        
        // Variable para controlar el habla detectada
        var hasSpeech = false
        
        // Tarea de reconocimiento
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }
            
            if let result = result {
                let transcription = result.bestTranscription.formattedString
                
                DispatchQueue.main.async {
                    self.recognizedText = transcription
                }
                
                // Si hay texto, marcar que hubo habla
                if !transcription.isEmpty {
                    hasSpeech = true
                    print("🎙️ Reconociendo: \(transcription)")
                }
                
                // Solo finalizar si es el resultado final del sistema
                if result.isFinal {
                    print("🎙️ Reconocimiento final: \(transcription)")
                    self.stopListening()
                    if !transcription.isEmpty {
                        self.onFinalResult?(transcription)
                    }
                }
            }
            
            if let error = error {
                let nsError = error as NSError
                
                // Ignorar error de "no speech" si ya hubo habla
                if nsError.domain == "kAFAssistantErrorDomain" && nsError.code == 1101 {
                    if hasSpeech && !self.recognizedText.isEmpty {
                        print("🎙️ Silencio detectado, procesando: \(self.recognizedText)")
                        self.stopListening()
                        self.onFinalResult?(self.recognizedText)
                    } else {
                        print("⚠️ No se detectó voz, reintentando...")
                        self.stopListening()
                        // Reintentar después de un segundo
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            if !self.isListening {
                                self.startListening()
                            }
                        }
                    }
                } else {
                    print("❌ Error reconociendo: \(error.localizedDescription)")
                    self.stopListening()
                }
            }
        }
        
        // Configurar formato de audio
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            recognitionRequest.append(buffer)
        }
        
        // Iniciar motor de audio
        audioEngine.prepare()
        do {
            try audioEngine.start()
            DispatchQueue.main.async {
                self.isListening = true
                self.statusMessage = "🎤 Escuchando..."
                self.recognizedText = ""
            }
            
            // Configurar timeout de seguridad
            DispatchQueue.main.async {
                self.listeningTimer?.invalidate()
                self.listeningTimer = Timer.scheduledTimer(withTimeInterval: self.maxListeningDuration, repeats: false) { [weak self] _ in
                    guard let self = self else { return }
                    if self.isListening {
                        print("⏱️ Timeout de escucha alcanzado (15 seg)")
                        if !self.recognizedText.isEmpty {
                            self.stopListening()
                            self.onFinalResult?(self.recognizedText)
                        } else {
                            self.stopListening()
                            print("⚠️ No se detectó voz en el tiempo límite")
                        }
                    }
                }
            }
            
            print("🎙️ Micrófono activado")
        } catch {
            print("❌ Error iniciando motor: \(error)")
        }
    }
    
    // MARK: - Stop Listening
    func stopListening() {
        // Cancelar timer
        listeningTimer?.invalidate()
        listeningTimer = nil
        
        // Detener motor de audio
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        
        // Finalizar request
        recognitionRequest?.endAudio()
        
        // Cancelar tarea
        recognitionTask?.cancel()
        
        DispatchQueue.main.async {
            self.isListening = false
            self.statusMessage = "Listo"
        }
        
        print("🛑 Micrófono detenido")
    }
}
