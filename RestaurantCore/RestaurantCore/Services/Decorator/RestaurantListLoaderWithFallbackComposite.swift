//
//  RestaurantListLoaderWithFallbackComposite.swift
//  RestaurantCore
//
//  Created by Amin faruq on 01/11/26.
//

import RxSwift

public final class RestaurantListLoaderWithFallbackComposite: RestaurantListLoader {
    private let primary: RestaurantListLoader
    private let fallback: RestaurantListLoader
    
    public init(primary: RestaurantListLoader, fallback: RestaurantListLoader) {
        self.primary = primary
        self.fallback = fallback
    }
    
    public func loadRestaurants(query: String) -> Single<[RestaurantEntity]> {
        return primary.loadRestaurants(query: query)
            .catch { [fallback] _ in
                return fallback.loadRestaurants(query: query)
            }
    }
    
}
