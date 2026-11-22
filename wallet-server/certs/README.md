# Chứng chỉ ký pass

Đặt 3 file PEM vào thư mục này trước khi chạy `npm start`:

| File | Nội dung |
|---|---|
| `wwdr.pem` | Apple WWDR G4 (tải tại https://www.apple.com/certificateauthority/) |
| `signerCert.pem` | Chứng chỉ Pass Type ID của bạn (PEM) |
| `signerKey.pem` | Khoá riêng tương ứng (PEM, không mật khẩu) |

Cách chuyển từ file `.p12`:

```bash
openssl pkcs12 -in pass.p12 -clobber -legacy -nodes -out all.pem
openssl x509 -in all.pem -out signerCert.pem
openssl pkey -in all.pem -out signerKey.pem
openssl x509 -inform der -in AppleWWDRCAG4.cer -out wwdr.pem
```

Nếu khoá có mật khẩu, chạy server với biến môi trường `PASS_PHRASE=matkhau`.
