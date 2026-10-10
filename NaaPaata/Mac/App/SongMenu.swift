//
//  SongMenu.swift
//  NaaPaataForMac
//
//  Created by Mekala Vamsi Krishna on 9/23/26.
//

import SwiftUI
import AppKit

/// The "Song" menu in the macOS menu bar.
struct SongMenu: Commands {

    @ObservedObject var viewModel: MusicLibraryViewModel

    private var song: Song? { viewModel.targetSong }

    var body: some Commands {
        CommandMenu("Song") {

            // ─── Play Next ───
            Button("Play Next") {
                guard let song else { return }
                viewModel.enqueueNext(song)
            }
            .keyboardShortcut("n", modifiers: [.command, .shift])
            .disabled(song == nil)

            Divider()

            // ─── Add to Playlist ▸ ───
            Menu {
                Button("New Playlist") {
                    guard let song else { return }
                    viewModel.pendingIntent = .addToNewPlaylist(song)
                }

                Button("Existing Playlist") {
                    guard let song else { return }
                    viewModel.pendingIntent = .addToExistingPlaylist(song)
                }
            } label: {
                Text("Add to Playlist")
            }
            .disabled(song == nil)

            // ─── Get Info ───
            Button("Get Info") {
                guard let song else { return }
                viewModel.pendingIntent = .showInfo(song)
            }
            .keyboardShortcut("i", modifiers: .command)
            .disabled(song == nil)

            Divider()

            // ─── Go to Album ───
            Button("Go to Album") {
                guard let song else { return }
                viewModel.pendingIntent = .goToAlbum(song)
            }
            .keyboardShortcut("g", modifiers: [.command, .shift])
            .disabled(song == nil)

            // ─── Show in Finder ───
            Button("Show in Finder") {
                guard let song else { return }
                NSWorkspace.shared.activateFileViewerSelecting([song.url])
            }
            .keyboardShortcut("f", modifiers: [.command, .shift])
            .disabled(song == nil)

            Divider()

            // ─── Delete ───
            Button("Delete") {
                guard let song else { return }
                viewModel.pendingIntent = .delete(song)
            }
            .keyboardShortcut(.delete, modifiers: .command)
            .disabled(song == nil)
        }
    }
}
