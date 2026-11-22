import Foundation

extension Data {
    /// In ra dạng hex, ví dụ "04A2B3" hoặc "04:A2:B3".
    func hexString(separator: String = "") -> String {
        map { String(format: "%02X", Int($0)) }.joined(separator: separator)
    }
}

extension String {
    /// Bỏ mọi ký tự không phải chữ/số, dùng để chuẩn hoá mã thẻ.
    var alphanumericOnly: String {
        filter { $0.isLetter || $0.isNumber }
    }
}
