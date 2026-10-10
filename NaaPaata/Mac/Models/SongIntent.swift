//
//  SongIntent.swift
//  NaaPaataForMac
//
//  Created by Mekala Vamsi Krishna on 9/23/26.
//

import Foundation

/// An action that needs to be handled by a view rather than the view model.
///
/// The menu bar has no way to present sheets or push navigation on its own,
/// so commands set a pending intent and the main window reacts.
enum SongIntent: Equatable {
    case showInfo(Song)
    case addToNewPlaylist(Song)
    case addToExistingPlaylist(Song)
    case goToAlbum(Song)
    case delete(Song)
}
