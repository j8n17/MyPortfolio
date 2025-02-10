import Foundation
import SwiftUI

struct Stock: Identifiable, Equatable, Codable {
    let id: UUID
    var name: String
    var code: String               // 종목 코드 (숫자만 저장됨)
    var targetPercentage: Double   // 목표 비율 (예: 20, 30, 50)
    var currentPrice: Int          // 현재 주가 (정수)
    var quantity: Int              // 보유 주식 수 (정수)
    var category: String           // "주식" 또는 "현금 및 채권"
    
    var currentValue: Double {
        Double(currentPrice * quantity)
    }
    
    var dailyVariation: Double = 0.0 // 전일 대비 변동 백분율 (예: 1.23, -0.56 등)
    var variationColor: Color { // 전일 대비 변동률에 대한 색상
        if dailyVariation > 0 {
            return .red
        } else if dailyVariation < 0 {
            return .blue
        } else {
            return .gray
        }
    }
}

extension Stock {
    // 외부에서 전체 자산과 리밸런싱 기준(threshold)을 설정할 수 있도록 static 프로퍼티들 추가
    static var totalAssets: Double = 0.0
    
    /// 주식의 이상적인 보유 수량을 계산하는 computed property
    /// Stock.overallTotalForRebalancing 값이 이미 설정되어 있다고 가정함.
    var desiredQuantity: Int {
        let overallTotal = Stock.totalAssets
        guard currentPrice > 0, overallTotal > 0 else { return 0 }
        return Int((overallTotal * (targetPercentage / 100) / Double(currentPrice)).rounded())
    }
    
    /// 전체 자산을 전달받아 현재 주식의 가치가 전체에서 차지하는 비율(%)을 계산합니다.
    var currentPercentage: Double {
        let overallTotal = Stock.totalAssets
        guard overallTotal > 0 else { return 0.0 }
        return Double(currentPrice * quantity) / overallTotal * 100
    }
    
    /// 전체 자산을 전달받아 목표 대비 증감율(%)을 계산합니다.
    var changeRate: Double {
        let cp = currentPercentage
        guard targetPercentage > 0 else { return 0.0 }
        return (cp - targetPercentage) / targetPercentage * 100
    }
    
    /// 전체 자산을 전달받아 현재 보유 수량과 목표 수량의 차이(조정 필요 수량)를 계산합니다.
    var adjustment: Int {
        return desiredQuantity - quantity
    }
}
