//
//  RealmFavoriteStoreTests.swift
//  RestaurantCore
//
//  Created by Amin faruq on 31/10/26.
//

import XCTest
import RealmSwift
import RxSwift
import RestaurantCore

final class RealmFavoriteStoreTests: XCTestCase {
    
    private let disposeBag = DisposeBag()
    
    private var inMemoryRealm: Realm?

    override func tearDown() {
        inMemoryRealm = nil
        super.tearDown()
    }
    
    func test_retrieve_deliversEmptyOnEmptyCache() {
        let sut = makeSUT()
        
        let exp = expectation(description: "wait from response")
        sut.retrieve()
            .subscribe(
                onSuccess: { result in
                    XCTAssertEqual(result, [])
                    exp.fulfill()
                }
            )
            .disposed(by: disposeBag)
        
        wait(for: [exp], timeout: 1.0)
    }
    
    func test_retrieve_hasNoSideEffectsOnEmptyCache() {
        let sut = makeSUT()
        
        let exp = expectation(description: "wait from response")
                    
        sut.retrieve()
            .flatMap({ result in
                XCTAssertEqual(result, [])
                return sut.retrieve()
            })
            .subscribe(
                onSuccess: { result in
                    XCTAssertEqual(result, [])
                    exp.fulfill()
                }
            )
            .disposed(by: disposeBag)
        
        wait(for: [exp], timeout: 1.0)
    }
    
    func test_retrieve_deliversFoundValuesOnNonEmptyCache() {
        let sut = makeSUT()
        let restaurant = makeRestaurant(name: "melting pot")
        
        let exp = expectation(description: "wait from response")
        sut.save(restaurant)
            .andThen(sut.retrieve())
                .subscribe(
                    onSuccess: { result in
                        XCTAssertEqual(result, [restaurant])
                        exp.fulfill()
                    }
                )
                .disposed(by: disposeBag)
        
        wait(for: [exp], timeout: 1.0)
    }
    
    func test_save_overridesPreviouslyInsertedValueWithSameID() {
        let sut = makeSUT()
        let originalRestaurant = makeRestaurant(id: "1", name: "Old name")
        let updateRestaurant = makeRestaurant(id: "1", name: "New name")
        let exp = expectation(description: "wait from response")

        sut.save(originalRestaurant)
            .andThen(sut.save(updateRestaurant))
            .andThen(sut.retrieve())
            .subscribe(
                onSuccess: { result in
                    XCTAssertEqual(result, [updateRestaurant])
                    XCTAssertEqual(result.count, 1)
                    exp.fulfill()
                }
            )
            .disposed(by: disposeBag)
        
        wait(for: [exp], timeout: 1.0)
    }
    
    func test_delete_emptiesPreviouslyInsertedValue() {
        let sut = makeSUT()
        let restaurant = makeRestaurant(id: "1", name: "Melting Pot")
        
        let exp = expectation(description: "wait from response")
        sut.save(restaurant)
            .andThen(sut.delete(id: restaurant.id))
            .andThen(sut.retrieve())
            .subscribe(
                onSuccess: { result in
                    XCTAssertEqual(result, [])
                    exp.fulfill()
                }
            )
            .disposed(by: disposeBag)
        
        wait(for: [exp], timeout: 1.0)
    }
    
    func test_delete_hasNoSideEffectsOnEmptyCache() {
        let sut = makeSUT()
        
        let exp = expectation(description: "wait from response")
        sut.delete(id: "non-exist")
            .andThen(sut.retrieve())
            .subscribe(
                onSuccess: { result in
                    XCTAssertEqual(result, [])
                    exp.fulfill()
                }
            )
            .disposed(by: disposeBag)
        
        wait(for: [exp], timeout: 1.0)
    }
    
    func test_isFavorite_deliversFalseOnEmptyCache() {
        let sut = makeSUT()
        
        let exp = expectation(description: "wait from response")
        sut.isFavorite(id: "non-exist")
            .subscribe(
                onSuccess: { isFavorite in
                    XCTAssertFalse(isFavorite)
                    exp.fulfill()
                }
            )
            .disposed(by: disposeBag)
        
        wait(for: [exp], timeout: 1.0)
    }
    
    func test_isFavorite_deliversTrueWhenItemExists() {
        let sut = makeSUT()
        let restaurant = makeRestaurant(name: "kopi kita")
        
        let exp = expectation(description: "wait from response")
        
        sut.save(restaurant)
            .andThen(sut.isFavorite(id: restaurant.id))
            .subscribe(
                onSuccess: { isFavorite in
                    XCTAssertTrue(isFavorite)
                    exp.fulfill()
                }
            )
            .disposed(by: disposeBag)
        
        wait(for: [exp], timeout: 1.0)
    }
    
    //MARK: Helpers
    private func makeSUT(
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> RealmFavoriteStore {
        var configuration = Realm.Configuration()
        configuration.inMemoryIdentifier = UUID().uuidString
        inMemoryRealm = try! Realm(configuration: configuration)
        
        let sut = RealmFavoriteStore(configuration: configuration)
        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
    }
}
