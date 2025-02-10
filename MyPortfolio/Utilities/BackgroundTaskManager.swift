import BackgroundTasks

class BackgroundTaskManager {
    static let shared = BackgroundTaskManager()
    private let refreshTaskIdentifier = "com.myportfolio.refresh"
    
    /// 앱 실행 시 백그라운드 작업 등록
    func registerBackgroundTask() {
        print("앱 실행 백그라운드 작업 등록")
        BGTaskScheduler.shared.register(forTaskWithIdentifier: refreshTaskIdentifier, using: nil, launchHandler: { task in
            print("등록된 백그라운드 작업 시작")
            self.handleAppRefresh(task: task as! BGAppRefreshTask)
        })
    }
    
    func nextTime() -> Date? {
        // 현재로부터 최소 3600초 후(1시간 후)부터 실행하도록 설정
        return Date().addingTimeInterval(3600)
    }
    
    func isMarketHours(date: Date) -> Bool {
        let hour = Calendar.current.component(.hour, from: date)
        let weekday = Calendar.current.component(.weekday, from: date)

        // 주식 시장 개장 시간: 09:00 ~ 16:00 (4시)
        let isWithinMarketHours = hour >= 9 && hour < 16
        let isWeekday = weekday != 1 && weekday != 7 // 1: 일요일, 7: 토요일

        return isWeekday && isWithinMarketHours
    }
    
    /// 백그라운드 작업 예약
    func scheduleAppRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: refreshTaskIdentifier)
        request.earliestBeginDate = nextTime()
        do {
            try BGTaskScheduler.shared.submit(request)
            print("백그라운드 작업 예약 성공: \(request.earliestBeginDate!)")
        } catch {
            print("백그라운드 작업 예약 실패: \(error)")
        }
    }
    
    /// 백그라운드 작업 처리
    func handleAppRefresh(task: BGAppRefreshTask) {
        print("백그라운드 작업 시작")
        scheduleAppRefresh() // 다음 작업 예약 (반복)
        
        if !isMarketHours(date: Date()) {
            print("현재 시간은 주식 시장 개장 시간이 아닙니다. 작업을 건너뜁니다.")
            task.setTaskCompleted(success: true)
            return
        }
        
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        
        // Stock 데이터 업데이트 및 알림 예약을 수행하는 커스텀 Operation
        let operation = StockRefreshOperation()
        
        // 작업 만료 시 모든 작업 취소
        task.expirationHandler = {
            queue.cancelAllOperations()
        }
        
        operation.completionBlock = {
            task.setTaskCompleted(success: !operation.isCancelled)
        }
        queue.addOperation(operation)
    }
}
