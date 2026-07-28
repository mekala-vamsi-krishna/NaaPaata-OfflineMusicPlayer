//
//  MatchedGeometryIfAvailable.swift
//  NaaPaata
//
//  Created by Mekala Vamsi Krishna on 7/26/26.
//

import SwiftUI

struct MatchedGeometryIfAvailable: ViewModifier {
    let id: String?
    let namespace: Namespace.ID?

    func body(content: Content) -> some View {
        if let id = id, let namespace = namespace {
            content.matchedGeometryEffect(id: id, in: namespace)
        } else {
            content
        }
    }
}
