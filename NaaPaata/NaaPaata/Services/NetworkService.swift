//
//  NetworkService.swift
//  NaaPaata
//
//  Created by Mekala Vamsi Krishna on 8/25/26.
//

import Foundation
import SwiftUI

// MARK: - Version & Sections Models
struct Version: Codable, Identifiable {
    let id = UUID()
    let version: String
    let date: String
    let sections: Sections

    enum CodingKeys: String, CodingKey {
        case version, date, sections
    }
}

struct Sections: Codable {
    let newFeatures: [String]
    let enhancements: [String]
    let bugFixes: [String]
    let patches: [String]
}

// MARK: - NetworkError
enum NetworkError: LocalizedError {
    case invalidURL
    case invalidResponse
    case decodingFailed(Error)
    case unknown

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid URL"
        case .invalidResponse: return "Invalid response from server"
        case .decodingFailed(let error): return "Failed to decode data: \(error.localizedDescription)"
        case .unknown: return "An unknown error occurred"
        }
    }
}

// MARK: - NetworkService
final class NetworkService {
    static let shared = NetworkService()

    private init() {}

    // MARK: - Load from Local Bundle
    func loadLocalVersionHistory() -> [Version]? {
        guard let url = Bundle.main.url(forResource: "version_history", withExtension: "json") else {
            print("❌ version_history.json not found in app bundle")
            return nil
        }
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let versions = try decoder.decode([Version].self, from: data)
            return versions
        } catch {
            print("❌ Failed to decode version_history.json: \(error)")
            return nil
        }
    }
}
