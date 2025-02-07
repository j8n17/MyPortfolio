import SwiftUI

struct StockDetailView: View {
    @Environment(\.dismiss) var dismiss
    @State var detailData: StockEditData
    var onSave: (Stock) -> Void

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("주식 정보")) {
                    // 항상 편집 가능한 Picker
                    Picker("종목 유형", selection: $detailData.category) {
                        Text("주식").tag("주식")
                        Text("현금 및 채권").tag("현금 및 채권")
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    
                    // 종목 코드 입력
                    HStack {
                        Text("종목 코드")
                        TextField("예: 278530", text: $detailData.code)
                            .keyboardType(.numbersAndPunctuation)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    // 목표 비율 입력
                    HStack {
                        Text("목표 비율")
                        TextField("예: 20.0", text: $detailData.targetPercentage)
                            .keyboardType(.numbersAndPunctuation)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    // 보유 수량 입력
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
                leading: Button("취소") {
                    dismiss()
                },
                trailing: Button("저장") {
                    saveStock()
                }
            )
        }
    }
    
    /// 저장 버튼 클릭 시 호출
    private func saveStock() {
        Task {
            // 입력된 종목 코드를 통해 현재가 및 전일 대비 변동률, 그리고 주식 이름을 조회합니다.
            let (price, variation) = await StockPriceFetcher.fetchCurrentPrice(for: detailData.code)
            let name = await StockPriceFetcher.fetchStockName(for: detailData.code)
            
            // 목표 비율과 보유 수량의 문자열을 적절한 타입으로 변환합니다.
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
            
            // 메인 스레드에서 onSave 실행 후 화면을 닫습니다.
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
