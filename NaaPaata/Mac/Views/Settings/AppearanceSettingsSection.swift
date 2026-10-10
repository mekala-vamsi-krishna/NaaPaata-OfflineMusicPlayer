//
//  AppearanceSettingsSection.swift
//  NaaPaataForMac
//
//  Created by Mekala Vamsi Krishna on 9/21/26.
//

import SwiftUI

struct AppearanceSettingsSection: View {

    @ObservedObject var service: AppearanceService

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {

            VStack(alignment: .leading, spacing: 3) {
                Text("Appearance")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.primary)

                Text("Choose how Naa Paata looks. Auto follows your system setting.")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }

            HStack(alignment: .top, spacing: 20) {
                ForEach(AppearancePreference.allCases) { pref in
                    AppearanceCard(
                        preference: pref,
                        isSelected: service.preference == pref,
                        onSelect: { service.preference = pref }
                    )
                }
            }
        }
    }
}
