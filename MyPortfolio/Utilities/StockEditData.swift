import Foundation

struct StockEditData: Identifiable, Hashable {
    var id: UUID
    // 이름과 현재가는 API를 통해 가져올 것이므로 빈 문자열로 초기화하거나, 기존 주식 수정 시 참고용으로만 사용합니다.
    var name: String
    var code: String         // 종목 코드 (문자열)
    var targetPercentage: String
    var currentPrice: String // 실제 입력은 받지 않으므로 무시됨
    var quantity: String           // 정수 입력값을 문자열로 관리
    var category: String           // "주식" 또는 "현금 및 채권"
    
    init(stock: Stock?) {
        if let stock = stock {
            self.id = stock.id
            // API를 통해 최신 정보를 가져올 것이므로 기존 값은 참고용으로만 남겨둡니다.
            self.name = stock.name
            self.code = stock.code
            self.targetPercentage = String(stock.targetPercentage)
            self.currentPrice = String(stock.currentPrice)
            self.quantity = String(stock.quantity)
            self.category = stock.category
        } else {
            self.id = UUID()
            self.name = ""
            self.code = ""
            self.targetPercentage = ""
            self.currentPrice = ""
            self.quantity = ""
            self.category = "주식"
        }
    }
    
    /// 이 함수는 더 이상 사용하지 않고, 저장 시 API로 값을 채운 후 Stock 객체를 생성합니다.
    func toStock() -> Stock? {
        if let target = Double(targetPercentage),
           let price = Int(currentPrice),
           let qty = Int(quantity),
           !code.isEmpty {
            return Stock(id: id, name: name, code: code, targetPercentage: target, currentPrice: price, quantity: qty, category: category, dailyVariation: 0.0)
        }
        return nil
    }
}
