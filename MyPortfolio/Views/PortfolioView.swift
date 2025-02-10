import SwiftUI

struct PortfolioView: View {
    @EnvironmentObject var store: StockStore
    
    @State private var isSelectingStocks: Bool = false
    @State private var selectedStockIDs: Set<Stock.ID> = []
    @State private var showRebalancingWarning: Bool = false
    
    // 주식만 필터링하여 정렬
    private var stocksOnly: [Stock] {
        store.stocks.filter { $0.category == "주식" }
            .sorted { (s1, s2) in (Int(s1.code) ?? 0) < (Int(s2.code) ?? 0) }
    }
    
    // 현금 및 채권만 필터링하여 정렬
    private var bondsOnly: [Stock] {
        store.stocks.filter { $0.category == "현금 및 채권" }
            .sorted { (s1, s2) in (Int(s1.code) ?? 0) < (Int(s2.code) ?? 0) }
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
                if store.needRebalance {
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
                                    overallTotal: store.totalAssets,
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
                                overallTotal: store.totalAssets,
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
                                    overallTotal: store.totalAssets,
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
                                overallTotal: store.totalAssets,
                                onEdit: { },
                                onDelete: { }
                            )
                        }
                    }
                    // 현금 행: StockStore의 cashPercentage 사용 (숫자 값을 포맷팅하여 표시)
                    HStack {
                        Text("현금")
                        Spacer()
                        Text(String(format: "%.1f%%", store.cashPercentage))
                            .font(.body)
                            .foregroundColor(.gray)
                    }
                    .contentShape(Rectangle())
                }
            }
            .refreshable { await store.updateStockPrices() }
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
            // 선택 모드일 때 하단 오버레이: 삭제 및 리밸런싱 버튼
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
                                    store.rebalanceStocks(selectedIDs: selectedStockIDs)
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
    }
}

struct PortfolioView_Previews: PreviewProvider {
    static var previews: some View {
        PortfolioView()
            .environmentObject(StockStore())
    }
}
