//
//  SettingsRow.swift
//  NaaPaata
//
//  Created by Mekala Vamsi Krishna on 8/25/26.
//

import SwiftUI

struct SettingsRow<Trailing: View>: View {
    let icon: String
    let title: String
    let iconColor: Color

    @ViewBuilder var trailing: () -> Trailing

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(
                    cornerRadius: 6,
                    style: .continuous
                )
                .fill(iconColor.gradient)
                .frame(width: 29, height: 29)

                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.white)
            }

            Text(title)
                .font(.system(size: 17))
                .foregroundStyle(.primary)

            Spacer(minLength: 8)

            trailing()
        }
        .padding(.vertical, 1)
        .contentShape(Rectangle())
    }
}

