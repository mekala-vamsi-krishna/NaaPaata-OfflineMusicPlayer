//
//  RepeatMode.swift
//  NaaPaata
//
//  Created by Mekala Vamsi Krishna on 9/26/26.
//

import Foundation

enum RepeatMode: String, CaseIterable {
    case off, all, one

    var systemImage: String {
        switch self {
        case .off, .all: return "repeat"
        case .one:       return "repeat.1"
        }
    }
}
