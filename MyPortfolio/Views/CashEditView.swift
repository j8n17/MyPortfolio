import SwiftUI

struct CashEditView: View {
    /// StockStore의 cash 값과 바인딩 (필요에 따라 EnvironmentObject를 사용할 수도 있음)
    @Binding var cash: Double
    @Environment(\.dismiss) var dismiss
    @State private var editedCash: String = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("현금 수정")) {
                    TextField("현금 입력", text: $editedCash)
                        .keyboardType(.numbersAndPunctuation)
                }
            }
            .navigationTitle("현금 수정")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("저장") {
                        // 입력된 문자열이 정수로 변환 가능한 경우에만 cash를 업데이트
                        if let newCashInt = Int(editedCash) {
                            cash = Double(newCashInt)
                        }
                        dismiss()
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                // 현금 값을 String으로 변환하여 초기값으로 설정 (정수로 보이게 하기 위해 Int로 변환)
                editedCash = String(Int(cash))
            }
        }
    }
}
