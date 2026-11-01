//
//  RestaurantListInteractor.swift
//  RestaurantApp
//
//  Created by Amin faruq on 01/11/26.
//

import RxSwift
import RestaurantCore


public final class RestaurantListInteractor: RestaurantListInteractorProtocol {
    
    private let loader: RestaurantListLoader
    
    public init(loader: RestaurantListLoader) {
        self.loader = loader
    }
    
    public func loadRestaurants(query: String = "") -> Single<[RestaurantEntity]> {
        return loader.loadRestaurants(query: query)
    }
    
    // Workaround bug compiler XCTest multi module
    nonisolated deinit {}
}
