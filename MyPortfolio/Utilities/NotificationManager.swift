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
    
    /// 최대 변동율(maxChange)을 포함하여 리밸런싱 필요 알림 예약 (예시로 5초 후 발송)
    func scheduleRebalancingNotification(maxChange: Double) {
        let content = UNMutableNotificationContent()
        
        content.title = "리밸런싱 필요 알림"
        content.body = "일부 주식의 변동율이 기준을 초과했습니다. 현재 증감율이 \(String(format: "%.1f", maxChange))% 입니다. 리밸런싱을 고려하세요."
        content.sound = .default
        
        // 테스트용: 5초 후에 알림 발송
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

    /// 전체 목표 비율 오류 알림 예약 (예시로 5초 후 발송)
    func scheduleCombinedTargetNotification(combinedTarget: Double) {
        let content = UNMutableNotificationContent()
        
        content.title = "목표 비율 설정 오류"
        content.body = "전체 목표 비율 합계가 \(String(format: "%.1f", combinedTarget))%입니다.\n100%로 설정해 주세요."
        content.sound = .default
        
        // 테스트용: 5초 후에 알림 발송
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

    /// StockStore의 데이터를 확인하여 조건에 따라 알림 예약을 수행합니다.
    func scheduleNotificationIfNeeded(stockStore: StockStore) {
        // 전체 목표 비율의 합계가 100%가 아닌 경우 우선 알림을 실행합니다.
        if abs(stockStore.combinedTarget - 100) > 0.001 {
            scheduleCombinedTargetNotification(combinedTarget: stockStore.combinedTarget)
            return
        }
        
        // 리밸런싱이 필요한 경우 알림을 실행합니다.
        let maxChange = stockStore.maxChange
        if stockStore.needRebalance {
            scheduleRebalancingNotification(maxChange: maxChange)
        } else {
            print("리밸런싱 조건 미충족: maxChange(\(maxChange))가 threshold(\(stockStore.threshold)) 미만입니다.")
        }
    }

}
