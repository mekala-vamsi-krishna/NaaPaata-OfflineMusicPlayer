//
//  AboutView.swift
//  NaaPaata
//
//  Created by Mekala Vamsi Krishna on 8/25/26.
//

import SwiftUI

struct AboutView: View {

    // MARK: - App Info
    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }

    private var appIcon: UIImage? {
        guard let icons = Bundle.main.infoDictionary?["CFBundleIcons"] as? [String: Any],
              let primary = icons["CFBundlePrimaryIcon"] as? [String: Any],
              let files = primary["CFBundleIconFiles"] as? [String],
              let iconName = files.last else { return nil }
        return UIImage(named: iconName)
    }

    var body: some View {
        List {
            Section {
                headerView
            }
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
            .listRowInsets(EdgeInsets())

            Section {
                infoRow(title: "Version", value: appVersion)
                infoRow(title: "Developer", value: "Tech Palle")
                infoRow(title: "Copyright", value: "© 2025 techpalle")
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Header

    private var headerView: some View {
        VStack(spacing: 6) {
            Group {
                if let appIcon {
                    Image(uiImage: appIcon)
                        .resizable()
                } else {
                    Image("AppLogo")
                        .resizable()
                }
            }
            .scaledToFit()
            .frame(width: 88, height: 88)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
            .padding(.bottom, 6)

            Text("Naa Paata")
                .font(.title2.weight(.bold))

            Text("Your world. Your sound.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text("Version \(appVersion)")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
    }

    // MARK: - Rows

    private func infoRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .foregroundStyle(.secondary)
        }
    }
}
