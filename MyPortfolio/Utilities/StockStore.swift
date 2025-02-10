import SwiftUI
import CoreData

class StockStore: ObservableObject {
    @Published var stocks: [Stock] = []
    @Published var cash: Double = 0.0
    @Published var threshold: Double = 12.0
    
    /// 모든 주식의 목표 비율 합계 계산
    var combinedTarget: Double {
        stocks.map { $0.targetPercentage }.reduce(0, +)
    }
    
    /// 전체 자산 = 모든 주식의 현재 가치 합계 + 현금
    var totalAssets: Double {
        stocks.map { $0.currentValue }.reduce(0, +) + cash
    }
    
    var maxChange: Double {
        // 각 주식의 changeRate(withOverallTotal:) 값을 절대값으로 변환한 후 최대값을 구함.
        return stocks.map { abs($0.changeRate) }.max() ?? 0.0
    }
    
    var needRebalance: Bool {
        return maxChange > threshold
    }
    
    /// 현금 비중을 숫자(%)로 계산 (전체 자산 대비 현금의 비율)
    var cashPercentage: Double {
        guard totalAssets > 0 else { return 0.0 }
        return cash / totalAssets * 100
    }
    
    private let context: NSManagedObjectContext
    private var settings: SettingsEntity?
    
    init(context: NSManagedObjectContext = PersistenceController.shared.container.viewContext) {
        self.context = context
        load()
        // 메인 컨텍스트의 변경을 감지하면 load()를 호출하여 published 프로퍼티를 업데이트합니다.
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(contextDidChange(_:)),
                                               name: NSNotification.Name.NSManagedObjectContextObjectsDidChange,
                                               object: context)
    }
    
    @objc private func contextDidChange(_ notification: Notification) {
        DispatchQueue.main.async {
            self.load()
        }
    }
    
    /// 선택된 주식들에 대해 리밸런싱을 수행하는 함수 (Stock의 desiredQuantity computed property 사용)
    func rebalanceStocks(selectedIDs: Set<Stock.ID>) {
        let pastTotal = self.totalAssets
        for index in stocks.indices {
            if selectedIDs.contains(stocks[index].id) {
                let stock = stocks[index]
                if stock.targetPercentage == 0 || stock.currentPrice <= 0 {
                    stocks[index].quantity = 0
                } else {
                    stocks[index].quantity = stock.desiredQuantity
                }
            }
        }
        self.cash = pastTotal - stocks.map { $0.currentValue }.reduce(0, +)
        save()
    }
    
    /// API를 통해 각 주식의 현재 가격, 변동률, 주식 이름을 업데이트하는 비동기 함수
    func updateStockPrices() async {
        let keys = await getKey()
        for i in stocks.indices {
            let code = stocks[i].code
            async let priceResult = StockPriceFetcher.fetchCurrentPrice(for: code, using: keys)
            async let fetchedName = StockPriceFetcher.fetchStockName(for: code, using: keys)
            let (result, name) = await (priceResult, fetchedName)
            
            // 메인 스레드에서 published 프로퍼티 업데이트 실행
            await MainActor.run {
                if result.price > 0 {
                    stocks[i].currentPrice = result.price
                    stocks[i].dailyVariation = result.variation
                }
                stocks[i].name = name
            }
        }
        save()
    }
    
    func load() {
        let request: NSFetchRequest<StockEntity> = StockEntity.fetchRequest()
        do {
            let stockEntities = try context.fetch(request)
            if stockEntities.isEmpty {
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
        
        Stock.totalAssets = self.totalAssets
    }
    
    func save() {
        // 기존 StockEntity들을 삭제하기 위해 NSBatchDeleteRequest를 사용합니다.
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = StockEntity.fetchRequest()
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        deleteRequest.resultType = .resultTypeObjectIDs
        
        do {
            if let result = try context.execute(deleteRequest) as? NSBatchDeleteResult,
               let objectIDs = result.result as? [NSManagedObjectID] {
                let changes = [NSDeletedObjectsKey: objectIDs]
                let mainContext = PersistenceController.shared.container.viewContext
                NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes, into: [mainContext])
            }
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
            // 저장 후 전체 자산을 반영하여 총 자산 업데이트
            Stock.totalAssets = self.totalAssets
        } catch {
            print("Error saving context: \(error)")
        }
    }
    
    func resetData() {
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
}
