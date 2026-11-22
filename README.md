# Thẻ Thang Máy — iOS app

App SwiftUI đọc thẻ nhà bằng NFC, lưu vào "ví" trong máy, hiện mã QR / Code 128 để quẹt,
và xuất pass sang Apple Wallet.

> Đọc thẻ bằng iPhone 18 Pro Max (hoặc bất kỳ iPhone nào từ iPhone 7 trở lên, iOS 17+).

---

## 1. Chạy app trong 5 phút

Yêu cầu: **macOS + Xcode 16 trở lên**.

1. Mở `TheThangMay.xcodeproj`.
2. Chọn target **TheThangMay** → tab **Signing & Capabilities**:
   - Chọn **Team** của bạn (Apple ID).
   - Đổi **Bundle Identifier** nếu Xcode báo trùng, ví dụ `com.tenban.thethangmay`.
   - Kiểm tra capability **Near Field Communication Tag Reading** đã có.
     (Project đã kèm sẵn file `TheThangMay.entitlements`.)
3. Cắm iPhone, chọn iPhone làm thiết bị đích, bấm **Run**.
4. Lần đầu bấm "Quét thẻ nhà", iOS sẽ hỏi quyền NFC → cho phép.

> **Quan trọng:** NFC **không chạy trên Simulator**, phải chạy trên iPhone thật.
> Đọc thẻ NFC cần tài khoản **Apple Developer có trả phí** (99 USD/năm).
> Với tài khoản miễn phí, app vẫn build được nhưng capability NFC có thể bị từ chối —
> khi đó dùng chức năng **Nhập mã bằng tay** để thử giao diện.

---

## 2. Cách dùng

| Thao tác | Ở đâu |
|---|---|
| Quét thẻ thật | Nút **Quét thẻ nhà** (hoặc dấu + → Quét thẻ NFC) |
| Nhập mã thẻ 125 kHz | Dấu + → **Nhập mã bằng tay** |
| Quẹt mã toàn màn hình | Mở thẻ → **Chế độ quẹt** (tự tăng sáng màn hình) |
| Đưa thẻ vào Apple Wallet | Mở thẻ → **Vào Wallet** (cần máy chủ ký pass, xem mục 4) |
| Xuất chẩn đoán thẻ | Cài đặt → **Xuất chẩn đoán thẻ** |

Màn hình "Quét thẻ" hiển thị **loại thẻ, UID, lỗi đọc, dump bộ nhớ** — nhờ đó bạn biết
được thẻ nhà thuộc loại nào mà không cần app khác.

---

## 3. Giới hạn thật của iPhone (đọc kỹ trước khi kỳ vọng)

| Việc | iPhone làm được? |
|---|---|
| Đọc UID thẻ MIFARE Classic | ✅ (chỉ UID) |
| Đọc dữ liệu thẻ MIFARE Classic | ❌ thiếu khoá Crypto1 |
| Đọc UID + dữ liệu Ultralight / NTAG | ✅ |
| Đọc ISO 15693 (ICODE) | ✅ |
| Đọc thẻ ID 125 kHz (thẻ dẹt) | ❌ khác tần số — phải nhập tay |
| **Giả lập thẻ để quẹt vào đầu đọc** | ❌ Apple không cho app làm việc này |
| Mở cửa bằng HomeKey | ⚠️ cần khoá/đầu đọc có chứng nhận Apple HomeKit |
| Apple Wallet pass có NFC | ⚠️ cần entitlement riêng do Apple duyệt |

**Kết luận thực tế:** nếu đầu đọc thang máy chỉ nhận thẻ vật lý thì không có app nào trên
App Store biến iPhone thành thẻ được. App này dùng được thật khi:

- đầu đọc có **camera/đầu quét QR** → dùng "Chế độ quẹt" hoặc Wallet pass, hoặc
- bạn chỉ cần **lưu và tra cứu** thông tin thẻ (UID, số thẻ, ghi chú).

Cách chắc chắn nhất cho đầu đọc chỉ quẹt thẻ: dùng ốp lưng có ngăn đựng thẻ, hoặc dán
sticker NFC đã được ghi đè (chỉ khi đầu đọc đọc được NTAG).

---

