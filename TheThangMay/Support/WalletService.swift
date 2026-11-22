import Foundation
import UIKit

/// Cầu nối tới dịch vụ ký pass (.pkpass) để đưa thẻ vào Apple Wallet.
///
/// Apple Wallet chỉ nhận file .pkpass đã được ký bằng chứng chỉ Pass Type ID.
/// App không thể tự ký, nên ta gọi một URL (ví dụ Cloudflare Worker hoặc VPS
/// chạy `wallet-server` kèm trong project) để lấy pass đã ký.
enum WalletService {
    static func passURL(for card: HomeCard, base: String) -> URL? {
        let trimmed = base.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty,
              var components = URLComponents(string: trimmed) else { return nil }

        var items = components.queryItems ?? []
        items.append(contentsOf: [
            URLQueryItem(name: "name", value: card.name),
            URLQueryItem(name: "code", value: card.displayValue),
            URLQueryItem(name: "format", value: card.format.rawValue),
            URLQueryItem(name: "tech", value: card.technology.shortLabel),
        ])
        components.queryItems = items
        return components.url
    }

    static func open(_ url: URL) {
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
}
