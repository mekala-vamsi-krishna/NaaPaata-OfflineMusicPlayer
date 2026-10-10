//
//  EqualizerView.swift
//  Mac
//
//  Created by Mekala Vamsi Krishna on 10/4/26.
//

import SwiftUI

struct EqualizerView: View {

    @EnvironmentObject private var viewModel: EqualizerViewModel
    @EnvironmentObject private var engine: EqualizerEngine
    @EnvironmentObject private var store: StoreManager
    @Environment(\.colorScheme) private var colorScheme

    @State private var showSaveSheet = false
    @State private var presetName = ""
    @State private var inspectorVisible = true

    var body: some View {
        Group {
            if store.isPremimumUser {
                equalizerContent
            } else {
                PaywallView()
            }
        }
        .frame(minWidth: 1_020, minHeight: 620)
        .toolbar {
            // The inspector toggle only applies to the Equalizer — hide
            // it while the paywall is on screen.
            if store.isPremimumUser {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            inspectorVisible.toggle()
                        }
                    } label: {
                        Label("Inspector", systemImage: "sidebar.right")
                    }
                    .help("Toggle Inspector")
                }
            }
        }
        .sheet(isPresented: $showSaveSheet) { savePresetSheet }
        // Refresh entitlement whenever the window opens — covers the case
        // where the user subscribed elsewhere (App Store, iOS device).
        .task {
            await store.refreshEntitlements()
        }
    }

    // MARK: - Equalizer content

    private var equalizerContent: some View {
        HStack(spacing: 0) {

            // LEFT — sidebar
            EQPresetSidebar(
                viewModel: viewModel,
                showSaveSheet: $showSaveSheet
            )
            .frame(width: 240)
            .background(sidebarBackground)

            Divider().opacity(0.3)

            // CENTER — header + canvas
            VStack(spacing: 0) {
                EQHeaderBar(viewModel: viewModel, showSaveSheet: $showSaveSheet)

                Divider().opacity(0.3)

                EQCanvasView(viewModel: viewModel)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .background(canvasBackground)

            // RIGHT — inspector
            if inspectorVisible {
                Divider().opacity(0.3)
                EQInspectorPanel(viewModel: viewModel)
                    .frame(width: 260)
                    .background(sidebarBackground)
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
    }

    // MARK: - Backgrounds

    @ViewBuilder
    private var canvasBackground: some View {
        if colorScheme == .dark {
            LinearGradient(
                colors: [
                    Color(red: 0.07, green: 0.07, blue: 0.10),
                    Color(red: 0.04, green: 0.04, blue: 0.06)
                ],
                startPoint: .top, endPoint: .bottom
            )
        } else {
            Color(nsColor: .windowBackgroundColor)
        }
    }

    @ViewBuilder
    private var sidebarBackground: some View {
        if colorScheme == .dark {
            Color(red: 0.10, green: 0.10, blue: 0.13)
        } else {
            Color(nsColor: .underPageBackgroundColor)
        }
    }

    // MARK: - Save sheet

    private var savePresetSheet: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Save Preset").font(.title2.bold())

            TextField("Preset name", text: $presetName)
                .textFieldStyle(.roundedBorder)
                .frame(width: 280)

            HStack {
                Spacer()
                Button("Cancel") {
                    presetName = ""
                    showSaveSheet = false
                }
                .keyboardShortcut(.cancelAction)

                Button("Save") {
                    let trimmed = presetName.trimmingCharacters(in: .whitespaces)
                    guard !trimmed.isEmpty else { return }
                    viewModel.saveCurrentAsPreset(name: trimmed)
                    presetName = ""
                    showSaveSheet = false
                }
                .keyboardShortcut(.defaultAction)
                .disabled(presetName.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding(24)
        .frame(width: 340)
    }
}
