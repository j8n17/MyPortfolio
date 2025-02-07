// Key.swift
import Foundation

/// API 키들을 담는 구조체
struct APIKeys {
    let token: String
    let appKey: String
    let appSecret: String
}

/// 접근 토큰 응답 모델 (API 스펙에 맞게 키를 정확히 일치)
struct AccessTokenResponse: Codable {
    let accessToken: String
    let tokenType: String
    let expiresIn: Int
    let tokenExpired: String

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case tokenType   = "token_type"
        case expiresIn   = "expires_in"
        case tokenExpired = "access_token_token_expired"
    }
}

/// KeyManager 싱글톤: 토큰 발급, 저장 및 앱 키/시크릿 관리를 담당
class KeyManager {
    static let shared = KeyManager()
    
    private let tokenKey = "accessToken"
    /// 기존의 tokenTimestampKey 대신 tokenExpirationKey에 만료 시각을 저장
    private let tokenExpirationKey = "accessTokenExpiration"
    
    private let appKeyKey = "appKey"
    private let appSecretKey = "appSecret"
    
    // UserDefaults를 통한 앱 키와 앱 시크릿 (기본값: "appKey", "appSecret")
    var appKey: String {
        get { UserDefaults.standard.string(forKey: appKeyKey) ?? "appKey" }
        set { UserDefaults.standard.set(newValue, forKey: appKeyKey) }
    }
    var appSecret: String {
        get { UserDefaults.standard.string(forKey: appSecretKey) ?? "appSecret" }
        set { UserDefaults.standard.set(newValue, forKey: appSecretKey) }
    }
    
    // 접근 토큰 발급 API URL
    private let tokenURL = "https://openapi.koreainvestment.com:9443/oauth2/tokenP"
    
    private init() {}
    
    /// 저장된 토큰이 있으면 만료 시각을 체크 후 반환, 없으면 새로 발급
    func getValidToken() async -> String? {
        let defaults = UserDefaults.standard
        if let token = defaults.string(forKey: tokenKey),
           let expiration = defaults.object(forKey: tokenExpirationKey) as? Date {
            // 현재 시각이 만료 시각 이전이면 기존 토큰 사용
            if Date() < expiration {
                return token
            }
        }
        // 토큰이 없거나 만료되었으면 새 토큰 발급
        if let newToken = await fetchAccessToken() {
            return newToken
        }
        return nil
    }
    
    /// 새 접근 토큰을 API를 통해 발급하고, 만료 시각을 저장
    private func fetchAccessToken() async -> String? {
        guard let url = URL(string: tokenURL) else { return nil }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json; charset=UTF-8", forHTTPHeaderField: "Content-Type")
        
        let body: [String: String] = [
            "grant_type": "client_credentials",
            "appkey": appKey,
            "appsecret": appSecret
        ]
        
        do {
            request.httpBody = try JSONEncoder().encode(body)
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                return nil
            }
            let decoder = JSONDecoder()
            let tokenResponse = try decoder.decode(AccessTokenResponse.self, from: data)
            
            // tokenExpired를 Date로 파싱 (ISO8601 형식으로 가정)
            let expirationString = tokenResponse.tokenExpired
            let formatter = ISO8601DateFormatter()
            let defaults = UserDefaults.standard
            if let expirationDate = formatter.date(from: expirationString) {
                defaults.set(tokenResponse.accessToken, forKey: tokenKey)
                defaults.set(expirationDate, forKey: tokenExpirationKey)
            } else {
                // 파싱 실패 시 expiresIn(초) 값을 기준으로 만료 시각 계산
                let expirationDate = Date().addingTimeInterval(TimeInterval(tokenResponse.expiresIn))
                defaults.set(tokenResponse.accessToken, forKey: tokenKey)
                defaults.set(expirationDate, forKey: tokenExpirationKey)
            }
            
            return tokenResponse.accessToken
        } catch {
            return nil
        }
    }
    
    /// 공개 프로퍼티: 저장된 토큰 만료 시각 (UI 참고용)
    var tokenExpirationDate: Date? {
        return UserDefaults.standard.object(forKey: tokenExpirationKey) as? Date
    }
}

/// 비동기적으로 유효한 토큰과 앱 키, 앱 시크릿을 포함하는 APIKeys를 반환
func getKey() async -> APIKeys {
    let token = await KeyManager.shared.getValidToken() ?? ""
    return APIKeys(token: token, appKey: KeyManager.shared.appKey, appSecret: KeyManager.shared.appSecret)
}
