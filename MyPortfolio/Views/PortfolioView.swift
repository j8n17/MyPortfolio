import SwiftUI

struct PortfolioView: View {
    @EnvironmentObject var store: StockStore
    /// 주식 추가용 데이터(새 주식 등록 시 사용)를 부모로부터 Binding으로 전달받음
    @Binding var editingStockData: StockEditData?
    
    @State private var isSelectingStocks: Bool = false
    @State private var selectedStockIDs: Set<Stock.ID> = []
    @State private var showRebalancingWarning: Bool = false
    
    // MARK: - Computed Properties
    
    private var cashPercentage: String {
        if store.overallTotal > 0 {
            let percent = store.cash / store.overallTotal * 100
            return String(format: "%.1f%%", percent)
        } else {
            return "0.0%"
        }
    }
    
    private var stocksOnly: [Stock] {
        store.stocks.filter { $0.category == "주식" }
            .sorted { (s1, s2) in (Int(s1.code) ?? 0) < (Int(s2.code) ?? 0) }
    }
    
    private var bondsOnly: [Stock] {
        store.stocks.filter { $0.category == "현금 및 채권" }
            .sorted { (s1, s2) in (Int(s1.code) ?? 0) < (Int(s2.code) ?? 0) }
    }
    
    /// 각 주식의 현재가, 변동률, 주식 이름을 비동기적으로 업데이트하는 함수
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
    
    var body: some View {
        NavigationStack {
            Form {
                // 전체 목표 비율 경고 섹션
                if abs(store.combinedTarget - 100) > 0.001 {
                    Section {
                        Text("전체 목표 비율 합계가 \(store.combinedTarget, specifier: "%.1f")%입니다.\n100%로 설정해 주세요.")
                            .foregroundColor(.red)
                    }
                }
                // 현금 음수 경고 섹션
                if store.cash < 0 {
                    Section {
                        Text("현금 잔액이 음수입니다.")
                            .foregroundColor(.red)
                    }
                }
                // 리밸런싱 필요 경고 섹션
                if store.overallNeedsRebalancing(threshold: store.threshold) {
                    Section {
                        Text("리밸런싱 필요")
                            .foregroundColor(.red)
                    }
                }
                
                // [주식 목록 섹션]
                Section(header: Text("주식")) {
                    ForEach(stocksOnly) { stock in
                        if isSelectingStocks {
                            HStack {
                                Image(systemName: selectedStockIDs.contains(stock.id) ? "checkmark.circle.fill" : "circle")
                                    .font(.system(size: 20))
                                    .foregroundColor(selectedStockIDs.contains(stock.id) ? .blue : .gray)
                                StockRowView(
                                    stock: stock,
                                    overallTotal: store.overallTotal,
                                    onEdit: { },
                                    onDelete: { }
                                )
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                if selectedStockIDs.contains(stock.id) {
                                    selectedStockIDs.remove(stock.id)
                                } else {
                                    selectedStockIDs.insert(stock.id)
                                }
                            }
                        } else {
                            StockRowView(
                                stock: stock,
                                overallTotal: store.overallTotal,
                                onEdit: { },
                                onDelete: { }
                            )
                        }
                    }
                }
                
                // [현금 및 채권 목록 섹션]
                Section(header: Text("현금 및 채권")) {
                    ForEach(bondsOnly) { stock in
                        if isSelectingStocks {
                            HStack {
                                Image(systemName: selectedStockIDs.contains(stock.id) ? "checkmark.circle.fill" : "circle")
                                    .font(.system(size: 20))
                                    .foregroundColor(selectedStockIDs.contains(stock.id) ? .blue : .gray)
                                StockRowView(
                                    stock: stock,
                                    overallTotal: store.overallTotal,
                                    onEdit: { },
                                    onDelete: { }
                                )
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                if selectedStockIDs.contains(stock.id) {
                                    selectedStockIDs.remove(stock.id)
                                } else {
                                    selectedStockIDs.insert(stock.id)
                                }
                            }
                        } else {
                            StockRowView(
                                stock: stock,
                                overallTotal: store.overallTotal,
                                onEdit: { },
                                onDelete: { }
                            )
                        }
                    }
                    // 현금 행
                    HStack {
                        Text("현금")
                        Spacer()
                        Text(cashPercentage)
                            .font(.body)
                            .foregroundColor(.gray)
                    }
                    .contentShape(Rectangle())
                }
            }
            .refreshable { await updateStockPrices() }
            .navigationTitle("포트폴리오")
            .toolbar {
                if isSelectingStocks {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("완료") {
                            isSelectingStocks = false
                            selectedStockIDs.removeAll()
                        }
                    }
                } else {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Menu {
                            Button("주식 선택") {
                                if store.cash < 0 || abs(store.combinedTarget - 100) > 0.001 {
                                    showRebalancingWarning = true
                                } else {
                                    isSelectingStocks.toggle()
                                }
                            }
                        } label: {
                            Image(systemName: "ellipsis")
                        }
                    }
                }
            }
            // 선택 모드일 때 하단에 오버레이로 삭제 및 리밸런싱 버튼 표시
            .overlay(
                Group {
                    if isSelectingStocks {
                        VStack {
                            Spacer()
                            HStack {
                                Button("삭제") {
                                    store.stocks.removeAll { selectedStockIDs.contains($0.id) }
                                    store.save()
                                    isSelectingStocks = false
                                    selectedStockIDs.removeAll()
                                }
                                .foregroundColor(.red)
                                .padding()
                                
                                Spacer()
                                
                                Button("리밸런싱") {
                                    let overallTotal = store.overallTotal
                                    for index in store.stocks.indices {
                                        if selectedStockIDs.contains(store.stocks[index].id) {
                                            let stock = store.stocks[index]
                                            if stock.targetPercentage == 0 {
                                                store.stocks[index].quantity = 0
                                            } else {
                                                if stock.currentPrice > 0 {
                                                    store.stocks[index].quantity = Int((overallTotal * (stock.targetPercentage / 100) / Double(stock.currentPrice)).rounded())
                                                } else {
                                                    store.stocks[index].quantity = 0
                                                }
                                            }
                                        }
                                    }
                                    let totalStockValue = store.stocks.map { $0.currentValue }.reduce(0, +)
                                    store.cash = overallTotal - totalStockValue
                                    store.save()
                                    isSelectingStocks = false
                                    selectedStockIDs.removeAll()
                                }
                                .foregroundColor(.blue)
                                .padding()
                            }
                            .frame(maxWidth: .infinity)
                            .background(Color(UIColor.systemBackground))
                        }
                        .transition(.move(edge: .bottom))
                    }
                }
            )
            .alert("경고", isPresented: $showRebalancingWarning) {
                Button("확인", role: .cancel) { }
            } message: {
                Text("현금 잔액이 음수이거나 목표 비율 합계가 100%가 아닙니다.")
            }
        }
        // 주식 추가 시트 (StockAddView)
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
    }
}

struct PortfolioView_Previews: PreviewProvider {
    static var previews: some View {
        PortfolioView(editingStockData: .constant(nil))
            .environmentObject(StockStore())
    }
}
