import Foundation
import UIKit

/// 使用阿里云百炼千问视觉 API 识图（大家用开发者的 Key，从 Info.plist 读取，用户无需填写）
/// 在 Xcode 的 Info 里配置 DASHSCOPE_API_KEY 后，优先用千问做拍照验证
/// 文档：https://help.aliyun.com/zh/model-studio/vision
enum QwenVerificationService {
    private static let chatURL = "https://dashscope.aliyuncs.com/compatible-mode/v1/chat/completions"
    /// 用 plus 提速（max 效果最好但较慢，plus 对「脚站地」判断足够且更快）
    private static let visionModel = "qwen-vl-plus"

    /// 缩小图片以加快上传与识别（最长边不超过 maxSide）
    private static func resizeForVerify(_ image: UIImage, maxSide: CGFloat) -> UIImage {
        let w = image.size.width, h = image.size.height
        guard w > maxSide || h > maxSide else { return image }
        let scale = min(maxSide / w, maxSide / h)
        let newSize = CGSize(width: w * scale, height: h * scale)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in image.draw(in: CGRect(origin: .zero, size: newSize)) }
    }

    /// 从 Info.plist 读取开发者的千问 API Key（不暴露给用户）
    static var apiKey: String? {
        let raw = Bundle.main.infoDictionary?["DASHSCOPE_API_KEY"] as? String
        let s = raw?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return s.isEmpty ? nil : s
    }

    /// 通过千问视觉判断：这张照片是否显示一个人从第一视角拍摄自己的脚并站在地面上
    /// useHighQuality：用更大图+更强模型再验（识别错误时用户点「再试一次」用）
    static func verify(image: UIImage, apiKey: String, useHighQuality: Bool = false, completion: @escaping (Bool, String?) -> Void) {
        guard !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            DispatchQueue.main.async { completion(false, nil) }
            return
        }
        let key = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        let maxSide: CGFloat = useHighQuality ? 1280 : 640
        let quality: CGFloat = useHighQuality ? 0.75 : 0.5
        let model = useHighQuality ? "qwen-vl-max" : visionModel
        let resized = Self.resizeForVerify(image, maxSide: maxSide)
        guard let jpeg = resized.jpegData(compressionQuality: quality) else {
            DispatchQueue.main.async { completion(false, nil) }
            return
        }
        let base64 = jpeg.base64EncodedString()
        let dataUrl = "data:image/jpeg;base64,\(base64)"

        let prompt = "这张照片是否显示一个人从第一视角拍摄自己的脚，并站在地面上？只回答一个字：是 或 否。"

        let body: [String: Any] = [
            "model": model,
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
            "max_tokens": 16
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
            var passed = false
            var apiError: String?

            if let error = error {
                apiError = error.localizedDescription
            } else if let http = response as? HTTPURLResponse, http.statusCode != 200 {
                apiError = "HTTP \(http.statusCode)"
                if let data = data, let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let err = json["error"] as? [String: Any], let msg = err["message"] as? String {
                    apiError = msg
                }
            } else if let data = data, let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                if let err = json["error"] as? [String: Any] {
                    apiError = (err["message"] as? String) ?? (err["code"] as? String) ?? "API 返回错误"
                } else if let choices = json["choices"] as? [[String: Any]],
                          let first = choices.first,
                          let message = first["message"] as? [String: Any] {
                    let text: String? = {
                        if let s = message["content"] as? String { return s }
                        if let arr = message["content"] as? [[String: Any]] {
                            return arr.compactMap { $0["text"] as? String }.joined()
                        }
                        return nil
                    }()
                    if let t = text?.trimmingCharacters(in: .whitespacesAndNewlines), !t.isEmpty {
                        let u = t.uppercased()
                        passed = t.hasPrefix("是") || t.contains("是") || u.contains("YES") || u.contains("对") || u.contains("正确")
                    }
                } else {
                    apiError = "无法解析 API 返回"
                }
            } else {
                apiError = "无有效返回"
            }

            DispatchQueue.main.async { completion(passed, apiError) }
        }.resume()
    }
}
