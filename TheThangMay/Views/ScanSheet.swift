import SwiftUI

/// Bottom sheet: quét thẻ, hiển thị chẩn đoán và cho lưu vào ví.
struct ScanSheet: View {
    var onSave: (HomeCard) -> Void

    @Environment(\.dismiss) private var dismiss
    @StateObject private var scanner = NFCScanner()

    @State private var draft: HomeCard?
    @State private var errorText: String?
    @State private var hasStarted = false
    @State private var name = ""
    @State private var value = ""
    @State private var format: BarcodeFormat = .qr

    var body: some View {
        NavigationStack {
            Group {
                if let draft {
                    resultForm(for: draft)
                } else {
                    scanningContent
                }
            }
            .navigationTitle(draft == nil ? "Quét thẻ nhà" : "Lưu vào ví")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Đóng") {
                        scanner.cancel()
                        dismiss()
                    }
                }
                if draft != nil {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Quét lại") {
                            draft = nil
                            start()
                        }
                    }
                }
            }
        }
        .onAppear {
            guard !hasStarted else { return }
            hasStarted = true
            start()
        }
        .onDisappear {
            scanner.cancel()
        }
    }

    private var scanningContent: some View {
        VStack(spacing: 22) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color(hex: 0x0EA5A4).opacity(0.12))
                    .frame(width: 170, height: 170)
                Image(systemName: "wave.3.right")
                    .font(.system(size: 62))
                    .foregroundStyle(Color(hex: 0x0F766E))
                    .symbolEffect(.pulse, options: .repeating)
            }

            VStack(spacing: 8) {
                Text(scanner.isScanning ? "Đang chờ thẻ…" : "Sẵn sàng quét")
                    .font(.headline)
                Text("Đưa phần trên của iPhone sát thẻ nhà.\nGiữ yên khoảng 2 giây.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            if let errorText {
                VStack(spacing: 10) {
                    Text(errorText)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)

                    Button("Thử lại") { start() }
                        .buttonStyle(SecondaryButtonStyle())
                        .padding(.horizontal, 60)
                }
            }

            Spacer()

            VStack(spacing: 10) {
                Button {
                    scanner.cancel()
                    draft = HomeCard(name: "Thẻ nhà", barcodeValue: "", technology: .em4100)
                } label: {
                    Label("Nhập mã bằng tay", systemImage: "keyboard")
                        .font(.subheadline.weight(.semibold))
                }

                Text("Thẻ ID 125 kHz (thẻ dẹt) không đọc được bằng iPhone — dùng cách nhập tay.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            .padding(.bottom, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }

    private func resultForm(for draft: HomeCard) -> some View {
        Form {
            Section("Kết quả đọc") {
                LabeledContent("Loại thẻ", value: draft.technology.label)
                LabeledContent("UID", value: draft.uid.isEmpty ? "—" : draft.uid)
                if !draft.diagnostics.isEmpty {
                    ForEach(draft.diagnostics, id: \.self) { line in
                        Text(line)
                            .font(.system(.caption2, design: .monospaced))
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Section("Lưu vào ví") {
                TextField("Tên thẻ", text: $name)
                TextField("Mã hiển thị", text: $value)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                    .font(.body.monospaced())
                Picker("Kiểu mã", selection: $format) {
                    ForEach(BarcodeFormat.allCases) { item in
                        Text(item.label).tag(item)
                    }
                }
            }

            if !draft.blocks.isEmpty {
                Section("Dữ liệu thẻ") {
                    ForEach(draft.sortedBlocks) { block in
                        HStack(alignment: .top, spacing: 8) {
                            Text(block.key)
                                .font(.system(.caption2, design: .monospaced))
                                .foregroundStyle(.secondary)
                            Spacer(minLength: 8)
                            Text(block.value)
                                .font(.system(.caption2, design: .monospaced))
                                .multilineTextAlignment(.trailing)
                        }
                    }
                }
            }

            Section {
                Button {
                    var card = draft
                    card.name = name.trimmingCharacters(in: .whitespaces)
                    card.barcodeValue = value.trimmingCharacters(in: .whitespaces)
                    card.format = format
                    card.lastReadAt = Date()
                    onSave(card)
                    dismiss()
                } label: {
                    Text("Lưu thẻ")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                }
                .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty ||
                          value.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .onAppear {
            if name.isEmpty { name = draft.suggestedNameForForm }
            if value.isEmpty { value = draft.suggestedValueForForm }
        }
    }

    private func start() {
        errorText = nil
        scanner.start { result in
            var card = HomeCard(scan: result)
            name = card.name
            value = card.barcodeValue
            format = card.format
            card.format = .qr
            draft = card
        } onError: { message in
            errorText = message
        }
    }
}

private extension HomeCard {
    var suggestedNameForForm: String {
        name.isEmpty ? "Thẻ nhà" : name
    }

    var suggestedValueForForm: String {
        barcodeValue.isEmpty ? uid.replacingOccurrences(of: ":", with: "") : barcodeValue
    }
}
