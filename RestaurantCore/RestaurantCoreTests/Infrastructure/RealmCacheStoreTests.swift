//
//  RealmCacheStoreTests.swift
//  RestaurantCoreTests
//
//  Created by Amin faruq on 31/10/26.
//

import XCTest
import RxSwift
import RealmSwift
import RestaurantCore

final class RealmCacheObject: Object {
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


final class RealmCacheStore: CacheStore {
    
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
                let objects = realm.objects(RealmCacheObject.self)
                single(.success(objects.map { $0.toModel() }))
            } catch {
                single(.failure(error))
            }
            
            return Disposables.create()
        }
    }
    
    func save(_ restaurants: [RestaurantEntity]) -> Completable {
        return Completable.create { [weak self] completable in
            guard let self = self else { return Disposables.create() }
            
            do {
                let realm = try getRealm()
                let objects = restaurants.map { RealmCacheObject(from: $0) }
                
                try realm.write {
                    realm.add(objects, update: .modified)
                }
                
                completable(.completed)
            } catch {
                completable(.error(error))
            }
            
            return Disposables.create()
        }
    }
}

final class RealmCacheStoreTests: XCTestCase {
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
        let restaurant1 = makeRestaurant(name: "melting pot")
        let restaurant2 = makeRestaurant(name: "melting pot")
        let items = [restaurant1, restaurant2]
        
        let exp = expectation(description: "wait from response")
        sut.save(items)
            .andThen(sut.retrieve())
                .subscribe(
                    onSuccess: { result in
                        XCTAssertEqual(result, items)
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

        sut.save([originalRestaurant])
            .andThen(sut.save([updateRestaurant]))
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
    
    //MARK: Helpers
    private func makeSUT(
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> RealmCacheStore {
        var configuration = Realm.Configuration()
        configuration.inMemoryIdentifier = UUID().uuidString
        inMemoryRealm = try! Realm(configuration: configuration)
        
        let sut = RealmCacheStore(configuration: configuration)
        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
    }
}
