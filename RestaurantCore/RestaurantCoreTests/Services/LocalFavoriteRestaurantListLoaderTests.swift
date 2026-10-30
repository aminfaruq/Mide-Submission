//
//  LocalFavoriteRestaurantListLoaderTests.swift
//  RestaurantCore
//
//  Created by Amin faruq on 31/10/26.
//

import XCTest
import RxSwift
import RestaurantCore

public protocol FavoriteStore {
    func retrieve() -> Single<[RestaurantEntity]>
    func save(_ restaurant: RestaurantEntity) -> Completable
    func delete(id: String) -> Completable
    func isFavorite(id: String) -> Single<Bool>
}

final class LocalFavoriteRestaurantListLoader: RestaurantListLoader {
    
    private let store: FavoriteStore
    
    init(store: FavoriteStore) {
        self.store = store
    }
    
    func loadRestaurants(query: String) -> Single<[RestaurantEntity]> {
        .never()
    }
    
}

final class LocalFavoriteRestaurantListLoaderTests: XCTestCase {
    
    
    //MARK: - Helpers
    private func makeSUT(
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (sut: LocalFavoriteRestaurantListLoader, spy: FavoriteStoreSpy) {
        let spy = FavoriteStoreSpy()
        let sut = LocalFavoriteRestaurantListLoader(store: spy)
        
        trackForMemoryLeaks(spy, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        
        return (sut, spy)
    }
    
    private class FavoriteStoreSpy: FavoriteStore {
        
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
}
