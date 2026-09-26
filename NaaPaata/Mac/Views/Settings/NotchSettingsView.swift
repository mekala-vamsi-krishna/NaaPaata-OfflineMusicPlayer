//
//  NotchSettingsView.swift
//  NaaPaataForMac
//
//  Created by Mekala Vamsi Krishna on 9/24/26.
//

import SwiftUI

struct NotchSettingsView: View {

    @ObservedObject var viewModel: MusicLibraryViewModel
    @AppStorage("showNotchMedia") private var showNotchMedia = false

    var body: some View {
        Form {
            Section {
                Toggle("Show Media in Notch", isOn: $showNotchMedia)
                    .onChange(of: showNotchMedia) { _, newValue in
                        if newValue {
                            NotchWindowController.shared.show(viewModel: viewModel)
                        } else {
                            NotchWindowController.shared.hide()
                        }
                    }
            } footer: {
                Text("Displays playback controls at the top center of your screen. Macs without a physical notch get a simulated one.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Notch")
    }
}
