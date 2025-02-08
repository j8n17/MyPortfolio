import Foundation

final class StockRefreshOperation: Operation, @unchecked Sendable {
    override func main() {
        if self.isCancelled { return }
        
        // 새로운 백그라운드 context 생성
        let context = PersistenceController.shared.container.newBackgroundContext()
        let stockStore = StockStore(context: context)
        
        // 모든 주식의 최신 가격 업데이트 (비동기 작업이므로 DispatchGroup 사용)
        let group = DispatchGroup()
        
        for i in stockStore.stocks.indices {
            group.enter()
            let code = stockStore.stocks[i].code
            Task {
                let (price, variation) = await StockPriceFetcher.fetchCurrentPrice(for: code)
                if price > 0 {
                    stockStore.stocks[i].currentPrice = price
                    stockStore.stocks[i].dailyVariation = variation
                }
                group.leave()
            }
        }
        
        // 모든 업데이트가 끝날 때까지 대기
        group.wait()
        stockStore.save()
        
        // 업데이트 후 리밸런싱 조건 판단 후 알림 예약
        NotificationManager.shared.scheduleNotificationIfNeeded(stockStore: stockStore)
    }
}
