import Foundation
import SwiftUI

class StockStore: ObservableObject {
    @Published var stocks: [Stock] = []
    @Published var cash: Double = 0.0
    
    // 기본 리밸런싱 기준 증감율 (8.0)
    @Published var threshold: Double = 12.0 {
        didSet { save() }
    }
    
    private let stocksKey = "stocksKey"
    private let cashKey = "cashKey"
    private let thresholdKey = "thresholdKey"
    
    init() {
        load()
    }
    
    func save() {
        if let encoded = try? JSONEncoder().encode(stocks) {
            UserDefaults.standard.set(encoded, forKey: stocksKey)
        }
        UserDefaults.standard.set(cash, forKey: cashKey)
        UserDefaults.standard.set(threshold, forKey: thresholdKey)
    }
    
    func load() {
        if let data = UserDefaults.standard.data(forKey: stocksKey),
           let decoded = try? JSONDecoder().decode([Stock].self, from: data) {
            stocks = decoded
        } else {
            stocks = defaultStocks()
            save()
        }
        cash = UserDefaults.standard.double(forKey: cashKey)
        if let storedThreshold = UserDefaults.standard.object(forKey: thresholdKey) as? Double {
            threshold = storedThreshold
        } else {
            threshold = 12.0
        }
    }
    
    func defaultStocks() -> [Stock] {
        return [
            Stock(id: UUID(), name: "KODEX 200TR", code: "278530", targetPercentage: 20, currentPrice: 11780, quantity: 965, category: "주식"),
            Stock(id: UUID(), name: "코리안리", code: "003690", targetPercentage: 10, currentPrice: 8240, quantity: 681, category: "주식"),
            Stock(id: UUID(), name: "맥쿼리인프라", code: "088980", targetPercentage: 16, currentPrice: 10500, quantity: 788, category: "주식"),
            Stock(id: UUID(), name: "ACE KRX금현물", code: "411060", targetPercentage: 14, currentPrice: 18975, quantity: 434, category: "주식"),
            Stock(id: UUID(), name: "ACE 미국30년국채액티브", code: "476760", targetPercentage: 8, currentPrice: 10065, quantity: 434, category: "현금 및 채권"),
            Stock(id: UUID(), name: "ACE 26-06 회사채", code: "461270", targetPercentage: 15, currentPrice: 10945, quantity: 751, category: "현금 및 채권"),
            Stock(id: UUID(), name: "TIGER 27-04회사채", code: "480260", targetPercentage: 17, currentPrice: 52430, quantity: 178, category: "현금 및 채권")
        ]
    }
    
    func resetData() {
        stocks = defaultStocks()
        cash = 234000
        threshold = 12.0
        save()
    }
    
    var combinedTarget: Double {
        stocks.map { $0.targetPercentage }.reduce(0, +)
    }
    
    var overallTotal: Double {
        stocks.map { $0.currentValue }.reduce(0, +) + cash
    }
    
    func needsRebalancing(for stock: Stock, threshold: Double) -> Bool {
        guard overallTotal > 0 else { return false }
        
        let currentFraction = stock.currentValue / overallTotal
        let targetFraction = stock.targetPercentage / 100.0
        
        // 목표 비율이 0인 경우
        if targetFraction == 0 {
            // 목표로 하지 않은 주식인데 보유중이면 리밸런싱 필요
            return currentFraction > 0
        }
        
        let changeFraction = (currentFraction - targetFraction) / targetFraction
        let thresholdFraction = threshold / 100.0
        return abs(changeFraction) >= thresholdFraction
    }

    func overallNeedsRebalancing(threshold: Double) -> Bool {
        guard overallTotal > 0 else { return false }
        for stock in stocks {
            if needsRebalancing(for: stock, threshold: threshold) {
                return true
            }
        }
        return false
    }
}
