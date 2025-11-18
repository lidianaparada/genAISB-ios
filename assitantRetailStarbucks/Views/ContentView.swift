//
//  ContentView.swift
//  assitantRetailStarbucks
//
//  Created by Lidiana Parada on 14/11/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = ChatViewModel()
    @State private var isListeningAnimation = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                
                // MARK: - Status Bar
                HStack {
                    Image(systemName: statusIcon)
                        .foregroundColor(statusColor)
                        .scaleEffect(isListeningAnimation ? 1.3 : 1.0)
                        .animation(
                            viewModel.speechService.isListening ?
                                .easeInOut(duration: 0.5).repeatForever(autoreverses: true) :
                                .default,
                            value: isListeningAnimation
                        )
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(viewModel.statusMessage)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        // Mostrar texto reconocido en tiempo real
                        if !viewModel.speechService.recognizedText.isEmpty {
                            Text(viewModel.speechService.recognizedText)
                                .font(.caption)
                                .foregroundColor(.blue)
                                .lineLimit(2)
                        }
                    }
                    
                    Spacer()
                }
                .padding()
                .background(Color(.systemGray6))
                
                // MARK: - Chat Messages
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(viewModel.messages) { message in
                                ChatBubbleView(message: message)
                                    .id(message.id)
                            }
                        }
                        .padding()
                    }
                    .onChange(of: viewModel.messages.count) { _ in
                        if let lastMessage = viewModel.messages.last {
                            withAnimation {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                }
                
                // MARK: - Control Button
                Button(action: {
                    if viewModel.speechService.isListening {
                        viewModel.stopListening()
                        viewModel.audioService.stopAudio()
                    } else {
                        Task {
                            await viewModel.startListening()
                        }
                    }
                }) {
                    Image(systemName: viewModel.speechService.isListening ? "stop.circle.fill" : "mic.circle.fill")
                        .resizable()
                        .frame(width: 60, height: 60)
                        .foregroundColor(viewModel.speechService.isListening ? .red : .green)
                }
                .padding()
            }
            .navigationTitle("☕ Starbucks Assistant")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $viewModel.showOrderConfirmation) {
                if let orderData = viewModel.currentOrderData {
                    OrderConfirmationView(
                        orderData: orderData,
                        onNewOrder: {
                            viewModel.newOrder()
                        },
                        onDismiss: {
                            viewModel.showOrderConfirmation = false
                        }
                    )
                }
            }
            .onAppear {
                isListeningAnimation = viewModel.speechService.isListening
            }
            .onChange(of: viewModel.speechService.isListening) { newValue in
                isListeningAnimation = newValue
            }
        }
    }
    
    // MARK: - Status Helpers
    private var statusIcon: String {
        if viewModel.audioService.isSpeaking {
            return "speaker.wave.3.fill"
        } else if viewModel.speechService.isListening {
            return "mic.fill"
        } else {
            return "checkmark.circle.fill"
        }
    }
    
    private var statusColor: Color {
        if viewModel.audioService.isSpeaking {
            return .blue
        } else if viewModel.speechService.isListening {
            return .red
        } else {
            return .green
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
