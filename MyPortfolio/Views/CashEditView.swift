import SwiftUI

struct CashEditView: View {
    @Binding var cash: Double
    
    var body: some View {
        Form {
            Section(header: Text("현금 보유액 수정")) {
                TextField("현금 보유액", value: $cash, formatter: FormatterHelper.editingCurrency)
                    .keyboardType(.numbersAndPunctuation)
                    .multilineTextAlignment(.trailing)
            }
        }
        .navigationTitle("현금 수정")
    }
}

struct CashEditView_Previews: PreviewProvider {
    static var previews: some View {
        CashEditView(cash: .constant(1000))
    }
}
