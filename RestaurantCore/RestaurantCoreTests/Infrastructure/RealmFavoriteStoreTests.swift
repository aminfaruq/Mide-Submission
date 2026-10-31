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

final class RealmFavoriteObject: Object {
    @Persisted(primaryKey: true) var id: String
    @Persisted var name: String = ""
    @Persisted var restaurantDescription: String = ""
    @Persisted var pictureId: String = ""
    @Persisted var city: String = ""
    @Persisted var rating: Double = 0
    
    convenience init(from entity: RestaurantEntity) {
        self.init()
        self.id = entity.id
        self.name = entity.name
        self.restaurantDescription = entity.description
        self.pictureId = entity.pictureId
        self.city = entity.city
        self.rating = entity.rating
    }
    
    func toModel() -> RestaurantEntity {
        .init(
            id: id,
            name: name,
            description: restaurantDescription,
            pictureId: pictureId,
            city: city,
            rating: rating
        )
    }
}

final class RealmFavoriteStore: FavoriteStore {
    
    private let configuration: Realm.Configuration
    
    public init(configuration: Realm.Configuration = .defaultConfiguration) {
        self.configuration = configuration
    }
    
    private func getRealm() throws -> Realm {
        try Realm(configuration: configuration)
    }
    
    func retrieve() -> Single<[RestaurantEntity]> {
        return Single.create { [weak self] single in
            guard let self = self else { return Disposables.create() }
            
            do {
                let realm = try self.getRealm()
                let objects = realm.objects(RealmFavoriteObject.self)
                single(.success(objects.map { $0.toModel() }))
            } catch {
                single(.failure(error))
            }
            
            
            return Disposables.create()
        }
    }
    
    func save(_ restaurant: RestaurantEntity) -> Completable {
        return Completable.create { [weak self] completable in
            guard let self = self else { return Disposables.create() }
            
            do {
                let realm = try getRealm()
                let object = RealmFavoriteObject(from: restaurant)
                
                try realm.write {
                    realm.add(object, update: .modified)
                }
                
                completable(.completed)
            } catch {
                completable(.error(error))
            }
            
            return Disposables.create()
        }
    }
    
    func delete(id: String) -> Completable {
        return Completable.create { [weak self] completable in
            guard let self = self else { return Disposables.create() }
            do {
                let realm = try getRealm()
                if let object = realm.object(ofType: RealmFavoriteObject.self, forPrimaryKey: id) {
                    try realm.write {
                        realm.delete(object)
                    }
                }
                completable(.completed)
            } catch {
                completable(.error(error))
            }
            
            return Disposables.create()
        }
    }
    
    func isFavorite(id: String) -> Single<Bool> {
        return Single.create { [weak self] single in
            guard let self = self else { return Disposables.create() }

            do {
                let realm = try self.getRealm()
                if realm.object(ofType: RealmFavoriteObject.self, forPrimaryKey: id) != nil {
                    single(.success(true))
                } else {
                    single(.success(false))
                }
            } catch {
                single(.failure(error))
            }
            
            return Disposables.create()
        }
    }
}

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
