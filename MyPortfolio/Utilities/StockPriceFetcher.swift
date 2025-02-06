import Foundation

// MARK: - 현재가 조회 관련 모델
struct InquiryPriceOutput: Codable {
    let stck_prpr: String   // 현재가 (문자열)
    let prdy_ctrt: String   // 전일 대비 백분율 (문자열, 예: "1.23", "-0.56")
}

struct InquiryPriceResponse: Codable {
    let output: InquiryPriceOutput
}

// MARK: - 주식 이름(상품명) 조회 관련 모델
struct StockNameOutput: Codable {
    let prdt_abrv_name: String   // 상품명 (주식 이름)
    // 필요한 경우 다른 필드들도 추가할 수 있음
}

struct StockNameResponse: Codable {
    let output: StockNameOutput
}

struct StockPriceFetcher {
    // 가격 조회 API 상수
    static let trIDPrice = "FHKST01010100"
    static let basePriceURL = "https://openapi.koreainvestment.com:9443/uapi/domestic-stock/v1/quotations/inquire-price"
    static let marketDivCode = "J"
    
    // 주식 이름 조회 API 상수
    static let trIDStockName = "CTPF1604R"
    static let baseStockNameURL = "https://openapi.koreainvestment.com:9443/uapi/domestic-stock/v1/quotations/search-info"
    
    /// 현재가와 전일 대비 백분율을 함께 반환하는 함수
    static func fetchCurrentPrice(for code: String) async -> (price: Int, variation: Double) {
        let query = "?FID_COND_MRKT_DIV_CODE=\(marketDivCode)&FID_INPUT_ISCD=\(code)"
        guard let url = URL(string: basePriceURL + query) else {
            return (0, 0.0)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // 비동기적으로 유효한 토큰과 키 정보를 가져옴
        let keys = await getKey()
        request.setValue("Bearer \(keys.token)", forHTTPHeaderField: "authorization")
        request.setValue(keys.appKey, forHTTPHeaderField: "appKey")
        request.setValue(keys.appSecret, forHTTPHeaderField: "appSecret")
        request.setValue(trIDPrice, forHTTPHeaderField: "tr_id")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                return (0, 0.0)
            }
            let decoder = JSONDecoder()
            let priceResponse = try decoder.decode(InquiryPriceResponse.self, from: data)
            let price = Int(priceResponse.output.stck_prpr) ?? 0
            let variation = Double(priceResponse.output.prdy_ctrt) ?? 0.0
            return (price, variation)
        } catch {
            return (0, 0.0)
        }
    }
    
    /// 주식 이름(상품명)을 가져오는 함수
    /// - Parameter code: 상품번호(PDNO), 예를 들어 "000660"
    /// - Returns: 주식 이름 문자열 (실패 시 빈 문자열)
    static func fetchStockName(for code: String) async -> String {
        // PRDT_TYPE_CD: "300"은 주식에 해당됨
        let query = "?PDNO=\(code)&PRDT_TYPE_CD=300"
        guard let url = URL(string: baseStockNameURL + query) else {
            return ""
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        // API 문서에서 요구하는 Content-Type (charset 포함)
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        
        // 비동기적으로 유효한 토큰과 키 정보를 가져옴
        let keys = await getKey()
        request.setValue("Bearer \(keys.token)", forHTTPHeaderField: "authorization")
        request.setValue(keys.appKey, forHTTPHeaderField: "appKey")
        request.setValue(keys.appSecret, forHTTPHeaderField: "appSecret")
        request.setValue(trIDStockName, forHTTPHeaderField: "tr_id")
        // 고객 타입: 개인은 "P", 법인은 "B" (여기서는 "P"로 가정)
        request.setValue("P", forHTTPHeaderField: "custtype")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                return ""
            }
            let decoder = JSONDecoder()
            let stockNameResponse = try decoder.decode(StockNameResponse.self, from: data)
            return stockNameResponse.output.prdt_abrv_name
        } catch {
            return ""
        }
    }
}
