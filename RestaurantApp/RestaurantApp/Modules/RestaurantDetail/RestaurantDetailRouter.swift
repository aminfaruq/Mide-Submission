//
//  RestaurantDetailRouter.swift
//  RestaurantApp
//
//  Created by Amin faruq on 02/11/26.
//

import FactoryKit
import UIKit

final class RestaurantDetailRouter {
    
    static func createModule(id: String) -> UIViewController {
        let view = RestaurantDetailViewController()
        
        let interactor = RestaurantDetailInteractor(loader: Container.shared.restaurantDetailLoader.resolve(), service: Container.shared.favoriteService.resolve())
        let presenter = RestaurantDetailPresenter(id: id)
        
        view.presenter = presenter
        presenter.view = view
        presenter.interactor = interactor
        
        return view
    }
}
