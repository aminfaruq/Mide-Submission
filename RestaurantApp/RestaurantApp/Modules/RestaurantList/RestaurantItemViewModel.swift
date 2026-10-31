//
//  RestaurantItemViewModel.swift
//  RestaurantApp
//
//  Created by Amin faruq on 01/11/26.
//

import RestaurantCore
import Foundation

public struct RestaurantItemViewModel: Equatable {
    public let id: String
    public let name: String
    public let description: String
    public let pictureURL: URL
    public let city: String
    public let rating: String
    
    public init(id: String, name: String, description: String, pictureURL: URL, city: String, rating: String) {
        self.id = id
        self.name = name
        self.description = description
        self.pictureURL = pictureURL
        self.city = city
        self.rating = rating
    }
}

public extension RestaurantEntity {
    private static let imageBaseURL = URL(string: "https://restaurant-api.dicoding.dev/images/medium")
    
    private func makeImageURL(from picture: String) -> URL {
        if let baseURL = RestaurantEntity.imageBaseURL {
            return baseURL.appending(path: pictureId)
        }
        
        return URL(string: "about:blank") ?? URL(fileURLWithPath: "")
    }
    
    func toViewModel() -> RestaurantItemViewModel {
        .init(
            id: id,
            name: name,
            description: description,
            pictureURL: makeImageURL(from: pictureId),
            city: city,
            rating: "\(rating)"
        )
    }
}
