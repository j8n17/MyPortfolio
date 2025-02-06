import SwiftUI

struct AssetStatusView: View {
    @EnvironmentObject var store: StockStore
    // ContentView에서 전달받은 주식 추가용 데이터 (시트용)
    @Binding var editingStockData: StockEditData?
    // tap gesture를 통해 선택된 주식 상세 데이터를 저장 (모달 시트 전환용)
    @State private var selectedDetailData: StockEditData? = nil
    
    var body: some View {
        NavigationStack {
            Form {
                // 상단에 총 자산 정보를 중앙 정렬하여 자연스럽게 배치
                HStack {
                    Spacer()
                    VStack(spacing: 4) {
                        Text("총 자산")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text("\(store.overallTotal, specifier: "%.0f")원")
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                    Spacer()
                }
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
                
                // [주식 섹션]
                Section(header: Text("주식")) {
                    ForEach(store.stocks.filter { $0.category == "주식" }) { stock in
                        assetRowView(for: stock)
                            .onTapGesture {
                                selectedDetailData = StockEditData(stock: stock)
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
                    ForEach(store.stocks.filter { $0.category == "현금 및 채권" }) { asset in
                        assetRowView(for: asset)
                            .onTapGesture {
                                selectedDetailData = StockEditData(stock: asset)
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
                    
                    // 현금 행: 현금은 삭제할 대상이 아니므로 swipeActions 없이 표시
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
                        // 예시: 현금 수정 화면으로 전환하고 싶다면 별도 상태 변수를 사용
                        // 여기서는 상세 화면 전환 없이 아무 동작도 하지 않음.
                    }
                }
            } // Form
            .navigationTitle("자산 현황")
            .toolbar {
                // 자산 현황 탭에 새 주식 추가를 위한 + 버튼
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        editingStockData = StockEditData(stock: nil)
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            // selectedDetailData가 설정되면 모달 시트로 StockDetailView를 표시 (아래에서 위로 등장)
            .sheet(item: $selectedDetailData) { detail in
                // StockDetailView를 NavigationView로 감싸서 상단 네비게이션 바가 보이도록 함
                NavigationView {
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
            }
        }
    }
    
    /// 주식/채권 행을 구성하는 뷰 (좌측: 이름, 코드, 현재가(전일대비); 우측: 보유 수량, 평가 금액)
    @ViewBuilder
    private func assetRowView(for stock: Stock) -> some View {
        // 전일 대비 변동률 색상 결정
        let variationColor: Color = stock.dailyVariation > 0 ? .red : (stock.dailyVariation < 0 ? .blue : .gray)
        
        HStack(alignment: .bottom) {
            // 왼쪽 영역
            VStack(alignment: .leading, spacing: 4) {
                Text(stock.name)
                    .font(.body)
                // 종목 코드는 단순 코드만 표시
                Text("\(stock.code)")
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
            // 오른쪽 영역
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(stock.quantity)주")
                    .font(.body)
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
