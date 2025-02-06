import SwiftUI

struct APIKeySettingsView: View {
    @State private var appKey: String = KeyManager.shared.appKey
    @State private var appSecret: String = KeyManager.shared.appSecret
    @Environment(\.presentationMode) private var presentationMode

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("API Key")) {
                    TextField("App Key", text: $appKey)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)
                    
                    TextField("App Secret", text: $appSecret)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)
                }
            }
            .navigationTitle("API Key")
            .safeAreaInset(edge: .bottom) {
                Button(action: {
                    KeyManager.shared.appKey = appKey
                    KeyManager.shared.appSecret = appSecret
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("저장")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .padding(.horizontal)
                }
            }
        }
    }
}

struct APIKeySettingsView_Previews: PreviewProvider {
    static var previews: some View {
        APIKeySettingsView()
    }
}
