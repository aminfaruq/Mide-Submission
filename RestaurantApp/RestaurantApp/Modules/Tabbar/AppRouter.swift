//
//  AppRouter.swift
//  RestaurantApp
//
//  Created by Amin faruq on 01/11/26.
//

import FactoryKit
import UIKit

final class AppRouter {
    
    public static func createModule() -> UITabBarController {
       
        let homeVC = RestaurantListRouter.createModule(loader: Container.shared.restaurantListLoader.resolve())
        let homeNav = UINavigationController(rootViewController: homeVC)
        homeNav.tabBarItem = UITabBarItem(
            title: "Home",
            image: UIImage(systemName: "house"),
            selectedImage: UIImage(systemName: "house.fill")
        )
        
        let favoriteVC = RestaurantListRouter.createModule(loader: Container.shared.localFavoriteRestaurantListLoader.resolve())
        let favoriteNav = UINavigationController(rootViewController: favoriteVC)
        favoriteNav.tabBarItem = UITabBarItem(
            title: "Favorite",
            image: UIImage(systemName: "heart"),
            selectedImage: UIImage(systemName: "heart.fill")
        )
        
        let tabBarController = MainTabBarController(viewControllers: [homeNav, favoriteNav])
        return tabBarController
    }
}
