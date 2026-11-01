//
//  RestaurantListViewController.swift
//  RestaurantApp
//
//  Created by Amin faruq on 01/11/26.
//

import UIKit

class RestaurantListViewController: UIViewController {
    
    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
    
    private lazy var emptyView: EmptyView = {
        let view = EmptyView.instantiate()
        return view
    }()
    
    private lazy var searchController: UISearchController = {
        let search = UISearchController(searchResultsController: nil)
        search.searchResultsUpdater = self
        search.searchBar.delegate = self
        search.searchBar.sizeToFit()
        search.obscuresBackgroundDuringPresentation = false
        search.searchBar.placeholder = "Search restaurant..."
        search.hidesNavigationBarDuringPresentation = false
        return search
    }()
    
    private let refreshControl = UIRefreshControl()
    
    private var restaurants = [RestaurantItemViewModel]()
    private var currentQuery = ""

    var presenter: RestaurantListPresenterProtocol?

    override func viewDidLoad() {
        super.viewDidLoad()
        presenter?.viewDidLoad()
        setupLayout()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        
        presenter?.viewDidLoad()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    private func setupLayout() {
        view.backgroundColor = .systemBackground
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(
            UINib(nibName: RestaurantTableViewCell.identifier, bundle: nil),
            forCellReuseIdentifier: RestaurantTableViewCell.identifier)
        
        tableView.tableHeaderView = searchController.searchBar
        definesPresentationContext = true
        tableView.refreshControl = refreshControl
        refreshControl.backgroundColor = .clear
        refreshControl.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
    }
    
    @objc private func handleRefresh() {
        presenter?.didPullToRefresh()
    }
    
    private func updateEmptyState() {
        if restaurants.isEmpty {
            emptyView.configure(title: currentQuery)
            tableView.backgroundView = emptyView
            tableView.separatorStyle = .none
        } else {
            tableView.backgroundView = nil
            tableView.separatorStyle = .singleLine
        }
    }
}

extension RestaurantListViewController: UISearchResultsUpdating, UISearchBarDelegate {
    func updateSearchResults(for searchController: UISearchController) {
        let query = searchController.searchBar.text ?? ""
        self.currentQuery = query
        presenter?.didSearch(query)
    }
}

extension RestaurantListViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return restaurants.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: RestaurantTableViewCell.identifier, for: indexPath) as? RestaurantTableViewCell else {
            return UITableViewCell()
        }
        
        cell.configure(restaurants[indexPath.row])
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        presenter?.didSelectRestaurant(id: restaurants[indexPath.row].id)
    }
}

extension RestaurantListViewController: RestaurantListViewProtocol {
    
    func showLoading() {
        if restaurants.isEmpty {
            activityIndicatorView.startAnimating()
            tableView.isHidden = true
        }
    }
    
    func hideLoading() {
        activityIndicatorView.stopAnimating()
        refreshControl.endRefreshing()
    }
    
    func showRestaurants(_ restaurants: [RestaurantItemViewModel]) {
        self.restaurants = restaurants
        tableView.isHidden = false
        updateEmptyState()
        self.tableView.reloadData()
    }
    
    func showError(_ message: String) {
        let alert = UIAlertController(title: "Alert", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("Retry", comment: "Default action"), style: .default, handler: { [weak self] _ in
            guard let self = self else { return }
            presenter?.didPullToRefresh()
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
}
