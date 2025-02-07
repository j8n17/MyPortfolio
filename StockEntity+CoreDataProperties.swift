import Foundation
import CoreData

extension StockEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<StockEntity> {
        return NSFetchRequest<StockEntity>(entityName: "StockEntity")
    }
    
    @NSManaged public var id: UUID?
    @NSManaged public var name: String?
    @NSManaged public var code: String?
    @NSManaged public var targetPercentage: Double
    @NSManaged public var currentPrice: Int64
    @NSManaged public var quantity: Int64
    @NSManaged public var category: String?
    @NSManaged public var dailyVariation: Double
}

extension StockEntity {
    /// Core Data의 StockEntity를 기존의 Stock 구조체로 변환
    var toStock: Stock {
        Stock(
            id: self.id ?? UUID(),
            name: self.name ?? "",
            code: self.code ?? "",
            targetPercentage: self.targetPercentage,
            currentPrice: Int(self.currentPrice),
            quantity: Int(self.quantity),
            category: self.category ?? "",
            dailyVariation: self.dailyVariation
        )
    }
    
    /// Stock 구조체의 값을 Core Data 객체에 반영
    func update(from stock: Stock) {
        self.id = stock.id
        self.name = stock.name
        self.code = stock.code
        self.targetPercentage = stock.targetPercentage
        self.currentPrice = Int64(stock.currentPrice)
        self.quantity = Int64(stock.quantity)
        self.category = stock.category
        self.dailyVariation = stock.dailyVariation
    }
}
