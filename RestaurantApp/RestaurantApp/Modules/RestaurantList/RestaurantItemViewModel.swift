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
    
    public init(from entity: RestaurantEntity) {
        self.id = entity.id
        self.name = entity.name
        self.description = entity.description
        self.pictureURL = Self.makeImageURL(from: entity.pictureId)
        self.city = entity.city
        self.rating = "\(entity.rating)"
    }
    
    private static func makeImageURL(from pictureId: String) -> URL {
        let baseURL = URL(string: "https://restaurant-api.dicoding.dev/images/medium")!
        return baseURL.appendingPathComponent(pictureId)
    }
}
