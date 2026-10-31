//
//  NetworkError.swift
//  RestaurantCore
//
//  Created by Amin faruq on 30/10/26.
//

import Foundation

public enum NetworkError: Swift.Error, LocalizedError, Equatable {
    case connectivity
    case invalidData
    case decodeError
    
    public var errorDescription: String? {
        switch self {
            case .connectivity:
                return NSLocalizedString(
                    "Unable to connect to the server. Please check your internet connection and try again.",
                    comment: "Connectivity error description"
                )
            case .invalidData:
                return NSLocalizedString(
                    "The server returned an invalid or unexpected response. Please try again later.",
                    comment: "Invalid data error description"
                )
            case .decodeError:
                return NSLocalizedString(
                    "Failed to process the response from the server. Please try again.",
                    comment: "Decode error description"
                )
        }
    }
    
}
