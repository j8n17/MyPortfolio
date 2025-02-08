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
    
//    func next10AM() -> Date? {
//        let calendar = Calendar.current
//        let now = Date()
//        
//        // 오늘 오전 10시 날짜를 구함
//        var nextDate = calendar.date(bySettingHour: 2, minute: 37, second: 0, of: now)!
//        
//        // 만약 오늘 오전 10시가 이미 지났다면, 내일 오전 10시로 설정
//        if nextDate < now {
//            nextDate = calendar.date(byAdding: .day, value: 1, to: nextDate)!
//        }
//        
//        return nextDate
//    }
    func next10AM() -> Date? {
        // 테스트용: 현재로부터 60초 후에 실행하도록 설정
        return Date().addingTimeInterval(1800)
    }
    
    func isWeekday(date: Date) -> Bool {
        let weekday = Calendar.current.component(.weekday, from: date)
        // 1: 일요일, 7: 토요일
        return weekday != 1 && weekday != 7
    }
    
    /// 백그라운드 작업 예약
    func scheduleAppRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: refreshTaskIdentifier)
        request.earliestBeginDate = next10AM()
        do {
            try BGTaskScheduler.shared.submit(request)
            print("백그라운드 작업 예약 성공: \(request.earliestBeginDate!)")
        } catch {
            print("백그라운드 작업 예약 실패: \(error)")
        }
    }
    
    /// 백그라운드 작업 처리 – 작업이 시작되면 주식 데이터 업데이트 후 조건에 따라 알림 예약
    func handleAppRefresh(task: BGAppRefreshTask) {
        print("백그라운드 작업 시작")
        // 다음 작업 예약 (반복)
        scheduleAppRefresh()
        
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        
        // Stock 데이터 업데이트와 알림 예약을 수행하는 커스텀 Operation
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
