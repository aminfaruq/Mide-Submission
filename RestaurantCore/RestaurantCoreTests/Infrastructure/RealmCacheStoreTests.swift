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
        .never()
    }
    
    func save(_ restaurants: [RestaurantEntity]) -> Completable {
        .never()
    }
}

final class RealmCacheStoreTests: XCTestCase {
    private let disposeBag = DisposeBag()
    
    private var inMemoryRealm: Realm?
    
    override func tearDown() {
        inMemoryRealm = nil
        super.tearDown()
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
