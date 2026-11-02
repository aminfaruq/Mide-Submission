//
//  RestaurantDetailViewController.swift
//  RestaurantApp
//
//  Created by Amin faruq on 01/11/26.
//

import UIKit
import Kingfisher
import RestaurantCore

class RestaurantDetailViewController: UIViewController {
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var restaurantNameLabel: UILabel!
    @IBOutlet weak var cityLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var horizontalStackView: UIStackView!
    @IBOutlet weak var verticalStackView: UIStackView!
    @IBOutlet weak var addReviewLabel: UILabel!
    
    private var restaurantId: String = ""
    private var favoriteBarButtonItem: UIBarButtonItem?
    private let refreshControl = UIRefreshControl()
    
    public var presenter: RestaurantDetailPresenterProtocol?

    override func viewDidLoad() {
        super.viewDidLoad()
        self.tabBarController?.tabBar.isHidden = true
        
        setupView()
        setupNavigationBar()
        
        presenter?.viewDidLoad()
    }
  
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.tabBarController?.tabBar.isHidden = false
    }
    
    private func setupView() {
        scrollView.refreshControl = refreshControl
        horizontalStackView.spacing = 12
        horizontalStackView.distribution = .fillProportionally
        verticalStackView.spacing = 12
        verticalStackView.distribution = .fill
        addReviewLabel.isUserInteractionEnabled = true
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didTapAddReview))
        addReviewLabel.addGestureRecognizer(tapGesture)
        refreshControl.addTarget(self, action: #selector(pullToRefresh), for: .valueChanged)
        
    }
    
    private func setupNavigationBar() {
        favoriteBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "heart"),
            style: .plain,
            target: self,
            action: #selector(didTapFavorite)
        )
        navigationItem.rightBarButtonItem = favoriteBarButtonItem
    }
    
    @objc func didTapFavorite() {
        presenter?.didTapFavoriteButton()
    }
    
    @objc func pullToRefresh() {
        presenter?.didPullToRefresh()
    }
    
    @objc func didTapAddReview() {
        let alert = UIAlertController(
            title: "Add Review",
            message: "Share your experience with this restaurant",
            preferredStyle: .alert
        )
        
        alert.addTextField { textField in
            textField.placeholder = "Your Name"
            textField.autocapitalizationType = .words
        }
        
        alert.addTextField { textField in
            textField.placeholder = "Your Review..."
            textField.autocapitalizationType = .sentences
        }
        
        let submitAction = UIAlertAction(title: "Submit", style: .default) { [weak self] _ in
            guard let self = self,
                  let name = alert.textFields?[0].text, !name.trimmingCharacters(in: .whitespaces).isEmpty,
                  let review = alert.textFields?[1].text, !review.trimmingCharacters(in: .whitespaces).isEmpty else {
                return
            }
            
            let body = AddReviewBody(id: self.restaurantId, name: name, review: review)
            self.presenter?.didAddReview(body)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        alert.addAction(submitAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true)
    }

}

extension RestaurantDetailViewController: RestaurantDetailViewProtocol {
    func showLoading() {
        contentView.isHidden = true
        activityIndicatorView.startAnimating()
    }
    
    func hideLoading() {
        contentView.isHidden = false
        refreshControl.endRefreshing()
        activityIndicatorView.stopAnimating()
    }
    
    func showRestaurant(_ restaurant: RestaurantDetailItemViewModel) {
        self.restaurantId = restaurant.id
        self.imageView.kf.indicatorType = .activity
        self.imageView.kf.setImage(with: restaurant.pictureURL)
        self.restaurantNameLabel.text = restaurant.name
        self.cityLabel.text = restaurant.city
        self.descriptionLabel.text = restaurant.description

        verticalStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        restaurant.customerReviews.forEach { review in
            let view = ReviewView.instantiate()
            view.setupLayout()
            view.configure(review)
            verticalStackView.addArrangedSubview(view)
        }
        
        self.view.layoutIfNeeded()
    }
    
    func showMenus(_ results: [String]) {
        let space = UIView()
        space.translatesAutoresizingMaskIntoConstraints = false
        horizontalStackView.layoutMargins = UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 0)
        
        horizontalStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        horizontalStackView.addArrangedSubview(space)
        results.forEach { menuName in
            let card = MenuView(title: menuName)
            horizontalStackView.addArrangedSubview(card)
        }
    }
    
    func showError(_ message: String) {
        let alert = UIAlertController(
            title: "Something Went Wrong",
            message: message,
            preferredStyle: .alert
        )
        
        let retryAction = UIAlertAction(title: "Retry", style: .default) { [weak self] _ in
            self?.presenter?.viewDidLoad()
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        alert.addAction(retryAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true)
    }
    
    func showPopup() {
        let alert = UIAlertController(title: "Success", message: "Your review has been sent!", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak self] _ in
            self?.presenter?.didDismissPopup()
        }))
        present(alert, animated: true)
    }
    
    func setFavoriteStatus(isFavorite: Bool) {
        let imageName = isFavorite ? "heart.fill" : "heart"
        favoriteBarButtonItem?.image = UIImage(systemName: imageName)
        favoriteBarButtonItem?.tintColor = isFavorite ? .systemRed : .label
    }
}
