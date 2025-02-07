import SwiftUI

@main
struct MyPortfolioApp: App {
    let persistenceController = PersistenceController.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView() // 기존 ContentView (또는 탭별 뷰들)
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
