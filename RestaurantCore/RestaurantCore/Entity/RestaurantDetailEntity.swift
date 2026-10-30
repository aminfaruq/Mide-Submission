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
    
    public init(id: String, name: String, description: String, city: String, address: String, pictureId: String, categories: [CategoryEntity], menus: MenuEntity, rating: Double, customerReviews: [CustomerReviewEntity]) {
        self.id = id
        self.name = name
        self.description = description
        self.city = city
        self.address = address
        self.pictureId = pictureId
        self.categories = categories
        self.menus = menus
        self.rating = rating
        self.customerReviews = customerReviews
    }
}

public struct CategoryEntity: Equatable {
    public let name: String
    
    public init(name: String) {
        self.name = name
    }
}

public struct MenuEntity: Equatable {
    public let foods: [CategoryEntity]
    public let drinks: [CategoryEntity]
    
    public init(foods: [CategoryEntity], drinks: [CategoryEntity]) {
        self.foods = foods
        self.drinks = drinks
    }
}

public struct CustomerReviewEntity: Equatable {
    public let name: String
    public let review: String
    public let date: String
    
    public init(name: String, review: String, date: String) {
        self.name = name
        self.review = review
        self.date = date
    }
}
