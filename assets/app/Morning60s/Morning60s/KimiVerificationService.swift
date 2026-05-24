import Foundation
import UIKit

/// 使用 Kimi（月之暗面 Moonshot）API 识图：判断是否为「第一视角拍脚、站在地面上」
/// 国内用 platform.moonshot.cn 创建 Key，请求地址为 api.moonshot.cn
enum KimiVerificationService {
    private static let visionModel = "moonshot-v1-8k-vision-preview"
    /// 国内开放平台用 .cn，国际用 .ai
    private static let chatURL = "https://api.moonshot.cn/v1/chat/completions"

    /// 通过 Kimi 视觉模型判断：这张照片是否显示一个人从第一视角拍摄自己的脚并站在地面上
    static func verify(image: UIImage, apiKey: String, completion: @escaping (Bool) -> Void) {
        guard !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              let jpeg = image.jpegData(compressionQuality: 0.7) else {
            DispatchQueue.main.async { completion(false) }
            return
        }
        let key = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        let base64 = jpeg.base64EncodedString()
        let dataUrl = "data:image/jpeg;base64,\(base64)"

        let prompt = "这张照片是否显示一个人从第一视角拍摄自己的脚，并站在地面上？只回答一个字：是 或 否。"

        let body: [String: Any] = [
            "model": visionModel,
            "messages": [
                [
                    "role": "user",
                    "content": [
                        ["type": "image_url", "image_url": ["url": dataUrl]],
                        ["type": "text", "text": prompt]
                    ]
                ]
            ],
            "temperature": 0.1,
            "max_completion_tokens": 16
        ]

        guard let url = URL(string: chatURL),
              let bodyData = try? JSONSerialization.data(withJSONObject: body) else {
            DispatchQueue.main.async { completion(false) }
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        request.httpBody = bodyData

        URLSession.shared.dataTask(with: request) { data, response, error in
            var passed = false
            if let data = data,
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let choices = json["choices"] as? [[String: Any]],
               let first = choices.first,
               let message = first["message"] as? [String: Any],
               let text = message["content"] as? String {
                let t = text.trimmingCharacters(in: .whitespacesAndNewlines)
                passed = t.hasPrefix("是") || t.uppercased().contains("YES")
            }
            DispatchQueue.main.async { completion(passed) }
        }.resume()
    }

    /// 验证 Kimi API Key 是否有效
    static func validateApiKey(_ apiKey: String, completion: @escaping (Bool, String?) -> Void) {
        let key = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !key.isEmpty else {
            DispatchQueue.main.async { completion(false, nil) }
            return
        }
        /// 验证时用纯文本模型（国内 .cn 支持 moonshot-v1-8k）
        let body: [String: Any] = [
            "model": "moonshot-v1-8k",
            "messages": [["role": "user", "content": "回复OK"]],
            "max_completion_tokens": 8
        ]
        guard let url = URL(string: chatURL),
              let bodyData = try? JSONSerialization.data(withJSONObject: body) else {
            DispatchQueue.main.async { completion(false, nil) }
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        request.httpBody = bodyData

        URLSession.shared.dataTask(with: request) { data, response, error in
            let http = response as? HTTPURLResponse
            let code = http?.statusCode ?? -1
            if code == 200 {
                DispatchQueue.main.async { completion(true, nil) }
                return
            }
            var hint = ""
            if let error = error {
                hint = error.localizedDescription
            } else if let data = data, let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let err = json["error"] as? [String: Any],
                      let msg = err["message"] as? String {
                hint = msg
            } else if code == 401 {
                hint = "API Key 无效或错误"
            } else if code == 403 {
                hint = "无权限或余额不足"
            } else if code == -1 || code == 0 {
                hint = "网络请求失败，请检查网络"
            } else {
                hint = "HTTP \(code)"
            }
            DispatchQueue.main.async { completion(false, hint) }
        }.resume()
    }
}
