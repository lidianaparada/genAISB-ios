//
//  NetworkService.swift
//  assitantRetailStarbucks
//
//  Created by Lidiana Parada on 14/11/25.
//

import Foundation

class NetworkService {
    static let shared = NetworkService()
    
    // ⚠️ CAMBIAR A TU IP
    //private let baseURL = "http://192.168.100.109:3000"
    private let baseURL = "https://genai-sborion.onrender.com"
    
    private init() {}
    
    // MARK: - Send Chat Message
    func sendMessage(
        userInput: String,
        sessionId: String,
        userName: String,
        history: [[String: String]]
    ) async throws -> ChatResponse {
        
        guard let url = URL(string: "\(baseURL)/chat") else {
            throw NetworkError.invalidURL
        }
        
        let payload: [String: Any] = [
            "userInput": userInput,
            "sessionId": sessionId,
            "userName": userName,
            "history": history
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        request.timeoutInterval = 30
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw NetworkError.serverError(httpResponse.statusCode)
        }
        
        let decoder = JSONDecoder()
        return try decoder.decode(ChatResponse.self, from: data)
    }
    
    // MARK: - Get TTS Audio
    func getTTSAudio(text: String) async throws -> Data {
        guard let url = URL(string: "\(baseURL)/speak") else {
            throw NetworkError.invalidURL
        }
        
        let payload: [String: Any] = ["text": text]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        request.timeoutInterval = 30
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw NetworkError.serverError(0)
        }
        
        return data
    }
}

// MARK: - Response Models
struct ChatResponse: Codable {
    let reply: String
    let responseTime: Int?
    let context: Context?
    let suggestions: [String]?
    let orderComplete: Bool?
    let orderData: OrderData?
    let currentStep: String?
    
    struct Context: Codable {
        let listoParaOrdenar: Bool?
        let sucursal: String?
        let bebida: String?
        let tamano: String?
        let metodoPago: String?
    }
}

// MARK: - Network Errors
enum NetworkError: LocalizedError {
    case invalidURL
    case invalidResponse
    case serverError(Int)
    case decodingError
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "URL inválida"
        case .invalidResponse:
            return "Respuesta inválida del servidor"
        case .serverError(let code):
            return "Error del servidor: \(code)"
        case .decodingError:
            return "Error al procesar respuesta"
        }
    }
}
