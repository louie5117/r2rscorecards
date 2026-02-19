//
//  Item.swift
//  r2rscorecards
//
//  Created by Paul Lewis on 19/02/2026.
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
