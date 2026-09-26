//
//  ArtworkView.swift
//  NaaPaataForMac
//
//  Created by Mekala Vamsi Krishna on 9/11/26.
//

import SwiftUI
import AppKit

struct ArtworkView: View {
    let data: Data?
    var size: CGFloat
    var cornerRadius: CGFloat = 6

    var body: some View {
        Group {
            if let data, let image = NSImage(data: data) {
                Image(nsImage: image)
                    .resizable()
                    .interpolation(.high)
                    .aspectRatio(contentMode: .fill)
            } else {
                placeholder
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .strokeBorder(AppColor.primary.opacity(0.08))
        )
    }

    private var placeholder: some View {
        ZStack {
            AppColor.brandGradient
            Image(systemName: "music.note")
                .font(.system(size: size * 0.42, weight: .light))
                .foregroundStyle(AppColor.onPrimary.opacity(0.9))
        }
    }
}
