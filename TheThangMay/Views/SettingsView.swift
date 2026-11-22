import SwiftUI
import CoreNFC

struct SettingsView: View {
    @EnvironmentObject private var store: CardStore
    @Environment(\.dismiss) private var dismiss
    @AppStorage("walletServiceURL") private var walletServiceURL = ""

    var body: some View {
        Form {
            Section {
                statusRow(
                    title: "Phần cứng NFC",
                    ok: NFCScanner.isAvailable,
                    okText: "Sẵn sàng đọc thẻ",
                    badText: "Không khả dụng"
                )
                statusRow(
                    title: "Quyền NFC của app",
                    ok: NFCScanner.hasNFCEntitlement,
                    okText: "Đã có entitlement",
                    badText: "Thiếu entitlement"
                )
                statusRow(
                    title: "Mô tả quyền (Info.plist)",
                    ok: NFCScanner.hasUsageDescription,
                    okText: "Đã có NFCReaderUsageDescription",
                    badText: "Thiếu NFCReaderUsageDescription"
                )
            } header: {
                Text("NFC")
            } footer: {
                if !NFCScanner.hasNFCEntitlement {
                    Text("App thiếu entitlement NFC — đây chính là lý do báo “không hỗ trợ quét”. Cần bản IPA được ký bằng tài khoản Apple Developer trả phí; Apple ID miễn phí không cấp quyền NFC Tag Reading.")
                } else if !NFCScanner.isAvailable {
                    Text("Entitlement đã có nhưng phiên quét chưa sẵn sàng. Đóng app, tắt bảng Apple Pay/Face ID rồi mở lại.")
                }
            }

            Section {
                TextField("https://wallet.example.com/pass", text: $walletServiceURL)
                    .keyboardType(.URL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            } header: {
                Text("Máy chủ ký pass Apple Wallet")
            } footer: {
                Text("Apple Wallet chỉ nhận .pkpass đã ký bằng chứng chỉ Pass Type ID. Chạy thư mục wallet-server (kèm trong project) rồi dán URL vào đây.")
            }

            Section("Dữ liệu") {
                LabeledContent("Số thẻ đã lưu", value: "\(store.cards.count)")
                ShareLink(item: diagnosticsText) {
                    Label("Xuất chẩn đoán thẻ", systemImage: "square.and.arrow.up")
                }
                .disabled(store.cards.isEmpty)
            }

            Section("Trợ giúp") {
                NavigationLink {
                    HelpView()
                } label: {
                    Label("iPhone đọc được thẻ nào?", systemImage: "questionmark.circle")
                }
                NavigationLink {
                    AboutView()
                } label: {
                    Label("Về app này", systemImage: "info.circle")
                }
            }
        }
        .navigationTitle("Cài đặt")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Xong") { dismiss() }
            }
        }
    }

    private func statusRow(title: String, ok: Bool, okText: String, badText: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: ok ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundStyle(ok ? Color.green : Color.orange)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                Text(ok ? okText : badText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var diagnosticsText: String {
        var lines = ["BÁO CÁO THẺ — Thẻ Thang Máy", ""]
        for card in store.cards {
            lines.append("• \(card.name)")
            lines.append("  Loại: \(card.technology.label)")
            lines.append("  UID: \(card.uid)")
            lines.append("  Kiểu mã: \(card.format.label) — giá trị: \(card.displayValue)")
            for line in card.diagnostics {
                lines.append("  \(line)")
            }
            for block in card.sortedBlocks {
                lines.append("  \(block.key): \(block.value)")
            }
            lines.append("")
        }
        return lines.joined(separator: "\n")
    }
}

struct HelpView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                helpSection(
                    title: "iPhone chỉ đọc, không phát lại thẻ",
                    body: "iPhone có thể đọc thẻ 13,56 MHz nhưng Apple không cho app giả lập thẻ để quẹt vào đầu đọc. Vì vậy app này lưu thông tin thẻ và hiện mã QR/Code 128 để đầu đọc có camera quét."
                )

                helpSection(
                    title: "Thẻ 13,56 MHz (có chip)",
                    body: "Thường là MIFARE Classic, Ultralight hoặc DESFire. iPhone đọc được UID của tất cả các loại này, nhưng chỉ đọc được dữ liệu bên trong với Ultralight / ISO 15693. MIFARE Classic cần khoá Crypto1 mà iPhone không có."
                )

                helpSection(
                    title: "Thẻ 125 kHz (thẻ dẹt, không chip)",
                    body: "iPhone không đọc được vì tần số khác. Hãy nhìn số in trên thẻ và nhập tay. Nếu thẻ không in số, cần một đầu đọc 125 kHz rời."
                )

                helpSection(
                    title: "Vì sao báo “máy không hỗ trợ quét NFC”?",
                    body: "Không phải lỗi phần cứng. App phải được ký với entitlement NFC (NFC Tag Reading). Apple ID miễn phí / Sideloadly không cấp quyền này, nên iPhone coi app là không có NFC. Kiểm tra trong Cài đặt → mục NFC. Muốn quét thật cần bản IPA ký bằng tài khoản Apple Developer trả phí."
                )

                helpSection(
                    title: "Thẻ MIFARE Classic 1K trắng (UID-only)",
                    body: "Nếu dump cho thấy sector 1–15 toàn 0x00 và key FFFFFFFFFFFF thì hệ thống chỉ so UID. Khi đó chỉ cần thẻ magic 1K (ghi được block 0) chép đúng UID là mở được cửa — không cần quan tâm sector."
                )

                helpSection(
                    title: "Khi nào quẹt được bằng điện thoại?",
                    body: "Chỉ khi đầu đọc thang máy có camera/đầu quét QR, hoặc toà nhà đã hỗ trợ điện thoại (HomeKey, NFC pass). Với đầu đọc chỉ nhận thẻ vật lý, cách chắc chắn nhất vẫn là mang thẻ theo."
                )
            }
            .padding(20)
        }
        .navigationTitle("Trợ giúp")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func helpSection(title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.headline)
            Text(body)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

struct AboutView: View {
    var body: some View {
        List {
            Section {
                LabeledContent("Tên app", value: "Thẻ Thang Máy")
                LabeledContent("Phiên bản", value: "1.0")
                LabeledContent("Nền tảng", value: "iOS 17 trở lên")
            }
            Section("Công nghệ") {
                Text("SwiftUI · CoreNFC · Core Image · PassKit")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Về app")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        SettingsView()
            .environmentObject(CardStore())
    }
}
