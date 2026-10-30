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
        return store.save(restaurant)
    }
    
    func remove(id: String) -> Completable {
        return store.delete(id: id)
    }
    
    func isFavorite(id: String) -> Single<Bool> {
        return store.isFavorite(id: id)
    }
}

final class LocalRestaurantDetailStoreTests: XCTestCase {
    
    private let disposeBag = DisposeBag()
    
    func test_init_doesNotMessagesUponCreation() {
        let (_, spy) = makeSUT()
        
        XCTAssertEqual(spy.messages, [])
    }
    
    func test_save_requestSaveFromStore() {
        let (sut, spy) = makeSUT()
        
        spy.saveStub = .empty()
        let exp = expectation(description: "wait from response")
        let insertion = makeRestaurant(name: "melting")
        
        sut.save(insertion)
            .subscribe(
                onCompleted: {
                    exp.fulfill()
                }
            )
            .disposed(by: disposeBag)
        
        
        wait(for: [exp], timeout: 1.0)
        
        XCTAssertEqual(spy.messages, [.save(insertion)])
    }
    
    func test_remove_requestDeleteFromStore() {
        let (sut, spy) = makeSUT()
        
        spy.deleteStub = .empty()
        let exp = expectation(description: "wait from response")
        let anyId = UUID().uuidString
        
        sut.remove(id: anyId)
            .subscribe(
                onCompleted: {
                    exp.fulfill()
                }
            )
            .disposed(by: disposeBag)
        
        
        wait(for: [exp], timeout: 1.0)
        
        XCTAssertEqual(spy.messages, [.delete(id: anyId)])
    }
    
    func test_isFavorite_requestFavoriteFromStore() {
        let (sut, spy) = makeSUT()
        
        spy.isFavoriteStub = .just(true)
        let exp = expectation(description: "wait from response")
        let anyId = UUID().uuidString
        
        sut.isFavorite(id: anyId)
            .subscribe(
                onSuccess: { result in
                    XCTAssertTrue(result)
                    exp.fulfill()
                }
            )
            .disposed(by: disposeBag)
        
        
        wait(for: [exp], timeout: 1.0)
        
        XCTAssertEqual(spy.messages, [.isFavorite(id: anyId)])
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
    
    private func makeRestaurant(name: String) -> RestaurantEntity {
        .init(
            id: UUID().uuidString,
            name: name,
            description: "a desc",
            pictureId: "an id",
            city:  "any-city",
            rating: 4.5
        )
    }

}
