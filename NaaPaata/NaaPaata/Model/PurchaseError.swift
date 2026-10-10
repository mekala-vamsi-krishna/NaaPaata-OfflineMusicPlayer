//
//  PurchaseError.swift
//  NaaPaata
//
//  Created by Mekala Vamsi Krishna on 12/5/25.
//

import Foundation

enum PurchaseError: Error, Identifiable {
    case loadProductsFailed(String)
    case userCancelled
    case pending
    case authenticationFailed
    case networkError
    case unknown(String)

    // MARK: - Identifiable

    var id: String {
        switch self {
        case .loadProductsFailed(let reason): return "loadProductsFailed-\(reason)"
        case .userCancelled:                  return "userCancelled"
        case .pending:                        return "pending"
        case .authenticationFailed:           return "authenticationFailed"
        case .networkError:                   return "networkError"
        case .unknown(let reason):            return "unknown-\(reason)"
        }
    }

    // MARK: - Display

    var title: String {
        switch self {
        case .loadProductsFailed:  return "Unable to Load Plans"
        case .userCancelled:       return "Purchase Cancelled"
        case .pending:             return "Purchase Pending"
        case .authenticationFailed:return "Purchase Failed"
        case .networkError:        return "Connection Problem"
        case .unknown:             return "Something Went Wrong"
        }
    }

    var message: String {
        switch self {
        case .loadProductsFailed(let reason):
            return "We couldn't fetch the subscription plans. \(reason)"
        case .userCancelled:
            return "No purchase was made."
        case .pending:
            return "Your purchase is pending approval. You'll be notified once it's approved."
        case .authenticationFailed:
            return "We couldn't verify this purchase with the App Store. Please try again."
        case .networkError:
            return "Please check your internet connection and try again."
        case .unknown(let reason):
            return reason
        }
    }
}
