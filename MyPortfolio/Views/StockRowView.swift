import SwiftUI

struct StockRowView: View {
    let stock: Stock
    let overallTotal: Double
    var onEdit: () -> Void
    var onDelete: () -> Void
    
    var body: some View {
        return HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 4) {
                Text(stock.name)
                    .font(.body)
                    .lineLimit(1)
                    .truncationMode(.tail)
                Text(stock.code)
                    .font(.caption2)
                    .foregroundColor(.gray)
                HStack(spacing: 0) {
                    Text("\(stock.currentPrice)원 ")
                    Text("(")
                        .foregroundColor(.gray)
                    Text("\(stock.dailyVariation, specifier: "%.2f")%")
                        .foregroundColor(stock.variationColor)
                    Text(")")
                        .foregroundColor(.gray)
                }
                .font(.caption2)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("현재: \(stock.currentPercentage, specifier: "%.1f")%")
                    .font(.caption)
                    .foregroundColor(.gray)
                Text("목표: \(stock.targetPercentage, specifier: "%.1f")%")
                    .font(.caption)
                    .foregroundColor(.gray)
                (Text(String(format: "%+6.1f", stock.changeRate) + "%")
                    .monospacedDigit()
                    .foregroundColor(stock.changeRate >= 0 ? .red : .blue)
                +
                Text(" | ")
                    .foregroundStyle(.secondary)
                +
                Text(String(format: "%+d", stock.adjustment))
                    .monospacedDigit()
                +
                Text("주"))
                    .lineLimit(1)
                    .truncationMode(.head)
            }
        }
        .contentShape(Rectangle())
    }
}

struct StockRowView_Previews: PreviewProvider {
    static var previews: some View {
        // 미리보기에서는 임의의 전체 자산 값을 전달합니다.
        StockRowView(
            stock: Stock(id: UUID(),
                         name: "Test Stock",
                         code: "123456",
                         targetPercentage: 20,
                         currentPrice: 100,
                         quantity: 10,
                         category: "주식",
                         dailyVariation: 1.23),
            overallTotal: 10000,
            onEdit: {},
            onDelete: {}
        )
        .previewLayout(.sizeThatFits)
    }
}
