import SwiftUI
import CoreNFC

struct SettingsView: View {
    @EnvironmentObject private var store: CardStore
    @Environment(\.dismiss) private var dismiss
    @AppStorage("walletServiceURL") private var walletServiceURL = ""

    var body: some View {
        Form {
            Section {
                HStack {
                    Image(systemName: NFCScanner.isAvailable ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                        .foregroundStyle(NFCScanner.isAvailable ? .green : .orange)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Quét NFC")
                        Text(NFCScanner.isAvailable
                             ? "Thiết bị hỗ trợ đọc thẻ."
                             : "Thiết bị không hỗ trợ, hoặc app chưa được cấp quyền NFC.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            } header: {
                Text("Phần cứng")
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
