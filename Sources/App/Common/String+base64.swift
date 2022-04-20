import Foundation
extension String {
    /// bae64 解码
    func base64Decode() -> String? {
        guard let data = Data(base64Encoded: self) else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }
}