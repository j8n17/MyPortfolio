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
    
    /// 전일 대비 변동 백분율 (예: 1.23, -0.56 등)
    var dailyVariation: Double = 0.0
    
    // 현재 가치 = 현재가 × 보유 수량 (Double로 계산)
    var currentValue: Double {
        Double(currentPrice * quantity)
    }
}

extension Stock {
    /// dailyVariation 값에 따라 전일 대비 변동률에 적절한 색상을 반환합니다.
    var variationColor: Color {
        if dailyVariation > 0 {
            return .red
        } else if dailyVariation < 0 {
            return .blue
        } else {
            return .gray
        }
    }
}
