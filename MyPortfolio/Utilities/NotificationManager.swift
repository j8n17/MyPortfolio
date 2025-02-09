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
}

extension NotificationManager {
    /// StockStore의 데이터를 확인하여 리밸런싱 필요 시, 모든 주식 중에서
    /// needsRebalancing에서 사용하는 changeFraction (즉, (currentFraction - targetFraction) / targetFraction)을
    /// 계산한 후 절대값이 가장 큰 값을 백분율(%)로 변환하여 알림 메시지에 포함합니다.
    func scheduleNotificationIfNeeded(stockStore: StockStore) {
        if stockStore.overallNeedsRebalancing(threshold: stockStore.threshold) {
            let overallTotal = stockStore.overallTotal
            let changeFractions: [Double] = stockStore.stocks.compactMap { stock in
                let targetFraction = stock.targetPercentage / 100.0
                guard targetFraction != 0, overallTotal > 0 else { return nil }
                let currentFraction = stock.currentValue / overallTotal
                let changeFraction = (currentFraction - targetFraction) / targetFraction
                return abs(changeFraction) * 100  // 백분율 값으로 변환
            }
            let maxChange = changeFractions.max() ?? 0.0
            scheduleRebalancingNotification(maxChange: maxChange)
        } else {
            print("리밸런싱 조건 미충족: 알림 미예약")
        }
    }
}
