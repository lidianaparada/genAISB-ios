//
//  ChatViewModel.swift
//  assitantRetailStarbucks
//
//  Created by Lidiana Parada on 14/11/25.
//

import Foundation
import Combine

@MainActor
class ChatViewModel: ObservableObject {
    
    @Published var messages: [ChatMessage] = []
    @Published var statusMessage = "Listo"
    @Published var showOrderConfirmation = false
    @Published var currentOrderData: OrderData?
    
    private let networkService = NetworkService.shared
    let speechService = SpeechService()
    let audioService = AudioService()
    
    private var sessionId: String = ""
    private let userName = "Lidy" // ⚠️ Puedes personalizar
    private var conversationHistory: [[String: String]] = []
    
    init() {
        generateNewSessionId()
        setupServices()
        
        // Solicitar saludo inicial después de un breve delay
        Task {
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 segundos
            await requestInitialGreeting()
        }
    }
    
    // MARK: - Setup
    private func setupServices() {
        // Callback cuando termina de hablar
        speechService.onFinalResult = { [weak self] text in
            guard let self = self else { return }
            Task {
                await self.handleUserInput(text)
            }
        }
        
        // Callback cuando termina el audio - MEJORADO
        audioService.onAudioFinished = { [weak self] in
            guard let self = self else { return }
            print("✅ Audio terminado, esperando para activar micrófono...")
            Task {
                // Esperar un poco más para que el usuario se prepare
                try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 segundo
                
                // Verificar que no esté hablando antes de activar
                if !self.audioService.isSpeaking {
                    print("🎙️ Activando micrófono para nueva entrada...")
                    await self.startListening()
                }
            }
        }
    }
    
    // MARK: - Session Management
    private func generateNewSessionId() {
        sessionId = "ios_user_\(UUID().uuidString.prefix(8))"
        print("📱 SessionId generado: \(sessionId)")
    }
    
    func newOrder() {
        print("🔄 Iniciando nuevo pedido")
        
        // Limpiar estado
        messages.removeAll()
        conversationHistory.removeAll()
        showOrderConfirmation = false
        currentOrderData = nil
        
        // Nuevo sessionId
        generateNewSessionId()
        
        // Solicitar saludo inicial
        Task {
            try? await Task.sleep(nanoseconds: 500_000_000)
            await requestInitialGreeting()
        }
    }
    
    // MARK: - Initial Greeting
    func requestInitialGreeting() async {
        statusMessage = "Iniciando asistente..."
        
        do {
            let response = try await networkService.sendMessage(
                userInput: "",
                sessionId: sessionId,
                userName: userName,
                history: []
            )
            
            addBotMessage(response.reply)
            await speakText(response.reply)
            
        } catch {
            print("❌ Error obteniendo saludo: \(error)")
            addBotMessage("⚠️ Error de conexión con el servidor.")
            statusMessage = "Error"
        }
    }
    
    // MARK: - Handle User Input
    func handleUserInput(_ text: String) async {
            print("👤 Usuario dijo: '\(text)'")
            print("📊 Historial actual: \(conversationHistory.count) mensajes")
            
            addUserMessage(text)
            statusMessage = "Generando respuesta..."
        
        do {
            let response = try await networkService.sendMessage(
                userInput: text,
                sessionId: sessionId,
                userName: userName,
                history: conversationHistory
            )
            
            // Actualizar historial
            conversationHistory.append(["role": "user", "content": text])
            conversationHistory.append(["role": "assistant", "content": response.reply])
            
            addBotMessage(response.reply)
            await speakText(response.reply)
            
            // Verificar si la orden está completa
            if let orderComplete = response.orderComplete, orderComplete,
               let orderData = response.orderData {
                // Esperar a que termine el TTS
                try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 segundos
                currentOrderData = orderData
                showOrderConfirmation = true
            }
            
        } catch {
            print("❌ Error enviando mensaje: \(error)")
            addBotMessage("❌ Error: \(error.localizedDescription)")
            statusMessage = "Error"
            
            // Reintentar escuchar
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            await startListening()
        }
    }
    
  
    func startListening() async {
        guard !audioService.isSpeaking else {
            print("⚠️ No se puede escuchar mientras habla")
            return
        }
        
        audioService.playBeep() // Beep al iniciar
        speechService.startListening()
    }
    
    func stopListening() {
        speechService.stopListening()
    }
    
    private func speakText(_ text: String) async {
        print("🔊 Iniciando TTS: '\(text.prefix(50))...'")
        statusMessage = "Asistente hablando..."
        
        do {
            let audioData = try await networkService.getTTSAudio(text: text)
            audioService.playAudio(data: audioData)
        } catch {
            print("❌ Error TTS: \(error)")
            audioService.isSpeaking = false
            statusMessage = "Error"
            
            // Reactivar micrófono después de un delay
            try? await Task.sleep(nanoseconds: 600_000_000)
            await startListening()
        }
    }
    
    // MARK: - Messages
    private func addUserMessage(_ text: String) {
        messages.append(ChatMessage(text: text, isUser: true))
    }
    
    private func addBotMessage(_ text: String) {
        messages.append(ChatMessage(text: text, isUser: false))
    }
}
