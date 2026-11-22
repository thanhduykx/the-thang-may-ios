import SwiftUI

struct WalletCardView: View {
    let card: HomeCard

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(card.name)
                        .font(.headline)
                        .foregroundStyle(.white)
                        .lineLimit(2)
                    Text(card.technology.shortLabel)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.75))
                }
                Spacer(minLength: 8)
                Image(systemName: card.technology.symbol)
                    .font(.title3)
                    .foregroundStyle(.white.opacity(0.9))
            }

            Spacer(minLength: 20)

            Text(card.displayValue)
                .font(.system(.footnote, design: .monospaced))
                .foregroundStyle(.white.opacity(0.95))
                .lineLimit(1)
                .minimumScaleFactor(0.55)

            HStack(spacing: 6) {
                Image(systemName: "qrcode")
                    .font(.caption2)
                Text(card.format.label)
                    .font(.caption2)
            }
            .foregroundStyle(.white.opacity(0.7))
            .padding(.top, 4)
        }
        .padding(20)
        .frame(height: 172)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: CardPalette.gradient(for: card.colorIndex),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(.white.opacity(0.16), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.14), radius: 12, x: 0, y: 6)
    }
}

#Preview {
    VStack(spacing: 16) {
        WalletCardView(card: HomeCard.samples[0])
        WalletCardView(card: HomeCard.samples[1])
    }
    .padding()
}
