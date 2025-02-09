import SwiftUI

struct StockAddView: View {
    @State var addData: StockEditData  // 기존 StockEditData를 재사용
    var onCancel: () -> Void
    var onSave: (Stock) -> Void
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("새 주식 정보 입력")) {
                    Picker("종목 유형", selection: $addData.category) {
                        Text("주식").tag("주식")
                        Text("현금 및 채권").tag("현금 및 채권")
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    
                    HStack {
                        Text("종목 코드")
                        TextField("예: 278530", text: $addData.code)
                            .keyboardType(.numbersAndPunctuation)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    HStack {
                        Text("목표 비율")
                        TextField("예: 20.0", text: $addData.targetPercentage)
                            .keyboardType(.numbersAndPunctuation)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    HStack {
                        Text("보유 수량")
                        TextField("예: 10", text: $addData.quantity)
                            .keyboardType(.numbersAndPunctuation)
                            .multilineTextAlignment(.trailing)
                    }
                }
            }
            .navigationTitle("주식 추가")
            .navigationBarItems(
                leading: Button("취소") { onCancel() },
                trailing: Button("저장") { saveStock() }
            )
        }
    }
    
    private func saveStock() {
        Task {
            // API 키를 미리 받아서 재사용
            let keys = await getKey()
            let (price, variation) = await StockPriceFetcher.fetchCurrentPrice(for: addData.code, using: keys)
            let name = await StockPriceFetcher.fetchStockName(for: addData.code, using: keys)
            
            guard let target = Double(addData.targetPercentage),
                  let qty = Int(addData.quantity) else {
                return
            }
            
            let stock = Stock(
                id: addData.id,
                name: name,
                code: addData.code,
                targetPercentage: target,
                currentPrice: price,
                quantity: qty,
                category: addData.category,
                dailyVariation: variation
            )
            
            await MainActor.run {
                onSave(stock)
            }
        }
    }
}

struct StockAddView_Previews: PreviewProvider {
    static var previews: some View {
        StockAddView(addData: StockEditData(stock: nil),
                     onCancel: {},
                     onSave: { stock in
                         print("저장된 주식: \(stock)")
                     })
    }
}
