//
//  Color+Ext.swift
//  NaaPaata
//
//  Created by Mekala Vamsi Krishna on 10/15/26.
//

import SwiftUI

extension Color {

    /// The app accent color used everywhere
    static let appAccent = Color(
        red: 0.61,
        green: 0.11,
        blue: 0.66
    )
}

extension ShapeStyle where Self == Color {
    static var appAccent: Color { .appAccent }
}
