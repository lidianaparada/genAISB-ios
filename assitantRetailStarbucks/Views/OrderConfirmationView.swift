//
//  OrderConfirmationView.swift
//  assitantRetailStarbucks
//
//  Created by Lidiana Parada on 14/11/25.
//

import SwiftUI

struct OrderConfirmationView: View {
    let orderData: OrderData
    let onNewOrder: () -> Void
    let onDismiss: () -> Void
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    
                    // MARK: - Header
                    VStack {
                        Image(systemName: "checkmark.circle.fill")
                            .resizable()
                            .frame(width: 60, height: 60)
                            .foregroundColor(.green)
                        
                        Text("¡Pedido Confirmado!")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Número de orden: \(orderData.orderNumber)")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    
                    Divider()
                    
                    // MARK: - Order Details
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Tu Pedido", systemImage: "bag.fill")
                            .font(.headline)
                        
                        ForEach(orderData.detalles, id: \.nombre) { detalle in
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(detalle.nombre)
                                        .font(.body)
                                    
                                    if let tamano = detalle.tamano, !tamano.isEmpty {
                                        Text(tamano)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                
                                Spacer()
                                
                                Text("$\(detalle.precio, specifier: "%.2f")")
                                    .font(.body)
                                    .fontWeight(.medium)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    Divider()
                    
                    // MARK: - Location & Payment
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Label("Sucursal", systemImage: "mappin.circle.fill")
                            Spacer()
                            Text(orderData.sucursal)
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Label("Pago", systemImage: "creditcard.fill")
                            Spacer()
                            Text(orderData.metodoPago)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    Divider()
                    
                    // MARK: - Total
                    VStack(spacing: 8) {
                        HStack {
                            Text("Total")
                                .font(.title3)
                                .fontWeight(.bold)
                            Spacer()
                            Text("$\(orderData.total, specifier: "%.2f")")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.green)
                        }
                        
                        HStack {
                            Text("⭐ Estrellas ganadas")
                                .font(.subheadline)
                            Spacer()
                            Text("\(orderData.estrellas)")
                                .font(.headline)
                                .foregroundColor(.orange)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    Spacer(minLength: 20)
                    
                    // MARK: - Buttons
                    VStack(spacing: 12) {
                        Button(action: {
                            onDismiss()
                            onNewOrder()
                        }) {
                            Text("Hacer Otro Pedido")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.green)
                                .cornerRadius(12)
                        }
                        
                        Button(action: {
                            onDismiss()
                        }) {
                            Text("Cerrar")
                                .font(.headline)
                                .foregroundColor(.primary)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(.systemGray5))
                                .cornerRadius(12)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Confirmación")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct OrderConfirmationView_Previews: PreviewProvider {
    static var previews: some View {
        OrderConfirmationView(
            orderData: OrderData(
                orderNumber: "SBX123456",
                total: 157.0,
                estrellas: 7,
                sucursal: "Starbucks Condesa",
                metodoPago: "Efectivo",
                detalles: [
                    OrderData.OrderDetail(tipo: "bebida", nombre: "Latte", tamano: "Grande", precio: 71.0),
                    OrderData.OrderDetail(tipo: "alimento", nombre: "Croissant", tamano: nil, precio: 86.0)
                ],
                modificadores: nil,
                timestamp: 1234567890,
                status: "completed"
            ),
            onNewOrder: {},
            onDismiss: {}
        )
    }
}
