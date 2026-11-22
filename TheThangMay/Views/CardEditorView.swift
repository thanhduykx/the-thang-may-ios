import SwiftUI
import UIKit

/// Form thêm / sửa thẻ.
struct CardEditorView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var draft: HomeCard
    private let saveTitle: String
    private let isNew: Bool
    var onSave: (HomeCard) -> Void

    init(card: HomeCard?, saveTitle: String = "Lưu", onSave: @escaping (HomeCard) -> Void) {
        _draft = State(initialValue: card ?? HomeCard(name: "", barcodeValue: ""))
        self.saveTitle = saveTitle
        self.isNew = card == nil
        self.onSave = onSave
    }

    private var title: String {
        isNew ? "Thêm thẻ" : "Sửa thẻ"
    }

    private var canSave: Bool {
        !draft.name.trimmingCharacters(in: .whitespaces).isEmpty &&
        !draft.barcodeValue.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        Form {
            Section("Thông tin thẻ") {
                TextField("Tên thẻ (VD: Thẻ thang máy)", text: $draft.name)
                TextField("Mã / UID in trên thẻ", text: $draft.barcodeValue)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                    .font(.body.monospaced())
                Picker("Kiểu mã", selection: $draft.format) {
                    ForEach(BarcodeFormat.allCases) { format in
                        Text(format.label).tag(format)
                    }
                }
                Picker("Loại thẻ", selection: $draft.technology) {
                    ForEach(CardTechnology.allCases) { tech in
                        Text(tech.label).tag(tech)
                    }
                }
            }

            Section {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(0..<CardPalette.gradients.count, id: \.self) { index in
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: CardPalette.gradient(for: index),
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .frame(width: 36, height: 36)
                                .overlay(
                                    Circle()
                                        .strokeBorder(.primary, lineWidth: draft.colorIndex == index ? 2.5 : 0)
                                        .padding(-3)
                                )
                                .onTapGesture {
                                    draft.colorIndex = index
                                }
                        }
                    }
                    .padding(.vertical, 4)
                }
            } header: {
                Text("Màu thẻ")
            }

            Section("Ghi chú") {
                TextField("Ví dụ: thẻ tầng 12, hết hạn 2027…", text: $draft.note, axis: .vertical)
                    .lineLimit(2...5)
            }

            Section("Xem trước") {
                HStack {
                    Spacer()
                    if let image = BarcodeGenerator.image(for: draft.barcodeValue, format: draft.format, scale: 8) {
                        Image(uiImage: image)
                            .interpolation(.none)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 140)
                            .padding(12)
                            .background(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    } else {
                        Text("Nhập mã để xem trước")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .listRowBackground(Color.clear)
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Huỷ") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button(saveTitle) {
                    onSave(draft)
                    dismiss()
                }
                .disabled(!canSave)
            }
        }
    }
}

#Preview {
    NavigationStack {
        CardEditorView(card: HomeCard.samples[0]) { _ in }
    }
}
