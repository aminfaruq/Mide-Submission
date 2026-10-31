//
//  CacheStoreSpy.swift
//  RestaurantCore
//
//  Created by Amin faruq on 31/10/26.
//

import RxSwift
import RestaurantCore

class CacheStoreSpy: CacheStore {
    enum Message: Equatable {
        case retrieve
        case save(_ restaurants: [RestaurantEntity])
    }
    
    private(set) var messages = [Message]()
    
    var retriveStub: Single<[RestaurantEntity]> = .never()
    var saveStub: Completable = .never()
    
    func retrieve() -> Single<[RestaurantEntity]> {
        messages.append(.retrieve)
        return retriveStub
    }
    
    func save(_ restaurants: [RestaurantEntity]) -> Completable {
        messages.append(.save(restaurants))
        return saveStub
    }
}
