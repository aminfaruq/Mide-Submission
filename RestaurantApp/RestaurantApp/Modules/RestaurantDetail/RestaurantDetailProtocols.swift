//
//  RestaurantDetailProtocols.swift
//  RestaurantApp
//
//  Created by Amin faruq on 02/11/26.
//

import RestaurantCore
import RxSwift

public protocol RestaurantDetailViewProtocol: AnyObject {
    func showLoading()
    func hideLoading()
    func showRestaurant(_ restaurant: RestaurantDetailItemViewModel)
    func showMenus(_ results: [String])
    func showError(_ message: String)
    func showPopup()
    func setFavoriteStatus(isFavorite: Bool)
}

public protocol RestaurantDetailInteractorProtocol: AnyObject {
    func loadRestaurantDetail(id: String) -> Single<RestaurantDetailEntity>
    func addReview(body: AddReviewBody) -> Completable
    func isFavorite(id: String) -> Single<Bool>
    func toggleFavorite(restaurant: RestaurantEntity) -> Single<Bool>
}

public protocol RestaurantDetailPresenterProtocol: AnyObject {
    var view: RestaurantDetailViewProtocol? { get set }
    var interactor: RestaurantDetailInteractorProtocol? { get set }
    
    func viewDidLoad()
    func didAddReview(_ review: AddReviewBody)
    func didDismissPopup()
    func didPullToRefresh()
    func didTapFavoriteButton()
}
