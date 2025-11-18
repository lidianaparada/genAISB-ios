//
//  OrderData.swift
//  assitantRetailStarbucks
//
//  Created by Lidiana Parada on 14/11/25.
//

import Foundation

struct OrderData: Codable {
    let orderNumber: String
    let total: Double
    let estrellas: Int
    let sucursal: String
    let metodoPago: String
    let detalles: [OrderDetail]
    let modificadores: [Modificador]?
    let timestamp: Int64
    let status: String
    
    struct OrderDetail: Codable {
        let tipo: String
        let nombre: String
        let tamano: String?
        let precio: Double
    }
    
    struct Modificador: Codable {
        let grupoId: String
        let opcionId: String
    }
}
