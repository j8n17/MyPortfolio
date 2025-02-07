import SwiftUI
import CoreData

class StockStore: ObservableObject {
    @Published var stocks: [Stock] = []
    @Published var cash: Double = 0.0
    @Published var threshold: Double = 12.0
    
    private let context: NSManagedObjectContext
    private var settings: SettingsEntity?
    
    init(context: NSManagedObjectContext = PersistenceController.shared.container.viewContext) {
        self.context = context
        load()
    }
    
    func load() {
        let request: NSFetchRequest<StockEntity> = StockEntity.fetchRequest()
        do {
            let stockEntities = try context.fetch(request)
            if stockEntities.isEmpty {
                // 저장된 데이터가 없으면 defaultStocks 데이터를 사용하여 populate
                self.stocks = defaultStocks()
                // defaultStocks의 각 항목을 Core Data에 추가
                for stock in self.stocks {
                    let entity = StockEntity(context: context)
                    entity.update(from: stock)
                }
                try context.save()
            } else {
                self.stocks = stockEntities.map { $0.toStock }
            }
        } catch {
            print("Error fetching stocks: \(error)")
            self.stocks = []
        }
        
        // SettingsEntity 불러오기 또는 생성
        self.settings = SettingsEntity.fetchOrCreate(context: context)
        self.cash = settings?.cash ?? 0.0
        self.threshold = settings?.threshold ?? 12.0
    }

    
    func save() {
        // Core Data 저장 전, 기존 StockEntity들을 모두 삭제하고 현재 stocks 배열의 값을 다시 저장하는 방식 (간단한 구현 예시)
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = StockEntity.fetchRequest()
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        do {
            try context.execute(deleteRequest)
        } catch {
            print("Error deleting old stocks: \(error)")
        }
        
        // stocks 배열의 각 항목을 새 StockEntity로 추가
        for stock in stocks {
            let entity = StockEntity(context: context)
            entity.update(from: stock)
        }
        
        // Settings 업데이트
        settings?.cash = cash
        settings?.threshold = threshold
        
        do {
            try context.save()
        } catch {
            print("Error saving context: \(error)")
        }
    }
    
    func resetData() {
        // 기본 데이터를 다시 설정
        self.stocks = defaultStocks()
        self.cash = 234000
        self.threshold = 12.0
        save()
    }
    
    func defaultStocks() -> [Stock] {
        return [
            Stock(id: UUID(), name: "KODEX 200TR", code: "278530", targetPercentage: 20, currentPrice: 11780, quantity: 965, category: "주식", dailyVariation: 0.0),
            Stock(id: UUID(), name: "코리안리", code: "003690", targetPercentage: 10, currentPrice: 8240, quantity: 681, category: "주식", dailyVariation: 0.0),
            Stock(id: UUID(), name: "맥쿼리인프라", code: "088980", targetPercentage: 16, currentPrice: 10500, quantity: 788, category: "주식", dailyVariation: 0.0),
            Stock(id: UUID(), name: "ACE KRX금현물", code: "411060", targetPercentage: 14, currentPrice: 18975, quantity: 434, category: "주식", dailyVariation: 0.0),
            Stock(id: UUID(), name: "ACE 미국30년국채액티브", code: "476760", targetPercentage: 8, currentPrice: 10065, quantity: 434, category: "현금 및 채권", dailyVariation: 0.0),
            Stock(id: UUID(), name: "ACE 26-06 회사채", code: "461270", targetPercentage: 15, currentPrice: 10945, quantity: 751, category: "현금 및 채권", dailyVariation: 0.0),
            Stock(id: UUID(), name: "TIGER 27-04회사채", code: "480260", targetPercentage: 17, currentPrice: 52430, quantity: 178, category: "현금 및 채권", dailyVariation: 0.0)
        ]
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
        
        if targetFraction == 0 {
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
