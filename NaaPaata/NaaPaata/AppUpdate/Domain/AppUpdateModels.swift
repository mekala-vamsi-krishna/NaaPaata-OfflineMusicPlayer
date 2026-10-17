//
//  AppUpdateModels.swift
//  NaaPaata
//
//  Created by Mekala Vamsi Krishna on 10/17/26.
//

import Foundation
// MARK: - Version History Models

struct VersionInfo: Codable, Identifiable, Sendable, Equatable {
    var id: String { version }
    let version: String
    let date: String
    let sections: VersionSections
}

struct VersionSections: Codable, Sendable, Equatable {
    let newFeatures: [String]
    let enhancements: [String]
    let bugFixes: [String]
    let patches: [String]

    var isEmpty: Bool {
        newFeatures.isEmpty
            && enhancements.isEmpty
            && bugFixes.isEmpty
            && patches.isEmpty
    }
}

// MARK: - Update State

enum AppUpdateState: Equatable {
    case idle
    case checking
    case upToDate
    case updateAvailable(VersionInfo)
    case failed(String)
}

// MARK: - Errors

enum AppUpdateError: LocalizedError {
    case invalidURL
    case invalidResponse
    case decodingFailed(Error)
    case bundledJSONMissing
    case unknown

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "The version history URL is invalid."
        case .invalidResponse:
            return "Received an unexpected response from the server."
        case .decodingFailed(let error):
            return "Failed to parse version history: \(error.localizedDescription)"
        case .bundledJSONMissing:
            return "Bundled version history is missing."
        case .unknown:
            return "An unknown error occurred."
        }
    }
}
