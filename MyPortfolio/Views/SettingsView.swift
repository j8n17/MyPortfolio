import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var store: StockStore
    /// 탭 선택 상태에 대한 Binding (데이터 초기화 후 포트폴리오 탭(인덱스 0)으로 전환)
    @Binding var selectedTab: Int
    @State private var showAPIKeySettings: Bool = false
    
    private var tokenExpirationText: String {
        if let expiration = KeyManager.shared.tokenExpirationDate {
            let formatted = expiration.formatted(date: .abbreviated, time: .shortened)
            return "토큰 만료 시각: \(formatted)"
        } else {
            return "토큰 만료 시각: 없음"
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("설정")) {
                    HStack {
                        Text("리밸런싱 기준 증감율")
                        TextField("예: 12.0",
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
                }
                
                // 데이터 초기화 섹션
                Section {
                    Button("데이터 초기화") {
                        store.resetData()
                        // 데이터 초기화 후 포트폴리오 탭(인덱스 0)으로 전환
                        selectedTab = 0
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("설정")
            .sheet(isPresented: $showAPIKeySettings) {
                NavigationStack {
                    APIKeySettingsView()
                }
            }
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        // 프리뷰에서는 임의의 탭 선택 Binding을 사용합니다.
        SettingsView(selectedTab: .constant(2))
            .environmentObject(StockStore())
    }
}
