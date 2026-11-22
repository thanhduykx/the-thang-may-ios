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

### Cách A — Codemagic (khuyến nghị, không cần Mac)

Project đã kèm `codemagic.yaml` với 3 workflow:

| Workflow | Dùng khi | Kết quả |
|---|---|---|
| **iOS — IPA chưa ký** | Chưa có tài khoản Apple Developer | `.ipa` để Sideloadly ký lại |
| **iOS — IPA có ký** | Có tài khoản Developer trả phí | `.ipa` cài trực tiếp, NFC chạy |
| **iOS — TestFlight** | Muốn cài qua TestFlight | Build đẩy lên App Store Connect |

**Bước 1 — đưa code lên GitHub:**

```bash
cd TheThangMay
git remote add origin https://github.com/<user>/<repo>.git
git push -u origin main
```

**Bước 2 — nối Codemagic:**

1. Vào [codemagic.io](https://codemagic.io) → đăng nhập bằng GitHub.
2. **Add application** → chọn repo vừa push.
3. Ở bước chọn cấu hình, chọn **codemagic.yaml** (đừng chọn Workflow Editor).
4. Bấm **Start new build** → chọn workflow **iOS — IPA chưa ký**.
5. Khoảng 4–6 phút → mở build → tab **Artifacts** → tải `TheThangMay-unsigned.ipa`.

Gói miễn phí của Codemagic: **500 phút macOS/tháng**, mỗi lần build ~5 phút.

**Bước 3 (tuỳ chọn) — bật NFC bằng bản có ký:**

1. **Teams → Integrations → App Store Connect** → **Add key**.
2. Nhập Issuer ID, Key ID và file `.p8` (tải từ App Store Connect → Users and Access → Keys).
3. Đặt tên integration đúng **`TheThangMayASC`** (khớp trong `codemagic.yaml`).
4. Chạy workflow **iOS — IPA có ký** → tải `.ipa` ở tab Artifacts.

> Lần đầu Codemagic có thể báo chưa có App ID / provisioning profile. Vào
> developer.apple.com tạo App ID `com.duong.thethangmay` (bật capability
> **NFC Tag Reading**) rồi chạy lại, hoặc đổi `bundle_identifier` trong
> `codemagic.yaml` cho khớp App ID bạn đã có.

**Cài IPA chưa ký lên iPhone:** dùng [Sideloadly](https://sideloadly.io/) — cắm iPhone,
kéo file `.ipa`, nhập Apple ID, Start. Sau đó vào Cài đặt → Cài đặt chung →
**VPN & Quản lý thiết bị** để tin cậy Apple ID.

> Apple ID miễn phí **không có entitlement NFC** → app mở được, nhập tay/xem mã được,
> nhưng bấm quét NFC sẽ báo lỗi. Muốn quét thẻ phải dùng bản **IPA có ký** với tài khoản
> Developer trả phí.

### Cách B — GitHub Actions

Đã kèm `.github/workflows/build-ipa.yml` (chưa ký) và `build-ipa-signed.yml` (có ký).

Repo → **Actions** → **Build IPA (unsigned)** → **Run workflow** → tải artifact
`TheThangMay-unsigned-ipa`.

Bản có ký cần 6 secret trong **Settings → Secrets and variables → Actions**:

| Secret | Nội dung |
|---|---|
| `BUILD_CERTIFICATE_BASE64` | file `.p12` (certificate Development), base64 |
| `P12_PASSWORD` | mật khẩu `.p12` |
| `PROVISIONING_PROFILE_BASE64` | file `.mobileprovision`, base64 |
| `PROVISIONING_PROFILE_NAME` | tên profile trong Apple Developer |
| `APPLE_TEAM_ID` | Team ID 10 ký tự |
| `KEYCHAIN_PASSWORD` | mật khẩu tạm bất kỳ |

Tạo base64 trên Windows:

```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes("cert.p12")) | Set-Clipboard
[Convert]::ToBase64String([IO.File]::ReadAllBytes("profile.mobileprovision")) | Set-Clipboard
```

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
