//
//  LocalRestaurantDetailStoreTests.swift
//  RestaurantCoreTests
//
//  Created by Amin faruq on 31/10/26.
//

import XCTest
import RxSwift
import RestaurantCore

public protocol FavoriteManager {
    func save(_ restaurant: RestaurantEntity) -> Completable
    func remove(id: String)  -> Completable
    func isFavorite(id: String)  -> Single<Bool>
}

final class LocalRestaurantDetailStore: FavoriteManager {

    private let store: FavoriteStore
    
    init(store: FavoriteStore) {
        self.store = store
    }
    
    func save(_ restaurant: RestaurantEntity) -> Completable {
        .never()
    }
    
    func remove(id: String) -> Completable {
        .never()
    }
    
    func isFavorite(id: String) -> Single<Bool> {
        .never()
    }
}

final class LocalRestaurantDetailStoreTests: XCTestCase {
    
    func test_init_doesNotMessagesUponCreation() {
        let (_, spy) = makeSUT()
        
        XCTAssertEqual(spy.messages, [])
    }

    //MARK: Helpers
    private func makeSUT(
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (sut: LocalRestaurantDetailStore, spy: FavoriteStoreSpy) {
        let spy = FavoriteStoreSpy()
        let sut = LocalRestaurantDetailStore(store: spy)
        
        trackForMemoryLeaks(spy, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        
        return (sut, spy)
    }

}
