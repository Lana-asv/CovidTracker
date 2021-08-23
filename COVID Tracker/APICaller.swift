//
//  APICaller.swift
//  COVID Tracker
//
//  Created by Sveta on 07.06.2021.
//  Copyright © 2021 Sveta. All rights reserved.
//

import Foundation

extension DateFormatter {
    static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
        formatter.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        formatter.locale = .current
        return formatter
    }()
    
    static let prettyFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeZone = .current
        formatter.locale = .current
        return formatter
    }()
}

final class APICaller {
    static let shared = APICaller()
    
    private struct Constants {
        static let allCountriesUrl = URL(string: "https://api.covid19api.com/countries")
    }
    
    enum DataScope {
        case country(Country)
    }
    
    public func getCovidData(
        for scope: DataScope,
        completion: @escaping (Result<[DayData], Error>) -> Void
    ) {
        let urlString: String
        switch scope {
        case .country(let country):
            let from = "2020-03-01T00:00:00Z"
            let to = DateFormatter.dayFormatter.string(from: Date())
            urlString = "https://api.covid19api.com/total/country/\(country.Slug)/status/confirmed?from=\(from)&to=\(to)"
        }
        
        guard let url = URL(string: urlString) else {
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { data, _, error in
            if let err = error {
                DispatchQueue.main.async {
                    completion(.failure(err))
                }
                return
            }

            guard let data = data else {
                return
            }
            
            do {
                let result = try JSONDecoder().decode(Array<CovidDayData>.self, from: data)
                
                let models: [DayData] = result.compactMap {
                    guard let date = DateFormatter.dayFormatter.date(from: $0.date) else {
                        return nil
                    }
                    let value = $0.cases
                    return DayData(date: date, count: value)
                }
                DispatchQueue.main.async {
                    completion(.success(models.reversed()))
                }
            }
            catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
        task.resume()
    }
    
    public func getCountriesList(completion: @escaping (Result<[Country], Error>) -> Void) {
        guard let url = Constants.allCountriesUrl else { return }
        
        let task = URLSession.shared.dataTask(with: url) { data, _, error in
            if let err = error {
                DispatchQueue.main.async {
                    completion(.failure(err))
                }
                return
            }

            guard let data = data else {
                return
            }
            
            do {
                let result = try JSONDecoder().decode(Array<Country>.self, from: data)
                let sorted = result.sorted { $0.Slug.compare($1.Slug) == .orderedAscending }
                
                DispatchQueue.main.async {
                    completion(.success(sorted))
                }
            }
            catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
        
        task.resume()
    }
}

// MARK: - Models

struct Country: Codable {
    let Country: String
    let Slug: String
    let ISO2: String
}

struct CovidDataResponse: Codable {
    let data: [CovidDayData]
}

struct CovidDayData: Codable {
    enum CodingKeys: String, CodingKey {
        case country = "Country"
        case countryCode = "CountryCode"
        case cases = "Cases"
        case status = "Status"
        case date = "Date"
    }
    
    let country: String
    let countryCode: String
    let cases: Int
    let status: String
    let date: String
}

struct DayData {
    let date: Date
    let count: Int
}
