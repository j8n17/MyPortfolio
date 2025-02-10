import SwiftUI

struct AssetStatusView: View {
    @EnvironmentObject var store: StockStore
    /// ContentView에서 전달받은 주식 추가용 데이터 (시트용)
    @Binding var editingStockData: StockEditData?
    /// 탭 제스처로 선택한 주식 상세 데이터를 저장 (모달 시트 전환용)
    @State private var selectedDetailData: StockEditData? = nil
    /// 현금 수정 시트를 표시하기 위한 상태 변수
    @State private var showCashEdit: Bool = false
    /// 수량 전체 수정 모드 여부
    @State private var isEditingQuantity: Bool = false
    /// 편집 중인 수량을 임시로 저장 (stock.id를 key로 사용)
    @State private var editedQuantities: [UUID: String] = [:]
    /// 포커스 관리: 현재 포커스가 가야하는 주식의 id (수량 수정란)
    @FocusState private var focusedStock: UUID?
    
    var body: some View {
        NavigationStack {
            ZStack {
                Form {
                    // 상단에 총 자산 정보를 중앙 정렬하여 표시
                    HStack {
                        Spacer()
                        VStack(spacing: 4) {
                            Text("총 자산")
                                .font(.caption)
                                .foregroundColor(.gray)
                            Text("\(store.totalAssets, specifier: "%.0f")원")
                                .font(.title2)
                                .fontWeight(.bold)
                        }
                        Spacer()
                    }
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    
                    // [주식 섹션]
                    Section(header: Text("주식")) {
                        // 주식 섹션은 주식 코드 오름차순으로 정렬
                        let sortedStocks = store.stocks.filter { $0.category == "주식" }
                            .sorted { (s1, s2) in (Int(s1.code) ?? 0) < (Int(s2.code) ?? 0) }
                        
                        ForEach(sortedStocks) { stock in
                            assetRowView(for: stock)
                                .onTapGesture {
                                    if !isEditingQuantity {
                                        selectedDetailData = StockEditData(stock: stock)
                                    }
                                }
                                .swipeActions(edge: .trailing) {
                                    Button(role: .destructive) {
                                        if let index = store.stocks.firstIndex(where: { $0.id == stock.id }) {
                                            store.stocks.remove(at: index)
                                            store.save()
                                        }
                                    } label: {
                                        Label("삭제", systemImage: "trash")
                                    }
                                }
                        }
                    }
                    
                    // [채권 섹션]
                    Section(header: Text("채권")) {
                        ForEach(store.stocks.filter { $0.category == "현금 및 채권" }
                                    .sorted { (s1, s2) in (Int(s1.code) ?? 0) < (Int(s2.code) ?? 0) }
                        ) { asset in
                            assetRowView(for: asset)
                                .onTapGesture {
                                    if !isEditingQuantity {
                                        selectedDetailData = StockEditData(stock: asset)
                                    }
                                }
                                .swipeActions(edge: .trailing) {
                                    Button(role: .destructive) {
                                        if let index = store.stocks.firstIndex(where: { $0.id == asset.id }) {
                                            store.stocks.remove(at: index)
                                            store.save()
                                        }
                                    } label: {
                                        Label("삭제", systemImage: "trash")
                                    }
                                }
                        }
                        
                        // 현금 행 (현금은 삭제 대상이 아니므로 swipeActions 없이 표시)
                        HStack(alignment: .bottom) {
                            Text("현금")
                                .font(.body)
                            Spacer()
                            Text("\(FormatterHelper.displayCurrency.string(from: NSNumber(value: store.cash)) ?? "\(store.cash)")원")
                                .font(.body)
                                .foregroundColor(.gray)
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            showCashEdit = true
                        }
                    }
                } // Form 끝
                
                // 떠 있는 + 버튼 (새 주식 추가용)
                Button(action: {
                    editingStockData = StockEditData(stock: nil)
                }) {
                    Image(systemName: "plus")
                        .font(.title)
                        .foregroundColor(.white)
                        .frame(width: 60, height: 60)
                        .background(Color.blue)
                        .clipShape(Circle())
                        .shadow(radius: 4)
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
            } // ZStack 끝
            .navigationTitle("자산 현황")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if isEditingQuantity {
                        Button("완료") {
                            // 입력한 수량을 저장
                            for index in store.stocks.indices {
                                let stock = store.stocks[index]
                                if let newQuantityString = editedQuantities[stock.id],
                                   let newQuantity = Int(newQuantityString) {
                                    store.stocks[index].quantity = newQuantity
                                }
                            }
                            store.save()
                            // 편집 모드 종료 및 임시 데이터 초기화
                            isEditingQuantity = false
                            editedQuantities = [:]
                            focusedStock = nil
                        }
                    } else {
                        Menu {
                            Button("수량 전체 수정") {
                                // 각 주식의 현재 수량을 임시 저장 후 편집 모드 활성화
                                for stock in store.stocks {
                                    editedQuantities[stock.id] = "\(stock.quantity)"
                                }
                                isEditingQuantity = true
                                
                                // 주식 섹션에서 주식 코드 기준 오름차순 정렬 후 첫 번째 주식에 포커스 부여
                                let sortedStocks = store.stocks.filter { $0.category == "주식" }
                                    .sorted { (s1, s2) in (Int(s1.code) ?? 0) < (Int(s2.code) ?? 0) }
                                if let firstStock = sortedStocks.first {
                                    focusedStock = firstStock.id
                                }
                            }
                        } label: {
                            Image(systemName: "ellipsis")
                                .imageScale(.large)
                        }
                    }
                }
            }
            // 주식 상세 데이터 모달 시트 (편집 모드가 아닐 때)
            .sheet(item: $selectedDetailData) { detail in
                StockDetailView(
                    detailData: detail,
                    onSave: { updatedStock in
                        if let index = store.stocks.firstIndex(where: { $0.id == updatedStock.id }) {
                            store.stocks[index] = updatedStock
                        }
                        store.save()
                    }
                )
            }
            // 현금 수정 시트를 위한 모달 시트
            .sheet(isPresented: $showCashEdit) {
                CashEditView(cash: $store.cash)
            }
            // 주식 추가 시트
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
        } // NavigationStack 끝
    }
    
    /// 주식/채권 행을 구성하는 뷰 (좌측: 이름, 코드, 현재가(전일대비); 우측: 보유 수량, 평가 금액)
    @ViewBuilder
    private func assetRowView(for stock: Stock) -> some View {
        HStack(alignment: .bottom) {
            // 왼쪽 정보 영역
            VStack(alignment: .leading, spacing: 4) {
                Text(stock.name)
                    .font(.body)
                    .lineLimit(1)
                    .truncationMode(.tail)
                Text("\(stock.code)")
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
            // 오른쪽 정보 영역
            VStack(alignment: .trailing, spacing: 2) {
                if isEditingQuantity {
                    HStack(spacing: 2) {
                        TextField("", text: Binding(
                            get: { editedQuantities[stock.id] ?? "\(stock.quantity)" },
                            set: { editedQuantities[stock.id] = $0 }
                        ))
                        .keyboardType(.numbersAndPunctuation)
                        .frame(width: 50)
                        .focused($focusedStock, equals: stock.id)
                        Text("주")
                    }
                } else {
                    Text("\(stock.quantity)주")
                        .font(.body)
                }
                Text("\(FormatterHelper.displayCurrency.string(from: NSNumber(value: stock.currentValue)) ?? "\(stock.currentValue)")원")
                    .font(.body)
                    .foregroundColor(.gray)
            }
        }
    }
}

struct AssetStatusView_Previews: PreviewProvider {
    static var previews: some View {
        AssetStatusView(editingStockData: .constant(nil))
            .environmentObject(StockStore())
    }
}
