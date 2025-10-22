//
//  Item.swift
//  scv-apple
//
//  Created by Visakha on 22/10/2025.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
