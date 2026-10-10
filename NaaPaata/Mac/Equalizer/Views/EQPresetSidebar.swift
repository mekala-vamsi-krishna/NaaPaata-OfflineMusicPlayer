//
//  EQPresetSidebar.swift
//  Mac
//
//  Created by Mekala Vamsi Krishna on 10/4/26.
//

import SwiftUI

struct EQPresetSidebar: View {

    @ObservedObject var viewModel: EqualizerViewModel
    @Binding var showSaveSheet: Bool

    @State private var renamingPreset: EqualizerPreset?
    @State private var renameText: String = ""

    var body: some View {
        VStack(spacing: 0) {

            // Search field
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                    .font(.system(size: 12))
                TextField("Search presets", text: $viewModel.searchQuery)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(.quaternary, in: RoundedRectangle(cornerRadius: 6))
            .padding(10)

            Divider().opacity(0.4)

            // Preset list
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 2, pinnedViews: [.sectionHeaders]) {
                    ForEach(viewModel.groupedPresets, id: \.0) { category, presets in
                        Section {
                            ForEach(presets) { preset in
                                row(for: preset)
                            }
                        } header: {
                            Text(category.label.uppercased())
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(.tertiary)
                                .tracking(0.8)
                                .padding(.horizontal, 12)
                                .padding(.top, 12)
                                .padding(.bottom, 4)
                        }
                    }
                }
                .padding(.bottom, 12)
            }
        }
        .sheet(item: $renamingPreset) { preset in
            renameSheet(for: preset)
        }
    }

    // MARK: - Row

    private func row(for preset: EqualizerPreset) -> some View {
        let isSelected = viewModel.selectedPresetID == preset.id

        return Button {
            viewModel.apply(preset)
        } label: {
            HStack(spacing: 8) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 11))
                    .foregroundStyle(isSelected ? Color.accentColor : .accentColor)

                Text(preset.name)
                    .font(.system(size: 12.5))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .truncationMode(.tail)

                Spacer(minLength: 4)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isSelected ? Color.accentColor.opacity(0.15) : .clear)
                .padding(.horizontal, 6)
        )
        .contextMenu {
            if preset.isBuiltIn {
                Text("Built-in preset")
            } else {
                Button {
                    renameText = preset.name
                    renamingPreset = preset
                } label: {
                    Label("Rename…", systemImage: "pencil")
                }
                Divider()
                Button(role: .destructive) {
                    viewModel.deletePreset(preset)
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
        .simultaneousGesture(
            TapGesture(count: 2).onEnded {
                guard !preset.isBuiltIn else { return }
                renameText = preset.name
                renamingPreset = preset
            }
        )
    }

    // MARK: - Rename sheet

    @ViewBuilder
    private func renameSheet(for preset: EqualizerPreset) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Rename Preset").font(.title3.bold())

            TextField("Preset name", text: $renameText)
                .textFieldStyle(.roundedBorder)
                .frame(width: 300)
                .onSubmit { commitRename(for: preset) }

            HStack {
                Spacer()
                Button("Cancel") {
                    renamingPreset = nil
                    renameText = ""
                }
                .keyboardShortcut(.cancelAction)

                Button("Rename") { commitRename(for: preset) }
                    .keyboardShortcut(.defaultAction)
                    .disabled(renameText.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding(24)
        .frame(width: 360)
    }

    private func commitRename(for preset: EqualizerPreset) {
        let trimmed = renameText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        viewModel.renamePreset(preset, to: trimmed)
        renamingPreset = nil
        renameText = ""
    }
}
