//
//  FilterViewController.swift
//  COVID Tracker
//
//  Created by Sveta on 07.06.2021.
//  Copyright © 2021 Sveta. All rights reserved.
//

import UIKit

final class FilterViewController: UIViewController {
    
    public var completion: ((Country) -> Void)?
    
    private let tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .grouped)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        return tableView
    }()
    
    private var countries: [Country] = [] {
        didSet {
            tableView.reloadData()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Select Country"
        view.addSubview(tableView)
        tableView.dataSource = self
        tableView.delegate = self
        fetchCountries()
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .close,
            target: self,
            action: #selector(didTapClose))
        
    }

    @objc private func didTapClose() {
        dismiss(animated: true, completion: nil)
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        tableView.frame = view.bounds
    }
    
    private func fetchCountries() {
        APICaller.shared.getCountriesList { [weak self] result in
            switch result {
            case .success(let countries):
                self?.countries = countries
                
            case .failure(let error):
                print(error)
            }
        }
    }
}
 
// MARK: - TableViewDataSource

extension FilterViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return countries.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let country = countries[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        
        cell.textLabel?.text = country.Country
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let country = countries[indexPath.row]
        completion?(country)
        dismiss(animated: true, completion: nil)
    }
}
