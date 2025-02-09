import Foundation

final class StockRefreshOperation: Operation, @unchecked Sendable {
    override func main() {
        if self.isCancelled { return }
        
        let context = PersistenceController.shared.container.newBackgroundContext()
        let stockStore = StockStore(context: context)
        
        // API 키(토큰 등)를 미리 받아둠
        var keys: APIKeys?
        let keyGroup = DispatchGroup()
        keyGroup.enter()
        Task {
            keys = await getKey()
            keyGroup.leave()
        }
        keyGroup.wait()
        guard let keys = keys else { return }
        
        let group = DispatchGroup()
        for i in stockStore.stocks.indices {
            group.enter()
            let code = stockStore.stocks[i].code
            Task {
                let (price, variation) = await StockPriceFetcher.fetchCurrentPrice(for: code, using: keys)
                if price > 0 {
                    stockStore.stocks[i].currentPrice = price
                    stockStore.stocks[i].dailyVariation = variation
                }
                group.leave()
            }
        }
        
        group.wait()
        stockStore.save()
        
        NotificationManager.shared.scheduleNotificationIfNeeded(stockStore: stockStore)
    }
}
