import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var store: CardStore

    @State private var showScanner = false
    @State private var showManualAdd = false
    @State private var showSettings = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    scanButton

                    if store.cards.isEmpty {
                        emptyState
                    } else {
                        ForEach(store.cards) { card in
                            NavigationLink(value: card.id) {
                                WalletCardView(card: card)
                            }
                            .buttonStyle(.plain)
                            .contextMenu {
                                Button(role: .destructive) {
                                    store.delete(card)
                                } label: {
                                    Label("Xoá thẻ", systemImage: "trash")
                                }
                            }
                        }
                    }

                    tipCard
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 32)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Ví thẻ của tôi")
            .navigationDestination(for: UUID.self) { id in
                CardDetailView(cardID: id)
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            showScanner = true
                        } label: {
                            Label("Quét thẻ NFC", systemImage: "wave.3.right")
                        }
                        Button {
                            showManualAdd = true
                        } label: {
                            Label("Nhập mã bằng tay", systemImage: "keyboard")
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                    }
                }
            }
            .sheet(isPresented: $showScanner) {
                ScanSheet { card in
                    store.add(card)
                }
            }
            .sheet(isPresented: $showManualAdd) {
                NavigationStack {
                    CardEditorView(card: nil) { card in
                        store.add(card)
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                NavigationStack {
                    SettingsView()
                        .environmentObject(store)
                }
            }
        }
    }

    private var scanButton: some View {
        Button {
            showScanner = true
        } label: {
            HStack(spacing: 14) {
                Image(systemName: "wave.3.right")
                    .font(.title2)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Quét thẻ nhà")
                        .font(.headline)
                    Text("Chạm iPhone vào thẻ để dò loại thẻ")
                        .font(.subheadline)
                        .opacity(0.85)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .opacity(0.7)
            }
            .foregroundStyle(.white)
            .padding(18)
            .frame(maxWidth: .infinity)
            .background(
                LinearGradient(
                    colors: [Color(hex: 0x0EA5A4), Color(hex: 0x0F766E)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "wallet.pass")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)
            Text("Chưa có thẻ nào")
                .font(.headline)
            Text("Quét thẻ nhà hoặc nhập mã bằng tay để bắt đầu.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var tipCard: some View {
        NavigationLink {
            HelpView()
        } label: {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "info.circle")
                    .foregroundStyle(Color(hex: 0x0F766E))
                VStack(alignment: .leading, spacing: 4) {
                    Text("iPhone không tự phát được thẻ từ")
                        .font(.subheadline.weight(.semibold))
                    Text("Xem hướng dẫn để biết khi nào dùng được QR và khi nào cần cách khác.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(16)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    HomeView()
        .environmentObject(CardStore())
}
