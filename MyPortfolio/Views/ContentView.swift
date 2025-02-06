import SwiftUI

struct ContentView: View {
    @StateObject private var store = StockStore()
    
    // 탭 선택 상태 (0: 포트폴리오, 1: 자산 현황, 2: 설정)
    @State private var selectedTab: Int = 0
    
    // 주식 상세보기(푸시)용: 선택된 주식 데이터를 저장 (포트폴리오 탭에서는 사용하지 않음)
    @State private var selectedDetailData: StockEditData? = nil
    
    // 주식 추가용 데이터 (시트)
    @State private var editingStockData: StockEditData? = nil
    
    // 현금 수정(푸시)용: 더 이상 ContentView에서는 사용하지 않음
    @State private var isEditingCashPush: Bool = false
    
    // API Key 설정 화면을 모달로 표시하기 위한 상태 변수
    @State private var showAPIKeySettings: Bool = false
    
    // 토큰 만료 시각 텍스트 (computed property)
    private var tokenExpirationText: String {
        if let expiration = KeyManager.shared.tokenExpirationDate {
            let formatted = expiration.formatted(date: .abbreviated, time: .shortened)
            return "토큰 만료 시각: \(formatted)"
        } else {
            return "토큰 만료 시각: 없음"
        }
    }
    
    // 현금 퍼센트 계산 (전체 자산이 0보다 클 경우)
    private var cashPercentage: String {
        if store.overallTotal > 0 {
            let percent = store.cash / store.overallTotal * 100
            return String(format: "%.1f%%", percent)
        } else {
            return "0.0%"
        }
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // [포트폴리오 탭]
            NavigationStack {
                Form {
                    // 전체 목표 비율 경고 섹션
                    if abs(store.combinedTarget - 100) > 0.001 {
                        Section {
                            Text("전체 목표 비율 합계가 \(store.combinedTarget, specifier: "%.1f")%입니다.\n100%로 설정해 주세요.")
                                .foregroundColor(.red)
                        }
                    }
                    
                    // 리밸런싱 상태 섹션 (리밸런싱 필요할 때만 표시)
                    if store.overallNeedsRebalancing(threshold: store.threshold) {
                        Section {
                            Text("리밸런싱 필요")
                                .foregroundColor(.red)
                        }
                    }
                    
                    // 주식 목록 섹션 (삭제 기능 제거)
                    let stocksOnly = store.stocks
                        .filter { $0.category == "주식" }
                        .sorted { (s1, s2) in (Int(s1.code) ?? 0) < (Int(s2.code) ?? 0) }
                    Section(header: Text("주식")) {
                        ForEach(stocksOnly) { stock in
                            StockRowView(
                                stock: stock,
                                overallTotal: store.overallTotal,
                                onEdit: { },
                                onDelete: { }  // 빈 클로저로 삭제 버튼 제거
                            )
                        }
                    }
                    
                    // 현금 및 채권 목록 섹션 (삭제 기능 제거)
                    let bondsOnly = store.stocks.filter { $0.category == "현금 및 채권" }
                    Section(header: Text("현금 및 채권")) {
                        ForEach(bondsOnly) { stock in
                            StockRowView(
                                stock: stock,
                                overallTotal: store.overallTotal,
                                onEdit: { },
                                onDelete: { }  // 삭제 버튼 제거
                            )
                        }
                        // 현금 행: 현금을 금액 대신 전체 자산에 대한 퍼센트로 표시
                        HStack {
                            Text("현금")
                            Spacer()
                            Text(cashPercentage)
                                .font(.body)
                                .foregroundColor(.gray)
                        }
                        .contentShape(Rectangle())
                        // ContentView에서는 현금 수정 화면 호출 제거
                        //.onTapGesture { isEditingCashPush = true }
                    }
                    
                    // 리밸런싱 실행 버튼 섹션 (조건 만족 시)
                    if abs(store.combinedTarget - 100) <= 0.001 &&
                        store.overallNeedsRebalancing(threshold: store.threshold) {
                        Section {
                            Button("리밸런싱 실행") {
                                for index in store.stocks.indices {
                                    let stock = store.stocks[index]
                                    if stock.targetPercentage == 0 {
                                        store.stocks[index].quantity = 0
                                    } else {
                                        let desiredValue = store.overallTotal * (stock.targetPercentage / 100)
                                        if stock.currentPrice > 0 {
                                            store.stocks[index].quantity = Int((desiredValue / Double(stock.currentPrice)).rounded())
                                        } else {
                                            store.stocks[index].quantity = 0
                                        }
                                    }
                                }
                                store.save()
                            }
                        }
                    }
                } // Form
                .refreshable { await updateStockPrices() }
                .navigationTitle("포트폴리오")
                // 주식 상세보기(푸시) 화면 제거 (포트폴리오 탭에서는 상세 화면이 나타나지 않음)
            }
            .tabItem {
                Label("포트폴리오", systemImage: "chart.bar")
            }
            .tag(0)
            
            // [자산 현황 탭]
            AssetStatusView(editingStockData: $editingStockData)
                .environmentObject(store)
                .tabItem {
                    Label("자산 현황", systemImage: "dollarsign.circle")
                }
                .tag(1)
            
            // [설정 탭]
            NavigationView {
                Form {
                    Section(header: Text("설정")) {
                        HStack {
                            Text("리밸런싱 기준 증감율")
                            TextField("예: 8.0",
                                      value: $store.threshold,
                                      formatter: FormatterHelper.thresholdFormatter)
                                .keyboardType(.numbersAndPunctuation)
                                .multilineTextAlignment(.trailing)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Button("API Key") {
                                showAPIKeySettings = true
                            }
                            .foregroundColor(.blue)
                            
                            Text(tokenExpirationText)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Button("데이터 초기화") {
                            store.resetData()
                            selectedTab = 0
                        }
                        .foregroundColor(.red)
                    }
                }
                .navigationTitle("설정")
            }
            .tabItem {
                Label("설정", systemImage: "gear")
            }
            .tag(2)
        } // TabView
        // 주식 추가 화면 (시트)
        .sheet(isPresented: Binding<Bool>(
            get: { editingStockData != nil && (editingStockData?.name.isEmpty ?? true) },
            set: { if !$0 { editingStockData = nil } }
        )) {
            if let addData = editingStockData {
                StockAddView(
                    addData: addData,
                    onCancel: { editingStockData = nil },
                    onSave: { newStock in
                        store.stocks.append(newStock)
                        store.save()
                        editingStockData = nil
                    }
                )
            }
        }
        // API Key 설정 화면 (시트)
        .sheet(isPresented: $showAPIKeySettings) {
            NavigationStack {
                APIKeySettingsView()
            }
        }
    }
    
    // 삭제 함수 (포트폴리오 탭에서는 사용하지 않음)
    private func deleteStock(_ stock: Stock) {
        store.stocks.removeAll { $0.id == stock.id }
        store.save()
    }
    
    // 주식의 현재가, 전일 대비 변동률, 주식 이름(상품명) 업데이트 함수
    private func updateStockPrices() async {
        for i in store.stocks.indices {
            let code = store.stocks[i].code
            
            async let priceResult = StockPriceFetcher.fetchCurrentPrice(for: code)
            async let fetchedName = StockPriceFetcher.fetchStockName(for: code)
            
            let (result, name) = await (priceResult, fetchedName)
            
            if result.price > 0 {
                store.stocks[i].currentPrice = result.price
                store.stocks[i].dailyVariation = result.variation
            }
            store.stocks[i].name = name
        }
        store.save()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
