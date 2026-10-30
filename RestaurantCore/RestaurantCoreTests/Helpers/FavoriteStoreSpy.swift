//
//  FavoriteStoreSpy.swift
//  RestaurantCore
//
//  Created by Amin faruq on 31/10/26.
//

import RestaurantCore
import RxSwift

class FavoriteStoreSpy: FavoriteStore {
    enum Message: Equatable {
        case retrieve
        case save(_ restaurant: RestaurantEntity)
        case delete(id: String)
        case isFavorite(id: String)
    }
    
    private(set) var messages = [Message]()
    
    var retrieveStub: Single<[RestaurantEntity]> = .never()
    var saveStub: Completable = .never()
    var deleteStub: Completable = .never()
    var isFavoriteStub: Single<Bool> = .never()
    
    func retrieve() -> Single<[RestaurantEntity]> {
        messages.append(.retrieve)
        return retrieveStub
    }
    
    func save(_ restaurant: RestaurantEntity) -> Completable {
        messages.append(.save(restaurant))
        return saveStub
    }
    
    func delete(id: String) -> Completable {
        messages.append(.delete(id: id))
        return deleteStub
    }
    
    func isFavorite(id: String) -> Single<Bool> {
        messages.append(.isFavorite(id: id))
        return isFavoriteStub
    }
}
