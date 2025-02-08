import UserNotifications

class NotificationManager {
    static let shared = NotificationManager()
    
    /// 알림 권한 요청
    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("알림 권한 요청 오류: \(error.localizedDescription)")
            } else {
                print("알림 권한 요청 결과: \(granted)")
            }
        }
    }
    
    /// 조건에 따라 로컬 알림을 예약하는 함수 (현재는 예시로 5초 후에 알림)
    func scheduleRebalancingNotification() {
        let content = UNMutableNotificationContent()
        content.title = "리밸런싱 필요 알림"
        content.body = "일부 주식의 변동율이 기준을 초과했습니다. 리밸런싱을 고려하세요."
        content.sound = .default
        
        // 테스트용으로 5초 후에 발송하도록 함 (추후 백그라운드 작업에서 예약하도록 수정)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString,
                                            content: content,
                                            trigger: trigger)
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("알림 예약 오류: \(error)")
            }
        }
    }
}

extension NotificationManager {
    /// StockStore의 데이터를 확인하여 리밸런싱이 필요하면 알림을 예약한다.
    func scheduleNotificationIfNeeded(stockStore: StockStore) {
        if stockStore.overallNeedsRebalancing(threshold: stockStore.threshold) {
            scheduleRebalancingNotification()
        } else {
            print("리밸런싱 조건 미충족: 알림 미예약")
        }
    }
}

