//
//  AppearanceSettingsView.swift
//  NaaPaataForMac
//
//  Created by Mekala Vamsi Krishna on 9/24/26.
//

import SwiftUI

struct AppearanceSettingsView: View {

    @ObservedObject var service: AppearanceService

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Choose how Naa Paata looks. Auto follows your system setting.")
                .font(.callout)
                .foregroundStyle(.secondary)

            HStack(alignment: .top, spacing: 22) {
                ForEach(AppearancePreference.allCases) { preference in
                    AppearanceCard(
                        preference: preference,
                        isSelected: service.preference == preference,
                        onSelect: { service.preference = preference }
                    )
                }
                Spacer(minLength: 0)
            }

            Spacer()
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .navigationTitle("Appearance")
    }
}
