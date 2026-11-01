//
//  RestaurantDetailInteractor.swift
//  RestaurantApp
//
//  Created by Amin faruq on 01/11/26.
//

import RxSwift
import RestaurantCore

public protocol RestaurantDetailInteractorProtocol: AnyObject {
    func loadRestaurantDetail(id: String) -> Single<RestaurantDetailEntity>
    func addReview(body: AddReviewBody) -> Completable
    func isFavorite(id: String) -> Single<Bool>
    func toggleFavorite(restaurant: RestaurantEntity) -> Single<Bool>
}

public final class RestaurantDetailInteractor: RestaurantDetailInteractorProtocol {
    
    private let loader: RestaurantDetailLoader
    private let service: FavoriteService
    
    public init(loader: RestaurantDetailLoader, service: FavoriteService) {
        self.loader = loader
        self.service = service
    }
    
    public func loadRestaurantDetail(id: String) -> Single<RestaurantDetailEntity> {
        return loader.loadRestaurantDetail(id: id)
    }
    
    public func addReview(body: AddReviewBody) -> Completable {
        return loader.addReview(review: body)
    }
    
    public func isFavorite(id: String) -> Single<Bool> {
        return service.isFavorite(id: id)
    }
    
    public func toggleFavorite(restaurant: RestaurantEntity) -> Single<Bool> {
        return service.isFavorite(id: restaurant.id)
            .flatMap { [weak self] isFavorite in
                guard let self = self else { return .just(false) }
                
                if isFavorite {
                    return self.service.remove(id: restaurant.id)
                        .andThen(.just(false))
                } else {
                    return self.service.save(restaurant)
                        .andThen(.just(true))
                }
            }
    }
    
    nonisolated deinit {}
}
