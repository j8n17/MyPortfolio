import SwiftUI

struct StockRowView: View {
    let stock: Stock
    let overallTotal: Double
    var onEdit: () -> Void
    var onDelete: () -> Void
    
    // 현재가 기반 현재 비중 계산
    private var currentPercentage: Double {
        overallTotal > 0 ? (Double(stock.currentPrice * stock.quantity) / overallTotal * 100) : 0.0
    }
    
    // 목표 대비 증감율 계산 (목표 비율이 0이면 0으로 처리)
    private var changeRate: Double {
        stock.targetPercentage > 0 ? (currentPercentage - stock.targetPercentage) / stock.targetPercentage * 100 : 0.0
    }
    
    // 목표 수량 계산 시, currentPrice가 0이면 0을 반환하여 0으로 나누는 상황을 방지합니다.
    private var desiredQuantity: Double {
        guard stock.currentPrice > 0, overallTotal > 0 else { return 0.0 }
        return overallTotal * (stock.targetPercentage / 100) / Double(stock.currentPrice)
    }
    
    // 보유 수량과 목표 수량의 차이 (조정 필요 수량)
    private var adjustment: Double {
        desiredQuantity - Double(stock.quantity)
    }
    
    // 전일 대비 백분율의 색상 결정
    private var variationColor: Color {
        if stock.dailyVariation > 0 {
            return .red
        } else if stock.dailyVariation < 0 {
            return .blue
        } else {
            return .gray
        }
    }
    
    var body: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 4) {
                Text(stock.name)
                    .font(.body)
                Text(stock.code)
                    .font(.caption2)
                    .foregroundColor(.gray)
                HStack(spacing: 0) {
                    Text("\(stock.currentPrice)원 ")
                    Text("(")
                        .foregroundColor(.gray)
                    Text("\(stock.dailyVariation, specifier: "%.2f")%")
                        .foregroundColor(variationColor)
                    Text(")")
                        .foregroundColor(.gray)
                }
                .font(.caption2)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("현재: \(currentPercentage, specifier: "%.1f")%")
                    .font(.caption)
                    .foregroundColor(.gray)
                Text("목표: \(stock.targetPercentage, specifier: "%.1f")%")
                    .font(.caption)
                    .foregroundColor(.gray)
                HStack(spacing: 0) {
                    Text(String(format: "%+6.1f", changeRate) + "%")
                        .monospacedDigit()
                        .foregroundColor(changeRate >= 0 ? .red : .blue)
                    Text(" | ")
                        .foregroundStyle(.secondary)
                    Text(String(format: "%+d", Int(adjustment.rounded())))
                        .monospacedDigit()
                    Text("주")
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { onEdit() }
    }
}

struct StockRowView_Previews: PreviewProvider {
    static var previews: some View {
        StockRowView(
            stock: Stock(
                id: UUID(),
                name: "예시 주식",
                code: "123456",
                targetPercentage: 20,
                currentPrice: 1000,
                quantity: 10,
                category: "주식",
                dailyVariation: 1.23
            ),
            overallTotal: 1000000,
            onEdit: {},
            onDelete: {}
        )
    }
}
