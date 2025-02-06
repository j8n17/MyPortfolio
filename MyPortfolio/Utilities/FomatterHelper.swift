import Foundation

struct FormatterHelper {
    // 화면에 표시할 때 쉼표가 포함된 형식 (예: 50,000,000)
    static let displayCurrency: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        formatter.usesGroupingSeparator = true
        formatter.groupingSize = 3
        formatter.secondaryGroupingSize = 3
        return formatter
    }()
    
    // 입력 시에는 쉼표 없이 숫자만 보이도록
    static let editingCurrency: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        formatter.usesGroupingSeparator = false
        return formatter
    }()
    
    // 리밸런싱 기준 증감율 입력용 포매터 (정수와 실수 모두 허용)
    static let thresholdFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 0
        return formatter
    }()
}
