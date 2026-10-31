//
//  RestaurantListLoaderCacheDecorator.swift
//  RestaurantCore
//
//  Created by Amin faruq on 01/11/26.
//

import RxSwift

public final class RestaurantListLoaderCacheDecorator: RestaurantListLoader {
    
    private let decoratee: RestaurantListLoader
    private let cache: CacheSaver
    
    public init(decoratee: RestaurantListLoader, cache: CacheSaver) {
        self.decoratee = decoratee
        self.cache = cache
    }
    
    public func loadRestaurants(query: String) -> Single<[RestaurantEntity]> {
        return decoratee.loadRestaurants(query: query)
            .flatMap { [weak self] results in
                guard let self = self else { return .just(results) }
                return self.cache.save(results)
                    .catch { _ in .empty() }
                    .andThen(Single.just(results))
            }
    }
}
