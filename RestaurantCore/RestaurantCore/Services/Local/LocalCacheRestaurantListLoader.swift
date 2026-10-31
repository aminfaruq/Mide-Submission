//
//  LocalCacheRestaurantListLoader.swift
//  RestaurantCore
//
//  Created by Amin faruq on 31/10/26.
//

import Foundation
import RxSwift

public final class LocalCacheRestaurantListLoader: RestaurantListLoader {
    
    private let store: CacheStore
    
    public init(store: CacheStore) {
        self.store = store
    }
    
    public func loadRestaurants(query: String = "") -> Single<[RestaurantEntity]> {
        return store.retrieve()
            .map { restaurants in
                let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
                
                if trimmedQuery.isEmpty {
                    return restaurants
                } else {
                    return restaurants.filter { restaurant in
                        restaurant.name.localizedCaseInsensitiveContains(trimmedQuery)
                    }
                }
            }
    }
    
}
