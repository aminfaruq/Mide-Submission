//
//  CacheStore.swift
//  RestaurantCore
//
//  Created by Amin faruq on 31/10/26.
//

import RxSwift

public protocol CacheStore {
    func retrieve() -> Single<[RestaurantEntity]>
    func save(_ restaurants: [RestaurantEntity]) -> Completable
}
