//
//  PlaylistViewMode.swift
//  NaaPaataForMac
//
//  Created by Mekala Vamsi Krishna on 9/16/26.
//

import Foundation

enum PlaylistViewMode: String, CaseIterable {
    case grid, list

    var systemImage: String {
        switch self {
        case .grid: return "square.grid.2x2"
        case .list: return "list.bullet"
        }
    }

    var help: String {
        switch self {
        case .grid: return "Grid View"
        case .list: return "List View"
        }
    }
}