## 4. Đưa thẻ vào Apple Wallet (tuỳ chọn)

Apple Wallet chỉ nhận file `.pkpass` **đã ký** bằng chứng chỉ Pass Type ID. Vì vậy cần
một máy chủ nhỏ — project có sẵn trong `wallet-server/`.

### 4.1. Lấy chứng chỉ

1. Vào [developer.apple.com](https://developer.apple.com/account) → **Certificates, IDs & Profiles**.
2. **Identifiers → Pass Type IDs** → tạo mới, ví dụ `pass.com.tenban.thethangmay.card`.
3. Tạo **Certificate** cho Pass Type ID đó, tải về, double-click để thêm vào Keychain.
4. Trong **Keychain Access**, chuột phải chứng chỉ → **Export** → lưu `pass.p12` (đặt mật khẩu).
5. Tải **Apple WWDR G4** tại [Apple PKI](https://www.apple.com/certificateauthority/) (file `.cer`).

Chuyển sang PEM:

```bash
openssl pkcs12 -in pass.p12 -clobber -legacy -nodes -out all.pem
openssl x509 -in all.pem -out signerCert.pem
openssl pkey -in all.pem -out signerKey.pem
openssl x509 -inform der -in AppleWWDRCAG4.cer -out wwdr.pem
```

Đặt 3 file `wwdr.pem`, `signerCert.pem`, `signerKey.pem` vào `wallet-server/certs/`.

### 4.2. Chạy máy chủ

```bash
cd wallet-server
npm install
npm start
# http://localhost:3000/pass?code=TEST
```

Đưa lên Internet (Cloudflare Tunnel, VPS, Render…) để iPhone gọi được, rồi mở app:

**Cài đặt → Máy chủ ký pass Apple Wallet** → dán URL, ví dụ
`https://wallet.example.com/pass`.

Sau đó mở thẻ → **Vào Wallet** → iOS hỏi "Thêm vào Wallet" → xong.

---

## 5. Lỗi thường gặp

| Lỗi | Nguyên nhân / cách sửa |
|---|---|
| "Máy này không hỗ trợ quét NFC" | Chạy trên Simulator, hoặc máy cũ hơn iPhone 7 |
| "Missing required entitlement" | Chưa bật NFC Tag Reading, hoặc dùng Apple ID miễn phí |
| Quét mà không thấy thẻ | Đưa phần **trên cùng** iPhone sát thẻ, tháo ốp lưng dày/kim loại |
| Đọc được UID nhưng không có dữ liệu | Thẻ MIFARE Classic — bình thường, iPhone chỉ đọc UID |
| Wallet báo "pass không hợp lệ" | Chứng chỉ sai, thiếu `wwdr.pem`, hoặc serialNumber trùng |
| Camera không quét được mã | Tăng độ sáng (app tự làm), hoặc đổi QR ↔ Code 128 |

---

## 6. Cấu trúc project

```
TheThangMay/
├── TheThangMay.xcodeproj
├── TheThangMay/
│   ├── TheThangMayApp.swift
│   ├── TheThangMay.entitlements      # quyền NFC
│   ├── Models/
│   │   ├── HomeCard.swift            # dữ liệu thẻ, loại thẻ, bảng màu
│   │   └── CardStore.swift           # lưu/đọc JSON
│   ├── NFC/NFCScanner.swift          # CoreNFC + chẩn đoán thẻ
│   ├── Support/
│   │   ├── BarcodeGenerator.swift    # QR / Code 128
│   │   ├── WalletService.swift       # gọi máy chủ .pkpass
│   │   └── Extensions.swift
│   ├── Views/                        # Home, Detail, Editor, Scan, QuickTap, Settings
│   └── Assets.xcassets
└── wallet-server/                    # Node.js ký pass cho Apple Wallet
```

---

## 7. Xuất file `.ipa`

### Cách A — GitHub Actions (không cần Mac, miễn phí)

Đã kèm sẵn workflow `.github/workflows/build-ipa.yml`.

```bash
cd TheThangMay
git init
git add .
git commit -m "Thẻ Thang Máy iOS app"
git branch -M main
git remote add origin https://github.com/<user>/<repo>.git
git push -u origin main
```

1. Vào repo → tab **Actions** → **Build IPA (unsigned)** → **Run workflow**.
2. Khoảng 3–5 phút, tải artefact **TheThangMay-unsigned-ipa** → giải nén được
   `TheThangMay-unsigned.ipa`.

**IPA chưa ký thì cài thế nào?** Dùng **Sideloadly** hoặc **AltStore** trên PC/Mac để
ký lại bằng Apple ID của bạn rồi cài lên iPhone:

1. Cài [Sideloadly](https://sideloadly.io/), cắm iPhone, chọn file `.ipa`, nhập Apple ID.
2. Trên iPhone: Cài đặt → Cài đặt chung → VPN & Quản lý thiết bị → tin cậy Apple ID.
3. Mở app. Lưu ý: tài khoản **miễn phí** không có quyền NFC → chỉ dùng được phần
   nhập tay/xem mã; muốn quét NFC cần tài khoản Developer trả phí.

### Cách B — IPA có ký sẵn (cài trực tiếp, NFC hoạt động)

Dùng `.github/workflows/build-ipa-signed.yml`. Thêm 6 secret trong
**Settings → Secrets and variables → Actions**:

| Secret | Nội dung |
|---|---|
| `BUILD_CERTIFICATE_BASE64` | file `.p12` (certificate Development) mã hoá base64 |
| `P12_PASSWORD` | mật khẩu `.p12` |
| `PROVISIONING_PROFILE_BASE64` | file `.mobileprovision` mã hoá base64 |
| `PROVISIONING_PROFILE_NAME` | tên profile, ví dụ `TheThangMay Development` |
| `APPLE_TEAM_ID` | Team ID 10 ký tự |
| `KEYCHAIN_PASSWORD` | mật khẩu tạm bất kỳ |

Tạo base64 trên Windows:

```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes("cert.p12")) | Set-Clipboard
[Convert]::ToBase64String([IO.File]::ReadAllBytes("profile.mobileprovision")) | Set-Clipboard
```

Chạy workflow **Build IPA (signed)** → tải `TheThangMay-ipa`.

> Provisioning profile phải có **iPhone của bạn trong danh sách thiết bị** và bật
> capability **NFC Tag Reading**.

### Cách C — Có Mac

```bash
chmod +x scripts/build-ipa.sh
./scripts/build-ipa.sh
# → dist/TheThangMay-unsigned.ipa
```

Hoặc mở Xcode → Product → Archive → Distribute App.

---

## 8. Chưa có Mac?

Bạn đang dùng Windows nên cần một trong các cách sau để build:

1. **Mượn Mac** 10 phút: mở Xcode, chọn Team, Run (đơn giản nhất).
2. **Mac thuê theo giờ** (MacStadium, MacinCloud…) — cài Xcode từ App Store.
3. **GitHub Actions** (miễn phí cho repo public): runner `macos-15`, bước build:

```yaml
name: build
on: [push, workflow_dispatch]
jobs:
  ios:
    runs-on: macos-15
    steps:
      - uses: actions/checkout@v4
      - run: xcodebuild -project TheThangMay/TheThangMay.xcodeproj \
               -scheme TheThangMay -sdk iphoneos \
               -configuration Debug CODE_SIGNING_ALLOWED=NO build
```

4. **Codemagic / Bitrise** — có gói miễn phí, build ra file .ipa để cài qua TestFlight.

Nếu `TheThangMay.xcodeproj` báo lỗi khi mở, chạy `xcodegen generate` trong thư mục
`TheThangMay/` (đã kèm `project.yml`) để tạo lại project.

---

## 9. Ghi chú kỹ thuật

- Deployment target: **iOS 17.0**.
- NFC entitlement: `com.apple.developer.nfc.readersession.formats = [TAG]`.
- Polling: `iso14443` (MIFARE) và `iso15693` (ICODE).
- Muốn đọc thẻ ISO 7816 sâu hơn: thêm `com.apple.developer.nfc.readersession.iso7816.select-identifiers`
  vào Info.plist với AID của toà nhà.
- Muốn đọc FeliCa: thêm `com.apple.developer.nfc.readersession.felica.systemcodes` và
  bật `.iso18092` trong `NFCScanner.start()`.
