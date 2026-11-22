import SwiftUI
import UIKit

/// Hiện UID thật to, nền trắng, sáng tối đa — để đọc/nhập sang app giả lập thẻ.
struct UIDDisplayView: View {
    let card: HomeCard

    @Environment(\.dismiss) private var dismiss
    @State private var savedBrightness: CGFloat = UIScreen.main.brightness
    @State private var copied = false

    private var plainUID: String {
        card.uid
            .replacingOccurrences(of: ":", with: "")
            .replacingOccurrences(of: " ", with: "")
            .uppercased()
    }

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            VStack(spacing: 16) {
                Spacer(minLength: 8)

                Text(card.name)
                    .font(.headline)
                    .foregroundStyle(.black)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)

                Text("UID THẺ")
                    .font(.caption.weight(.semibold))
                    .tracking(2)
                    .foregroundStyle(.gray)

                Text(plainUID.isEmpty ? "—" : grouped(plainUID))
                    .font(.system(size: 46, weight: .bold, design: .monospaced))
                    .foregroundStyle(.black)
                    .lineLimit(1)
                    .minimumScaleFactor(0.35)
                    .padding(.horizontal, 16)

                Text(plainUID.isEmpty ? "" : "Không dấu: \(plainUID)")
                    .font(.system(.subheadline, design: .monospaced))
                    .foregroundStyle(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)

                Button {
                    UIPasteboard.general.string = plainUID
                    copied = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        copied = false
                    }
                } label: {
                    Label(copied ? "Đã sao chép" : "Sao chép UID", systemImage: copied ? "checkmark" : "doc.on.doc")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color(hex: 0x0F766E))
                        .padding(.horizontal, 18)
                        .padding(.vertical, 10)
                        .background(Color(hex: 0x0EA5A4).opacity(0.14))
                        .clipShape(Capsule())
                }
                .disabled(plainUID.isEmpty)

                Spacer()

                Text("Thẻ: \(card.technology.label)\nDùng UID này cho app giả lập thẻ trên Android, hoặc ghi vào thẻ magic 1K.")
                    .font(.caption)
                    .foregroundStyle(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 28)

                Button {
                    dismiss()
                } label: {
                    Text("Xong")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [Color(hex: 0x0EA5A4), Color(hex: 0x0F766E)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(Capsule())
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
            }
        }
        .statusBarHidden()
        .onAppear {
            savedBrightness = UIScreen.main.brightness
            UIScreen.main.brightness = 1.0
            UIApplication.shared.isIdleTimerDisabled = true
        }
        .onDisappear {
            UIScreen.main.brightness = savedBrightness
            UIApplication.shared.isIdleTimerDisabled = false
        }
    }

    private func grouped(_ hex: String) -> String {
        stride(from: 0, to: hex.count, by: 2).map { offset -> String in
            let start = hex.index(hex.startIndex, offsetBy: offset)
            let end = hex.index(start, offsetBy: min(2, hex.count - offset))
            return String(hex[start..<end])
        }
        .joined(separator: ":")
    }
}
