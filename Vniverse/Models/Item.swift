//
//  Item.swift
//  Vniverse
//
//  Created by chii_magnus on 2025/1/28.
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
