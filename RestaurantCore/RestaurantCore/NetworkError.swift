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
}
