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
}

public extension RestaurantDetailEntity {
    private static let imageBaseURL = URL(string: "https://restaurant-api.dicoding.dev/images/medium")
    
    private func makeImageURL(from picture: String) -> URL {
        if let baseURL = RestaurantDetailEntity.imageBaseURL {
            return baseURL.appending(path: pictureId)
        }
        
        return URL(string: "about:blank") ?? URL(fileURLWithPath: "")
    }
    
    func toViewModel() -> RestaurantDetailItemViewModel {
        .init(
            id: id,
            name: name,
            description: description,
            city: city,
            address: address,
            pictureURL: makeImageURL(from: pictureId),
            categories: categories.map { $0.toViewModel() },
            menus: menus.toViewModel(),
            rating: "\(rating)",
            customerReviews: customerReviews.map { $0.toViewModel() }
        )
    }
    
}

public struct CategoryItemViewModel: Equatable {
    public let name: String
    
    public init(name: String) {
        self.name = name
    }
}

public extension CategoryEntity {
    func toViewModel() -> CategoryItemViewModel {
        .init(name: name)
    }
}

public struct MenuItemViewModel: Equatable {
    public let foods: [CategoryItemViewModel]
    public let drinks: [CategoryItemViewModel]
    
    public init(foods: [CategoryItemViewModel], drinks: [CategoryItemViewModel]) {
        self.foods = foods
        self.drinks = drinks
    }
}

public extension MenuEntity {
    func toViewModel() -> MenuItemViewModel {
        .init(
            foods: foods.map { $0.toViewModel() },
            drinks: drinks.map { $0.toViewModel() }
        )
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
}

public extension CustomerReviewEntity {
    func toViewModel() -> CustomerReviewItemViewModel {
        .init(
            name: name,
            review: review,
            date: date
        )
    }
}
