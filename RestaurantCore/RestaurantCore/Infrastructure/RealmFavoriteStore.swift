//
//  RealmFavoriteStore.swift
//  RestaurantCore
//
//  Created by Amin faruq on 31/10/26.
//

import RxSwift
import RealmSwift

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

public final class RealmFavoriteStore: FavoriteStore {
    
    private let configuration: Realm.Configuration
    
    public init(configuration: Realm.Configuration = .defaultConfiguration) {
        self.configuration = configuration
    }
    
    private func getRealm() throws -> Realm {
        try Realm(configuration: configuration)
    }
    
    public func retrieve() -> Single<[RestaurantEntity]> {
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
    
    public func save(_ restaurant: RestaurantEntity) -> Completable {
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
    
    public func delete(id: String) -> Completable {
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
    
    public func isFavorite(id: String) -> Single<Bool> {
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
