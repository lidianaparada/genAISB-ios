//
//  AudioService.swift
//  assitantRetailStarbucks
//
//  Created by Lidiana Parada on 14/11/25.
//

import Foundation
import AVFoundation
import Combine 

class AudioService: NSObject, ObservableObject {
    
    @Published var isSpeaking = false
    
    private var audioPlayer: AVAudioPlayer?
    var onAudioFinished: (() -> Void)?
    
    // MARK: - Play Audio from Data
    func playAudio(data: Data) {
        do {
            // Guardar en archivo temporal
            let tempURL = FileManager.default.temporaryDirectory
                .appendingPathComponent("tts_\(UUID().uuidString).mp3")
            try data.write(to: tempURL)
            
            // Configurar sesión de audio
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            
            // Crear player
            audioPlayer = try AVAudioPlayer(contentsOf: tempURL)
            audioPlayer?.delegate = self
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
            
            isSpeaking = true
            print("🔊 Reproduciendo audio")
            
        } catch {
            print("❌ Error reproduciendo audio: \(error)")
            isSpeaking = false
        }
    }
    
    // MARK: - Stop Audio
    func stopAudio() {
        audioPlayer?.stop()
        audioPlayer = nil
        isSpeaking = false
        print("🛑 Audio detenido")
    }
   
    // MARK: - Play Beep
    func playBeep() {
        // Sonido más claro para indicar que está escuchando
        AudioServicesPlaySystemSound(1114) // Tock sound
        
        // O usa este para un beep diferente al finalizar
        // AudioServicesPlaySystemSound(1105)
    }
}

// MARK: - AVAudioPlayerDelegate
extension AudioService: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        isSpeaking = false
        print("✅ Audio terminado")
        onAudioFinished?()
    }
    
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        print("❌ Error decodificando audio: \(error?.localizedDescription ?? "")")
        isSpeaking = false
    }
}
