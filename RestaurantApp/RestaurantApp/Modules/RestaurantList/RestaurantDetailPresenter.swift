//
//  RestaurantDetailPresenter.swift
//  RestaurantApp
//
//  Created by Amin faruq on 02/11/26.
//

import RxSwift
import RestaurantCore
import Foundation

public final class RestaurantDetailPresenter : RestaurantDetailPresenterProtocol {
    public weak var view: RestaurantDetailViewProtocol?
    
    public var interactor: RestaurantDetailInteractorProtocol?
    
    private let disposeBag = DisposeBag()
    
    private var currentRestaurantEntity: RestaurantEntity?
    
    private let id: String
    
    public init(id: String) {
        self.id = id
    }
    
    public func viewDidLoad() {
        requestDetail()
        checkFavoriteStatus()
    }
    
    public func didAddReview(_ review: AddReviewBody) {
        interactor?.addReview(body: review)
            .observe(on: MainScheduler.instance)
            .subscribe(
                onCompleted: {  [weak self] in
                    guard let self = self else { return }
                    view?.showPopup()
                },
                onError: { [weak self] error in
                    guard let self = self else { return }
                    view?.showError(error.localizedDescription)
                }
            )
            .disposed(by: disposeBag)
    }
    
    public func didDismissPopup() {
        requestDetail()
    }
    
    public func didPullToRefresh() {
        requestDetail()
    }
    
    public func didTapFavoriteButton() {
        guard let currentResult = currentRestaurantEntity else { return }
        
        interactor?.toggleFavorite(restaurant: currentResult)
            .observe(on: MainScheduler.instance)
            .subscribe(
                onSuccess: { [weak self] isFavorite in
                    guard let self = self else { return }
                    view?.setFavoriteStatus(isFavorite: isFavorite)
                },
                onFailure: {  [weak self] error in
                    guard let self = self else { return }
                    view?.showError(error.localizedDescription)
                }
            )
            .disposed(by: disposeBag)
    }
    
    private func checkFavoriteStatus() {
        interactor?.isFavorite(id: id)
            .observe(on: MainScheduler.instance)
            .subscribe(
                onSuccess: { [weak self] isFavorite in
                    guard let self = self else { return }
                    view?.setFavoriteStatus(isFavorite: isFavorite)
                },
                onFailure: { [weak self] _ in
                    guard let self = self else { return }
                    view?.setFavoriteStatus(isFavorite: false)
                }
            )
            .disposed(by: disposeBag)
    }
    
    private func requestDetail() {
        view?.showLoading()
        interactor?.loadRestaurantDetail(id: id)
            .observe(on: MainScheduler.instance)
            .subscribe(
                onSuccess: { [weak self] result in
                    guard let self = self else { return }
                    view?.hideLoading()
                    self.currentRestaurantEntity = result.toRestaurantEntity()
                    view?.showRestaurant(RestaurantDetailItemViewModel(from: result))
                    let menus = (result.menus.foods + result.menus.drinks).map(\.name)
                    view?.showMenus(menus)
                },
                onFailure: { [weak self] error in
                    guard let self = self else { return }
                    view?.hideLoading()
                    view?.showError(error.localizedDescription)
                }
            )
            .disposed(by: disposeBag)
    }
    
    nonisolated deinit {}
}
