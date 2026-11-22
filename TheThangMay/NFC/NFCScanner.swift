import Foundation
import CoreNFC

/// Kết quả một lần đọc thẻ.
struct ScanResult {
    var uid: String
    var technology: CardTechnology
    var diagnostics: [String]
    var blocks: [String: String]
    var suggestedName: String
    var suggestedValue: String
}

/// Bọc CoreNFC để quét thẻ và dò loại thẻ.
final class NFCScanner: NSObject, ObservableObject {
    @Published var isScanning = false
    @Published var errorMessage: String?

    private var session: NFCTagReaderSession?
    private var onResult: ((ScanResult) -> Void)?
    private var onError: ((String) -> Void)?
    private var didSucceed = false

    static var isAvailable: Bool { NFCTagReaderSession.readingAvailable }

    func start(onResult: @escaping (ScanResult) -> Void,
               onError: @escaping (String) -> Void) {
        guard NFCTagReaderSession.readingAvailable else {
            onError("Máy này không hỗ trợ quét NFC. Bạn vẫn có thể nhập mã thẻ bằng tay.")
            return
        }

        self.onResult = onResult
        self.onError = onError
        didSucceed = false
        errorMessage = nil
        isScanning = true

        let session = NFCTagReaderSession(
            pollingOption: [.iso14443, .iso15693],
            delegate: self,
            queue: nil
        )
        session.alertMessage = "Đưa phần trên của iPhone lại gần thẻ nhà, giữ yên 2 giây"
        self.session = session
        session.begin()
    }

    func cancel() {
        session?.invalidate()
        session = nil
        isScanning = false
    }
}

// MARK: - NFCTagReaderSessionDelegate

extension NFCScanner: NFCTagReaderSessionDelegate {
    func tagReaderSessionDidBecomeActive(_ session: NFCTagReaderSession) {}

    func tagReaderSession(_ session: NFCTagReaderSession,
                          didInvalidateWithError error: Error) {
        DispatchQueue.main.async {
            self.isScanning = false
            self.session = nil
            if self.didSucceed { return }

            if let readerError = error as? NFCReaderError,
               readerError.code == .readerSessionInvalidationErrorUserCanceled {
                return
            }

            let message = Self.friendlyMessage(for: error)
            self.errorMessage = message
            self.onError?(message)
        }
    }

    func tagReaderSession(_ session: NFCTagReaderSession, didDetect tags: [NFCTag]) {
        guard let tag = tags.first else {
            session.restartPolling()
            return
        }

        if tags.count > 1 {
            session.alertMessage = "Có nhiều thẻ một lúc. Chỉ giữ lại một thẻ rồi thử lại."
            session.restartPolling()
            return
        }

        session.connect(to: tag) { [weak self] error in
            guard let self else { return }
            if error != nil {
                session.restartPolling()
                return
            }

            // Đọc dữ liệu trên hàng đợi nền để tránh chặn main thread.
            DispatchQueue.global(qos: .userInitiated).async {
                let result = self.inspect(tag: tag)
                DispatchQueue.main.async {
                    self.didSucceed = true
                    session.alertMessage = "Đã đọc thẻ"
                    session.invalidate()
                    self.session = nil
                    self.isScanning = false
                    self.onResult?(result)
                }
            }
        }
    }

    private static func friendlyMessage(for error: Error) -> String {
        if let readerError = error as? NFCReaderError {
            switch readerError.code {
            case .readerSessionInvalidationErrorSessionTimeout:
                return "Hết thời gian chờ. Hãy thử lại và giữ iPhone sát thẻ lâu hơn."
            case .readerSessionInvalidationErrorFirstNDEFTagRead:
                return "Thẻ đã được đọc trước đó."
            case .readerErrorUnsupportedFeature:
                return "Thiết bị hoặc thẻ không hỗ trợ tính năng này."
            case .readerSessionInvalidationErrorSystemIsBusy:
                return "NFC đang bận (có thể đang quét Face ID / Apple Pay). Thử lại sau vài giây."
            default:
                break
            }
        }
        return (error as NSError).localizedDescription
    }
}

// MARK: - Inspecting tags

private extension NFCScanner {
    func inspect(tag: NFCTag) -> ScanResult {
        switch tag {
        case .miFare(let mifare):
            return inspectMiFare(mifare)
        case .iso15693(let iso):
            return inspectISO15693(iso)
        case .iso7816(let iso):
            var lines = ["Giao thức: ISO 7816 (ISO-DEP / APDU)"]
            lines.append("UID: \(iso.identifier.hexString(separator: ":"))")
            if let historical = iso.historicalBytes, !historical.isEmpty {
                lines.append("Historical bytes: \(historical.hexString(separator: " "))")
            }
            if let application = iso.applicationData, !application.isEmpty {
                lines.append("Application data: \(application.hexString(separator: " "))")
            }
            lines.append("AID đang chọn: \(iso.initialSelectedAID)")
            return ScanResult(
                uid: iso.identifier.hexString(separator: ":"),
                technology: .iso7816,
                diagnostics: lines,
                blocks: [:],
                suggestedName: "Thẻ ISO 7816",
                suggestedValue: iso.identifier.hexString()
            )
        case .feliCa(let felica):
            var lines = ["Giao thức: FeliCa (NFC-F)"]
            lines.append("IDm: \(felica.currentIDm.hexString(separator: ":"))")
            lines.append("System code: \(felica.currentSystemCode.hexString(separator: ":"))")
            return ScanResult(
                uid: felica.currentIDm.hexString(separator: ":"),
                technology: .felica,
                diagnostics: lines,
                blocks: [:],
                suggestedName: "Thẻ FeliCa",
                suggestedValue: felica.currentIDm.hexString()
            )
        @unknown default:
            return ScanResult(
                uid: "",
                technology: .unknown,
                diagnostics: ["Không nhận diện được loại thẻ này."],
                blocks: [:],
                suggestedName: "Thẻ mới",
                suggestedValue: ""
            )
        }
    }

