//
//  ViewController.swift
//  COVID Tracker
//
//  Created by Sveta on 07.06.2021.
//  Copyright © 2021 Sveta. All rights reserved.
//

import Charts 
import UIKit

// Data covid cases
final class ViewController: UIViewController {
    private var scope: APICaller.DataScope = .country(Country(Country: "Russian Federation", Slug: "russia", ISO2: "RU"))

    private static let numberFormatter: NumberFormatter = {
       let formatter = NumberFormatter()
        formatter.formatterBehavior = .default
        formatter.locale = .current
        return formatter
    }()
    
    private let tableView: UITableView = {
        let tableView = UITableView(frame: .zero)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        return tableView
    }()
    
    private var dayData: [DayData] = [] {
        didSet {
            tableView.reloadData()
            createGraph()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Covid Cases"
        configureTableView()
        createFilterButton()
        fetchData()
    }
    
    private func configureTableView() {
        view.addSubview(tableView)
        tableView.dataSource = self
    }
    
    private func createFilterButton() {
        let buttomTitle: String = {
            switch scope {
            case .country(let country):
                return country.Country
            }
        }()
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: buttomTitle,
            style: .done,
            target: self,
            action: #selector(didTapFilter))
    }
    
    @objc private func didTapFilter() {
        let vc = FilterViewController()
        vc.completion = { [weak self] country in
            self?.scope = .country(country)
            self?.fetchData()
            self?.createFilterButton()
        }
        let navVC = UINavigationController(rootViewController: vc)
        present(navVC, animated: true)
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        tableView.frame = view.bounds
    }
    
    private func createGraph() {
        let width = view.bounds.width
        let height = ceil(width / 1.5)
        let frame = CGRect(x: 0.0, y: 0.0, width: width, height: height)
        let headerView = UIView(frame: frame)
        headerView.clipsToBounds = true
        
        let chart = BarChartView(frame: frame)
        chart.data = prepareChartData()
        headerView.addSubview(chart)
        
        tableView.tableHeaderView = headerView
    }
    
    private func prepareChartData() -> BarChartData {
        let set = dayData.prefix(30)
        var entries: [BarChartDataEntry] = []
        for index in 0..<set.count {
            let data = set[index]
            let x = set.count - index
            let entry = BarChartDataEntry(x: Double(x), y: Double(data.count))
            entries.append(entry)
        }
        
        let dataSet = BarChartDataSet(entries: entries)
        dataSet.colors = ChartColorTemplates.joyful()

        return BarChartData(dataSet: dataSet)
    }
        
    private func fetchData() {
        APICaller.shared.getCovidData(for: scope) { [weak self] result in
            switch result {
            case .success(let dayData):
                self?.dayData = dayData
            case .failure(let error):
                print(error)
            }
        }
    }
}

// MARK: - TableViewDataSource
    
extension ViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dayData.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let data = dayData[indexPath.row]
        let cell  = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = createText(with: data)
        return cell
    }
    
    private func createText(with data: DayData) -> String? {
        let dateString = DateFormatter.prettyFormatter.string(from: data.date)
        let total = Self.numberFormatter.string(from: NSNumber(value: data.count))
        return "\(dateString): \(total ?? "\(data.count)")"
    }
}
