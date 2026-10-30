//
//  RestaurantDetailEntity.swift
//  RestaurantCore
//
//  Created by Amin faruq on 30/10/26.
//

public struct RestaurantDetailEntity: Equatable {
    public let id: String
    public let name: String
    public let description: String
    public let city: String
    public let address: String
    public let pictureId: String
    public let categories: [CategoryEntity]
    public let menus: MenuEntity
    public let rating: Double
    public let customerReviews: [CustomerReviewEntity]
}

public struct CategoryEntity: Equatable {
    public let name: String
}

public struct MenuEntity: Equatable {
    public let foods: [CategoryEntity]
    public let drinks: [CategoryEntity]
}

public struct CustomerReviewEntity: Equatable {
    public let name: String
    public let review: String
    public let date: String
}
