import SwiftUI
import UIKit

struct CardDetailView: View {
    let cardID: UUID

    @EnvironmentObject private var store: CardStore
    @Environment(\.dismiss) private var dismiss
    @AppStorage("walletServiceURL") private var walletServiceURL = ""

    @State private var showEditor = false
    @State private var showQuickTap = false
    @State private var showUID = false
    @State private var showWalletHelp = false

    private var card: HomeCard? { store.card(with: cardID) }

    var body: some View {
        Group {
            if let card {
                content(for: card)
            } else {
                ContentUnavailableView(
                    "Không tìm thấy thẻ",
                    systemImage: "creditcard.trianglebadge.exclamationmark",
                    description: Text("Thẻ này có thể đã bị xoá.")
                )
            }
        }
        .navigationTitle(card?.name ?? "Thẻ")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Sửa") { showEditor = true }
                    .disabled(card == nil)
            }
        }
        .sheet(isPresented: $showEditor) {
            if let card {
                NavigationStack {
                    CardEditorView(card: card) { updated in
                        store.update(updated)
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $showQuickTap) {
            if let card {
                QuickTapView(card: card)
            }
        }
        .fullScreenCover(isPresented: $showUID) {
            if let card {
                UIDDisplayView(card: card)
            }
        }
        .alert("Chưa có dịch vụ ký pass", isPresented: $showWalletHelp) {
            Button("Đã hiểu", role: .cancel) {}
        } message: {
            Text("Apple Wallet chỉ nhận file .pkpass đã ký bằng chứng chỉ Pass Type ID.\n\nMở Cài đặt → dán địa chỉ máy chủ ký pass (kèm trong project ở thư mục wallet-server), sau đó bấm lại nút này.\n\nChưa có máy chủ? Dùng nút “Chế độ quẹt” để hiện mã toàn màn hình.")
        }
    }

    @ViewBuilder
    private func content(for card: HomeCard) -> some View {
        ScrollView {
            VStack(spacing: 18) {
                barcodeCard(for: card)

                HStack(spacing: 12) {
                    Button {
                        showQuickTap = true
                    } label: {
                        Label("Chế độ quẹt", systemImage: "qrcode.viewfinder")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(PrimaryButtonStyle())

                    Button {
                        addToWallet(card)
                    } label: {
                        Label("Vào Wallet", systemImage: "wallet.pass")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(SecondaryButtonStyle())
                }

                Button {
                    showUID = true
                } label: {
                    Label("Hiện UID toàn màn hình", systemImage: "number.square")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(SecondaryButtonStyle())

                infoSection(for: card)

                if !card.diagnostics.isEmpty || !card.blocks.isEmpty {
                    diagnosticsSection(for: card)
                }

                if !card.note.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Ghi chú")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(.secondary)
                        Text(card.note)
                            .font(.subheadline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(16)
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }

                Button(role: .destructive) {
                    store.delete(card)
                    dismiss()
                } label: {
                    Text("Xoá thẻ")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .padding(.top, 4)
            }
            .padding(20)
        }
        .background(Color(.systemGroupedBackground))
    }

    private func barcodeCard(for card: HomeCard) -> some View {
        VStack(spacing: 14) {
            if let image = BarcodeGenerator.image(for: card.displayValue, format: card.format, scale: 10) {
                Image(uiImage: image)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 220)
            } else {
                Image(systemName: "barcode")
                    .font(.system(size: 60))
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 30)
            }

            Text(card.displayValue)
                .font(.system(.footnote, design: .monospaced))
                .foregroundStyle(.black.opacity(0.65))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: .black.opacity(0.08), radius: 10, y: 4)
    }

    private func infoSection(for card: HomeCard) -> some View {
        VStack(spacing: 0) {
            infoRow("Loại thẻ", card.technology.label)
            Divider().padding(.leading, 16)
            infoRow("UID", card.uid.isEmpty ? "—" : card.uid, monospaced: true)
            Divider().padding(.leading, 16)
            infoRow("Kiểu mã", card.format.label)
            Divider().padding(.leading, 16)
            infoRow("Ngày thêm", card.createdAt.formatted(date: .abbreviated, time: .shortened))
            if let lastRead = card.lastReadAt {
                Divider().padding(.leading, 16)
                infoRow("Đọc lần cuối", lastRead.formatted(date: .abbreviated, time: .shortened))
            }
        }
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func infoRow(_ title: String, _ value: String, monospaced: Bool = false) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer(minLength: 16)
            Text(value)
                .font(monospaced ? .system(.subheadline, design: .monospaced) : .subheadline)
                .multilineTextAlignment(.trailing)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private func diagnosticsSection(for card: HomeCard) -> some View {
        DisclosureGroup {
            VStack(alignment: .leading, spacing: 10) {
                ForEach(card.diagnostics, id: \.self) { line in
                    Text(line)
                        .font(.system(.caption, design: .monospaced))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                if !card.blocks.isEmpty {
                    Divider()
                    ForEach(card.sortedBlocks) { block in
                        HStack(alignment: .top, spacing: 8) {
                            Text(block.key)
                                .font(.system(.caption2, design: .monospaced))
                                .foregroundStyle(.secondary)
                                .frame(width: 90, alignment: .leading)
                            Text(block.value)
                                .font(.system(.caption2, design: .monospaced))
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
            }
            .padding(.top, 10)
        } label: {
            Label("Dữ liệu đọc được từ thẻ", systemImage: "doc.text.magnifyingglass")
                .font(.subheadline.weight(.semibold))
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func addToWallet(_ card: HomeCard) {
        if let url = WalletService.passURL(for: card, base: walletServiceURL) {
            WalletService.open(url)
        } else {
            showWalletHelp = true
        }
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.vertical, 14)
            .background(
                LinearGradient(
                    colors: [Color(hex: 0x0EA5A4), Color(hex: 0x0F766E)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(Capsule())
            .opacity(configuration.isPressed ? 0.8 : 1)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(Color(hex: 0x0F766E))
            .padding(.vertical, 14)
            .background(Color(hex: 0x0EA5A4).opacity(0.14))
            .clipShape(Capsule())
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}

#Preview {
    NavigationStack {
        CardDetailView(cardID: HomeCard.samples[0].id)
            .environmentObject(CardStore())
    }
}
