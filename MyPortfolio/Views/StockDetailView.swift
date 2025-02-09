import SwiftUI

struct StockDetailView: View {
    @Environment(\.dismiss) var dismiss
    @State var detailData: StockEditData
    var onSave: (Stock) -> Void

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("주식 정보")) {
                    Picker("종목 유형", selection: $detailData.category) {
                        Text("주식").tag("주식")
                        Text("현금 및 채권").tag("현금 및 채권")
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    
                    HStack {
                        Text("종목 코드")
                        TextField("예: 278530", text: $detailData.code)
                            .keyboardType(.numbersAndPunctuation)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    HStack {
                        Text("목표 비율")
                        TextField("예: 20.0", text: $detailData.targetPercentage)
                            .keyboardType(.numbersAndPunctuation)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    HStack {
                        Text("보유 수량")
                        TextField("예: 10", text: $detailData.quantity)
                            .keyboardType(.numbersAndPunctuation)
                            .multilineTextAlignment(.trailing)
                    }
                }
            }
            .navigationTitle(detailData.name.isEmpty ? "주식 정보" : detailData.name)
            .navigationBarItems(
                leading: Button("취소") { dismiss() },
                trailing: Button("저장") { saveStock() }
            )
        }
    }
    
    private func saveStock() {
        Task {
            let keys = await getKey()
            let (price, variation) = await StockPriceFetcher.fetchCurrentPrice(for: detailData.code, using: keys)
            let name = await StockPriceFetcher.fetchStockName(for: detailData.code, using: keys)
            
            guard let target = Double(detailData.targetPercentage),
                  let qty = Int(detailData.quantity) else {
                return
            }
            
            let stock = Stock(
                id: detailData.id,
                name: name,
                code: detailData.code,
                targetPercentage: target,
                currentPrice: price,
                quantity: qty,
                category: detailData.category,
                dailyVariation: variation
            )
            
            await MainActor.run {
                onSave(stock)
                dismiss()
            }
        }
    }
}

struct StockDetailView_Previews: PreviewProvider {
    static var previews: some View {
        StockDetailView(detailData: StockEditData(stock: nil),
                        onSave: { stock in
                            print("저장된 주식: \(stock)")
                        })
    }
}
