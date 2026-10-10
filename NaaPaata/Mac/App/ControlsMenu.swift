//
//  ControlsMenu.swift
//  NaaPaataForMac
//
//  Created by Mekala Vamsi Krishna on 9/23/26.
//

import SwiftUI

/// The "Controls" menu in the macOS menu bar.
struct ControlsMenu: Commands {

    @ObservedObject var viewModel: MusicLibraryViewModel

    var body: some Commands {
        CommandMenu("Controls") {

            // Play / Pause
            Button {
                viewModel.togglePlayPause()
            } label: {
                Text(viewModel.isPlaying ? "Pause" : "Play")
            }
            .keyboardShortcut(.space, modifiers: [])
            .disabled(viewModel.currentSong == nil)

            Divider()

            // Next / Previous
            Button("Next Track") {
                viewModel.playNext()
            }
            .keyboardShortcut(.rightArrow, modifiers: .command)
            .disabled(viewModel.currentSong == nil)

            Button("Previous Track") {
                viewModel.playPrevious()
            }
            .keyboardShortcut(.leftArrow, modifiers: .command)
            .disabled(viewModel.currentSong == nil)

            Divider()

            // Shuffle — Toggle renders a checkmark when on
            Toggle(
                "Shuffle",
                isOn: Binding(
                    get: { viewModel.isShuffled },
                    set: { newValue in
                        guard newValue != viewModel.isShuffled else { return }
                        viewModel.toggleShuffle()
                    }
                )
            )
            .keyboardShortcut("s", modifiers: [.command, .shift])

            // Repeat — submenu with radio selection
            Picker(
                "Repeat",
                selection: Binding(
                    get: { viewModel.repeatMode },
                    set: { viewModel.setRepeatMode($0) }
                )
            ) {
                Text("Off").tag(RepeatMode.off)
                Text("All").tag(RepeatMode.all)
                Text("One").tag(RepeatMode.one)
            }
        }
    }
}
