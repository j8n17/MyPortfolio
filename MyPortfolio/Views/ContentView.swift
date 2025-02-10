import SwiftUI

struct ContentView: View {
    @StateObject private var store = StockStore()  // 내부에서 Core Data의 context를 사용
    @State private var selectedTab: Int = 0
    @State private var editingStockData: StockEditData? = nil
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // PortfolioView는 더 이상 주식 추가용 editingStockData를 사용하지 않습니다.
            PortfolioView()
                .environmentObject(store)
                .tag(0)
                .tabItem {
                    Label("포트폴리오", systemImage: "chart.bar")
                }
            
            // AssetStatusView는 주식 추가를 위해 editingStockData 바인딩을 사용합니다.
            AssetStatusView(editingStockData: $editingStockData)
                .environmentObject(store)
                .tag(1)
                .tabItem {
                    Label("자산 현황", systemImage: "dollarsign.circle")
                }
            
            SettingsView(selectedTab: $selectedTab)
                .environmentObject(store)
                .tag(2)
                .tabItem {
                    Label("설정", systemImage: "gear")
                }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        // 미리보기에서는 inMemory 옵션 사용을 권장합니다.
        let persistenceController = PersistenceController.shared
        ContentView()
            .environment(\.managedObjectContext, persistenceController.container.viewContext)
    }
}
