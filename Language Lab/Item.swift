//
//  Item.swift
//  Language Lab
//
//  Created by Elias Amal on 2025-03-14.
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
