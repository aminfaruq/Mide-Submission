//
//  LocalCacheSaver.swift
//  RestaurantCore
//
//  Created by Amin faruq on 31/10/26.
//

import RxSwift

public protocol CacheSaver {
    func save(_ restaurants: [RestaurantEntity]) -> Completable
}

public final class LocalCacheSaver {
    
    private let store: CacheStore
    
    public init(store: CacheStore) {
        self.store = store
    }
    
    public func save(_ restaurants: [RestaurantEntity]) -> Completable {
        return store.save(restaurants)
    }
}
