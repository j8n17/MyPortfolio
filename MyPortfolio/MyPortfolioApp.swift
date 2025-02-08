import SwiftUI

@main
struct MyPortfolioApp: App {
    let persistenceController = PersistenceController.shared
    
    init() {
        NotificationManager.shared.requestAuthorization()
        BackgroundTaskManager.shared.registerBackgroundTask()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)) { _ in
                    // 앱이 백그라운드에 들어갈 때 작업 예약
                    BackgroundTaskManager.shared.scheduleAppRefresh()
                }
        }
    }
}