    func inspectMiFare(_ tag: NFCMiFareTag) -> ScanResult {
        let uid = tag.identifier.hexString(separator: ":")
        let uidPlain = tag.identifier.hexString()
        var lines: [String] = []
        var blocks: [String: String] = [:]
        var technology = CardTechnology.unknown
        var suggestedName = "Thẻ NFC"

        switch tag.mifareFamily {
        case .ultralight:
            technology = .mifareUltralight
            suggestedName = "Thẻ NFC"
            lines.append("Họ thẻ: MIFARE Ultralight / NTAG")
        case .desfire:
            technology = .mifareDesfire
            suggestedName = "Thẻ DESFire"
            lines.append("Họ thẻ: MIFARE DESFire")
        case .plus:
            technology = .mifarePlus
            suggestedName = "Thẻ MIFARE Plus"
            lines.append("Họ thẻ: MIFARE Plus")
        default:
            technology = .mifareClassic
            suggestedName = "Thẻ thang máy"
            lines.append("Họ thẻ: MIFARE Classic (hoặc biến thể không xác định)")
        }

        lines.append("UID: \(uid)")
        if let historical = tag.historicalBytes, !historical.isEmpty {
            lines.append("Historical bytes: \(historical.hexString(separator: " "))")
        }

        switch tag.mifareFamily {
        case .ultralight:
            var page = 4
            while page <= 40 {
                guard let data = send(tag, Data([0x30, UInt8(page)])), !data.isEmpty else { break }
                var offset = 0
                var localPage = page
                while offset < data.count {
                    let end = min(offset + 4, data.count)
                    blocks["Trang \(localPage)"] = data.subdata(in: offset..<end)
                        .hexString(separator: " ")
                    offset = end
                    localPage += 1
                }
                page += 4
            }
            if blocks.isEmpty {
                lines.append("Không đọc được nội dung bộ nhớ (thẻ có thể đã bị khoá).")
            }
        case .desfire, .plus:
            if let version = send(tag, Data([0x60])), !version.isEmpty {
                blocks["GetVersion"] = version.hexString(separator: " ")
                lines.append("Đã gửi lệnh GetVersion (0x60) thành công.")
            } else {
                lines.append("Thẻ cần xác thực trước khi đọc dữ liệu — bình thường với DESFire.")
            }
        default:
            if let data = send(tag, Data([0x30, 0x04])), !data.isEmpty {
                blocks["Trang 4"] = data.hexString(separator: " ")
            } else {
                lines.append("Không đọc được block dữ liệu: MIFARE Classic cần khoá Crypto1 mà iPhone không hỗ trợ. Chỉ đọc được UID.")
            }
        }

        lines.append("Ghi chú: \(technology.iphoneNote)")

        return ScanResult(
            uid: uid,
            technology: technology,
            diagnostics: lines,
            blocks: blocks,
            suggestedName: suggestedName,
            suggestedValue: uidPlain
        )
    }

    func inspectISO15693(_ tag: NFCISO15693Tag) -> ScanResult {
        let uid = tag.identifier.hexString(separator: ":")
        var lines = ["Giao thức: ISO 15693 (NFC-V / ICODE)"]
        lines.append("UID: \(uid)")
        lines.append("Mã nhà sản xuất IC: \(String(format: "0x%02X", tag.icManufacturerCode))")

        var blocks: [String: String] = [:]
        let semaphore = DispatchSemaphore(value: 0)
        tag.readMultipleBlocks(
            requestFlags: [.highDataRate],
            blockRange: NSRange(location: 0, length: 12)
        ) { data, error in
            if error == nil {
                for (index, block) in data.enumerated() {
                    blocks["Block \(index)"] = block.hexString(separator: " ")
                }
            }
            semaphore.signal()
        }
        _ = semaphore.wait(timeout: .now() + 2)

        if blocks.isEmpty {
            lines.append("Không đọc được block dữ liệu (thẻ có thể được bảo vệ).")
        }
        lines.append("Ghi chú: \(CardTechnology.iso15693.iphoneNote)")

        return ScanResult(
            uid: uid,
            technology: .iso15693,
            diagnostics: lines,
            blocks: blocks,
            suggestedName: "Thẻ ISO 15693",
            suggestedValue: tag.identifier.hexString()
        )
    }

    /// Gửi lệnh thô tới thẻ MIFARE, chờ tối đa 1,5 giây.
    func send(_ tag: NFCMiFareTag, _ packet: Data) -> Data? {
        let semaphore = DispatchSemaphore(value: 0)
        var output: Data?
        tag.sendMiFareCommand(commandPacket: packet) { data, error in
            if error == nil { output = data }
            semaphore.signal()
        }
        _ = semaphore.wait(timeout: .now() + 1.5)
        return output
    }
}
