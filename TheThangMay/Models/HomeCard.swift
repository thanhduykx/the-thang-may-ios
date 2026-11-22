import Foundation
import SwiftUI

/// Kiểu mã vạch dùng để hiển thị / lưu vào ví.
enum BarcodeFormat: String, Codable, CaseIterable, Identifiable {
    case qr
    case code128

    var id: String { rawValue }

    var label: String {
        switch self {
        case .qr: return "QR code"
        case .code128: return "Code 128"
        }
    }
}

/// Loại công nghệ của thẻ.
enum CardTechnology: String, Codable, CaseIterable, Identifiable {
    case mifareUltralight
    case mifareClassic
    case mifareDesfire
    case mifarePlus
    case iso15693
    case iso7816
    case felica
    case em4100
    case unknown

    var id: String { rawValue }

    var label: String {
        switch self {
        case .mifareUltralight: return "MIFARE Ultralight / NTAG"
        case .mifareClassic:    return "MIFARE Classic"
        case .mifareDesfire:    return "MIFARE DESFire"
        case .mifarePlus:       return "MIFARE Plus"
        case .iso15693:         return "ISO 15693 (ICODE)"
        case .iso7816:          return "ISO 7816 / thẻ chip"
        case .felica:           return "FeliCa"
        case .em4100:           return "Thẻ ID 125 kHz (nhập tay)"
        case .unknown:          return "Chưa xác định"
        }
    }

    var shortLabel: String {
        switch self {
        case .mifareUltralight: return "Ultralight"
        case .mifareClassic:    return "Classic"
        case .mifareDesfire:    return "DESFire"
        case .mifarePlus:       return "Plus"
        case .iso15693:         return "ISO 15693"
        case .iso7816:          return "ISO 7816"
        case .felica:           return "FeliCa"
        case .em4100:           return "ID 125 kHz"
        case .unknown:          return "Không rõ"
        }
    }

    var symbol: String {
        switch self {
        case .em4100: return "keyboard"
        case .iso7816: return "creditcard"
        case .unknown: return "questionmark.circle"
        default: return "wave.3.right"
        }
    }

    /// Ghi chú ngắn về khả năng của iPhone với loại thẻ này.
    var iphoneNote: String {
        switch self {
        case .mifareUltralight:
            return "iPhone đọc được UID và nội dung bộ nhớ."
        case .mifareClassic:
            return "iPhone chỉ đọc được UID (không đọc được dữ liệu vì thiếu Crypto1)."
        case .mifareDesfire:
            return "iPhone đọc được UID; dữ liệu cần khoá xác thực của toà nhà."
        case .mifarePlus:
            return "iPhone đọc được UID; dữ liệu tuỳ cấu hình của toà nhà."
        case .iso15693:
            return "iPhone đọc được UID và các block dữ liệu."
        case .iso7816:
            return "iPhone đọc được UID; muốn đọc sâu cần khai báo AID của ứng dụng trên thẻ."
        case .felica:
            return "iPhone đọc được IDm nếu khai báo System Code."
        case .em4100:
            return "Thẻ 125 kHz không đọc được bằng iPhone — nhập số in trên thẻ bằng tay."
        case .unknown:
            return "Chưa xác định được loại thẻ."
        }
    }
}

/// Một thẻ đã lưu trong ví.
struct HomeCard: Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String
    var barcodeValue: String
    var format: BarcodeFormat = .qr
    var technology: CardTechnology = .unknown
    var uid: String = ""
    var diagnostics: [String] = []
    var blocks: [String: String] = [:]
    var note: String = ""
    var colorIndex: Int = 0
    var createdAt = Date()
    var lastReadAt: Date?

    var displayValue: String {
        barcodeValue.isEmpty ? uid : barcodeValue
    }

    var sortedBlocks: [BlockEntry] {
        blocks.map { entry in
            BlockEntry(
                key: entry.key,
                value: entry.value,
                index: Int(entry.key.filter(\.isNumber)) ?? 0
            )
        }
        .sorted { lhs, rhs in
            if lhs.index == rhs.index { return lhs.key < rhs.key }
            return lhs.index < rhs.index
        }
    }
}

struct BlockEntry: Identifiable {
    let key: String
    let value: String
    let index: Int

    var id: String { key }
}

extension HomeCard {
    init(scan: ScanResult) {
        self.init(
            name: scan.suggestedName,
            barcodeValue: scan.suggestedValue,
            format: .qr,
            technology: scan.technology,
            uid: scan.uid,
            diagnostics: scan.diagnostics,
            blocks: scan.blocks,
            colorIndex: Int.random(in: 0..<CardPalette.gradients.count)
        )
        lastReadAt = Date()
    }
}

/// Bảng màu cho thẻ trong ví.
enum CardPalette {
    static let gradients: [[Color]] = [
        [Color(hex: 0x0EA5A4), Color(hex: 0x0F766E)],
        [Color(hex: 0x6366F1), Color(hex: 0x4338CA)],
        [Color(hex: 0xF97316), Color(hex: 0xC2410C)],
        [Color(hex: 0xEC4899), Color(hex: 0xBE185D)],
        [Color(hex: 0x22C55E), Color(hex: 0x15803D)],
        [Color(hex: 0x0F172A), Color(hex: 0x334155)],
    ]

    static func gradient(for index: Int) -> [Color] {
        gradients[abs(index) % gradients.count]
    }
}

extension Color {
    init(hex: UInt32) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: 1
        )
    }
}

extension HomeCard {
    /// Thẻ mẫu để giao diện không trống khi mở app lần đầu.
    static var samples: [HomeCard] {
        [
            HomeCard(
                name: "Thẻ thang máy",
                barcodeValue: "04A2B3C4D5E6F7",
                format: .code128,
                technology: .mifareClassic,
                uid: "04:A2:B3:C4:D5:E6:F7",
                diagnostics: ["Họ thẻ: MIFARE Classic (hoặc biến thể không xác định)", "UID: 04:A2:B3:C4:D5:E6:F7"],
                blocks: [:],
                note: "Thẻ mẫu — xoá và quét thẻ thật của bạn.",
                colorIndex: 0
            ),
            HomeCard(
                name: "Thẻ cổng toà nhà",
                barcodeValue: "1234567890",
                format: .qr,
                technology: .em4100,
                uid: "",
                note: "Thẻ mẫu cho thẻ ID 125 kHz.",
                colorIndex: 1
            ),
        ]
    }
}
