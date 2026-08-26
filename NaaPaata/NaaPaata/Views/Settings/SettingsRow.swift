//
//  SettingsRow.swift
//  NaaPaata
//
//  Created by Mekala Vamsi Krishna on 8/25/26.
//

import SwiftUI

struct SettingsRow<Content: View>: View {
    let icon: String
    let title: String
    let subtitle: String?
    let tintColor: Color
    let content: Content

    init(icon: String, title: String, subtitle: String? = nil, tintColor: Color = AppColors.primary, @ViewBuilder content: () -> Content) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.tintColor = tintColor
        self.content = content()
    }

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(tintColor.opacity(0.15))
                    .frame(width: 40, height: 40)
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(tintColor)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(AppColors.textPrimary)
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.system(size: 13))
                        .foregroundColor(AppColors.textSecondary)
                        .lineLimit(2)
                }
            }
            Spacer()
            content
        }
        .padding(.vertical, 4)
    }
}
