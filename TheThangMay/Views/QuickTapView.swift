import SwiftUI
import UIKit

/// Hiện mã toàn màn hình, tăng độ sáng tối đa để đầu đọc dễ quét.
struct QuickTapView: View {
    let card: HomeCard

    @Environment(\.dismiss) private var dismiss
    @State private var savedBrightness: CGFloat = UIScreen.main.brightness

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            VStack(spacing: 22) {
                Spacer(minLength: 12)

                Text(card.name)
                    .font(.headline)
                    .foregroundStyle(.black)

                if let image = BarcodeGenerator.image(for: card.displayValue, format: card.format, scale: 12) {
                    Image(uiImage: image)
                        .interpolation(.none)
                        .resizable()
                        .scaledToFit()
                        .padding(.horizontal, 24)
                } else {
                    Text("Chưa có mã để hiển thị")
                        .foregroundStyle(.gray)
                }

                Text(card.displayValue)
                    .font(.system(.body, design: .monospaced))
                    .foregroundStyle(.black)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)

                Text("Đưa màn hình vào đầu đọc · \(card.format.label)")
                    .font(.footnote)
                    .foregroundStyle(.gray)

                Spacer()

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
}
