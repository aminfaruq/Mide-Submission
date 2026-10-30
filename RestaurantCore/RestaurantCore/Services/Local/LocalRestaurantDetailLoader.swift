//
//  LocalRestaurantDetailLoader.swift
//  RestaurantCore
//
//  Created by Amin faruq on 31/10/26.
//

import RxSwift

public protocol FavoriteLoader {
    func save(_ restaurant: RestaurantEntity) -> Completable
    func remove(id: String)  -> Completable
    func isFavorite(id: String)  -> Single<Bool>
}

public final class LocalRestaurantDetailLoader: FavoriteLoader {

    private let store: FavoriteStore
    
    public init(store: FavoriteStore) {
        self.store = store
    }
    
    public func save(_ restaurant: RestaurantEntity) -> Completable {
        return store.save(restaurant)
    }
    
    public func remove(id: String) -> Completable {
        return store.delete(id: id)
    }
    
    public func isFavorite(id: String) -> Single<Bool> {
        return store.isFavorite(id: id)
    }
}
