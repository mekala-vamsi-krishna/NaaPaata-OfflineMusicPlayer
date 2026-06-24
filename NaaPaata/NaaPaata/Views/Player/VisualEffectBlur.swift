//
//  VisualEffectBlur.swift
//  NaaPaata
//
//  Created by Mekala Vamsi Krishna on 6/24/26.
//

import SwiftUI

struct VisualEffectBlur: UIViewRepresentable {
    let blurStyle: UIBlurEffect.Style

    func makeUIView(context: Context) -> UIVisualEffectView {
        let view = UIVisualEffectView(effect: UIBlurEffect(style: blurStyle))
        return view
    }

    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
}
