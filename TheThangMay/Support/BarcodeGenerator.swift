import UIKit
import CoreImage
import CoreImage.CIFilterBuiltins

/// Tạo ảnh QR / Code 128 từ chuỗi.
enum BarcodeGenerator {
    private static let context = CIContext(options: nil)

    static func image(for value: String,
                      format: BarcodeFormat,
                      scale: CGFloat = 12) -> UIImage? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        let output: CIImage?
        switch format {
        case .qr:
            let filter = CIFilter.qrCodeGenerator()
            filter.message = Data(trimmed.utf8)
            filter.correctionLevel = "M"
            output = filter.outputImage
        case .code128:
            let filter = CIFilter.code128BarcodeGenerator()
            filter.message = Data(trimmed.utf8)
            filter.quietSpace = 2
            output = filter.outputImage
        }

        guard let image = output else { return nil }
        let scaled = image.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
        guard let cgImage = context.createCGImage(scaled, from: scaled.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }
}
