//
//  AppearanceCard.swift
//  NaaPaataForMac
//
//  Created by Mekala Vamsi Krishna on 9/21/26.
//

import SwiftUI

struct AppearanceCard: View {

    let preference: AppearancePreference
    let isSelected: Bool
    let onSelect: () -> Void

    private let previewWidth: CGFloat = 108
    private let previewHeight: CGFloat = 74

    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 8) {
                preview
                label
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help(preference.title)
    }

    // MARK: - Preview

    private var preview: some View {
        AppearancePreview(preference: preference)
            .frame(width: previewWidth, height: previewHeight)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .strokeBorder(
                        isSelected
                            ? Color.accentColor
                            : Color.primary.opacity(0.15),
                        lineWidth: isSelected ? 3 : 1
                    )
            )
            .overlay(alignment: .bottomLeading) {
                if isSelected {
                    checkmarkBadge
                        .offset(x: -9, y: 9)
                }
            }
            .animation(.easeInOut(duration: 0.15), value: isSelected)
    }

    // MARK: - Checkmark

    private var checkmarkBadge: some View {
        ZStack {
            Circle()
                .fill(Color.accentColor)
            Image(systemName: "checkmark")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(.white)
        }
        .frame(width: 22, height: 22)
        .overlay(
            Circle().strokeBorder(.white, lineWidth: 2)
        )
    }

    // MARK: - Label

    private var label: some View {
        Text(preference.title)
            .font(.system(size: 11, weight: isSelected ? .semibold : .regular))
            .foregroundStyle(.primary)
            .frame(width: previewWidth)
    }
}
