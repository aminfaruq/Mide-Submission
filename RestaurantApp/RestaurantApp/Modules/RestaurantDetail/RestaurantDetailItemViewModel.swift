//
//  RestaurantDetailItemViewModel.swift
//  RestaurantApp
//
//  Created by Amin faruq on 01/11/26.
//

import RestaurantCore
import Foundation

public struct RestaurantDetailItemViewModel: Equatable {
    public let id: String
    public let name: String
    public let description: String
    public let city: String
    public let address: String
    public let pictureURL: URL
    public let categories: [CategoryItemViewModel]
    public let menus: MenuItemViewModel
    public let rating: String
    public let customerReviews: [CustomerReviewItemViewModel]
    
    public init(id: String, name: String, description: String, city: String, address: String, pictureURL: URL, categories: [CategoryItemViewModel], menus: MenuItemViewModel, rating: String, customerReviews: [CustomerReviewItemViewModel]) {
        self.id = id
        self.name = name
        self.description = description
        self.city = city
        self.address = address
        self.pictureURL = pictureURL
        self.categories = categories
        self.menus = menus
        self.rating = rating
        self.customerReviews = customerReviews
    }
    
    public init(from entity: RestaurantDetailEntity) {
        self.id = entity.id
        self.name = entity.name
        self.description = entity.description
        self.city = entity.city
        self.address = entity.address
        self.pictureURL = Self.makeImageURL(from: entity.pictureId)
        self.categories = entity.categories.map { CategoryItemViewModel(from: $0) }
        self.menus = MenuItemViewModel(from: entity.menus)
        self.rating = "\(entity.rating)"
        self.customerReviews = entity.customerReviews.map { CustomerReviewItemViewModel(from: $0) }
    }
    
    private static func makeImageURL(from pictureId: String) -> URL {
        let baseURL = URL(string: "https://restaurant-api.dicoding.dev/images/medium")!
        return baseURL.appendingPathComponent(pictureId)
    }
}

public struct CategoryItemViewModel: Equatable {
    public let name: String
    
    public init(name: String) {
        self.name = name
    }
    
    public init(from entity: CategoryEntity) {
        self.name = entity.name
    }
}

public struct MenuItemViewModel: Equatable {
    public let foods: [CategoryItemViewModel]
    public let drinks: [CategoryItemViewModel]
    
    public init(foods: [CategoryItemViewModel], drinks: [CategoryItemViewModel]) {
        self.foods = foods
        self.drinks = drinks
    }
    
    public init(from entity: MenuEntity) {
        self.foods = entity.foods.map { CategoryItemViewModel(from: $0) }
        self.drinks = entity.drinks.map { CategoryItemViewModel(from: $0) }
    }
}

public struct CustomerReviewItemViewModel: Equatable {
    public let name: String
    public let review: String
    public let date: String
    
    public init(name: String, review: String, date: String) {
        self.name = name
        self.review = review
        self.date = date
    }
    
    public init(from entity: CustomerReviewEntity) {
        self.name = entity.name
        self.review = entity.review
        self.date = entity.date
    }
}
