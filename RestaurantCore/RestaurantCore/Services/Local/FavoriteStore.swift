//
//  FavoriteStore.swift
//  RestaurantCore
//
//  Created by Amin faruq on 31/10/26.
//

import RxSwift

public protocol FavoriteStore {
    func retrieve() -> Single<[RestaurantEntity]>
    func save(_ restaurant: RestaurantEntity) -> Completable
    func delete(id: String) -> Completable
    func isFavorite(id: String) -> Single<Bool>
}
