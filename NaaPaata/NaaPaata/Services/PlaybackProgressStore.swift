//
//  PlaybackProgressStore.swift
//  NaaPaata
//
//  Created by Mekala Vamsi Krishna on 10/7/26.
//
import Foundation
import Combine

@MainActor
final class PlaybackProgressStore: ObservableObject {
    @Published var elapsed: TimeInterval = 0
    @Published var progress: Double = 0
}
