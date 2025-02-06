import SwiftUI

struct StockAddView: View {
    @State var addData: StockEditData  // 기존 StockEditData를 재사용 (추가용으로 id 등은 nil 혹은 새 값)
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
        // 저장 버튼 클릭 시 비동기로 API 호출 후 Stock 객체를 생성하여 onSave 호출
        Task {
            // 입력된 종목 코드를 이용해 현재가 및 전일 대비 변동률 조회
            let (price, variation) = await StockPriceFetcher.fetchCurrentPrice(for: addData.code)
            // 입력된 종목 코드를 이용해 주식 이름(상품명) 조회
            let name = await StockPriceFetcher.fetchStockName(for: addData.code)
            
            // 목표 비율과 보유 수량은 텍스트필드 입력값을 변환
            guard let target = Double(addData.targetPercentage),
                  let qty = Int(addData.quantity) else {
                // 변환 실패 시 에러처리 (예: Alert 등) – 여기서는 단순 return 처리
                return
            }
            
            let stock = Stock(
                id: addData.id, // 추가 시에는 새로운 id를 부여하거나 nil일 수 있음
                name: name,
                code: addData.code,
                targetPercentage: target,
                currentPrice: price,
                quantity: qty,
                category: addData.category,
                dailyVariation: variation
            )
            
            // 메인 스레드에서 onSave 호출
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
