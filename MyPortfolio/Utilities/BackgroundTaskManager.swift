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
    
    func next10AM() -> Date? {
        // 테스트용: 현재로부터 1800초 후(30분 후)에 실행하도록 설정
        return Date().addingTimeInterval(180)
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
    
    /// 백그라운드 작업 처리
    func handleAppRefresh(task: BGAppRefreshTask) {
        print("백그라운드 작업 시작")
        
        // 현재 시간 확인: 시(hour)가 0시 이상 9시 미만이면 작업을 건너뜁니다.
        let hour = Calendar.current.component(.hour, from: Date())
        if hour >= 16 && hour < 9 {
            print("현재 시간이 \(hour)시로, 밤 12시부터 오전 9시 사이입니다. 작업을 건너뜁니다.")
            scheduleAppRefresh()  // 다음 작업 예약
            task.setTaskCompleted(success: true)
            return
        }
        
        // 다음 작업 예약 (반복)
        scheduleAppRefresh()
        
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
