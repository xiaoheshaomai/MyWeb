import Foundation
import UIKit

/// 请求你自己的后端做拍照验证（后端用你的 Kimi Key 调 Moonshot，用户无需填 Key）
/// 后端接口：POST JSON { "image": "<base64>" }，返回 { "passed": true/false }
enum BackendVerifyService {
    /// 从 Info.plist 读取「验证服务地址」，上线时在 Xcode 里配置，大家就统一走你的 API
    static var backendURL: String? {
        let raw = Bundle.main.infoDictionary?["VerifyBackendURL"] as? String
        let s = raw?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return s.isEmpty ? nil : s
    }

    static func verify(image: UIImage, urlString: String, completion: @escaping (Bool) -> Void) {
        guard let jpeg = image.jpegData(compressionQuality: 0.7),
              let url = URL(string: urlString) else {
            DispatchQueue.main.async { completion(false) }
            return
        }
        let base64 = jpeg.base64EncodedString()
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: ["image": base64])

        URLSession.shared.dataTask(with: request) { data, _, _ in
            var passed = false
            if let data = data,
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let p = json["passed"] as? Bool {
                passed = p
            }
            DispatchQueue.main.async { completion(passed) }
        }.resume()
    }
}
