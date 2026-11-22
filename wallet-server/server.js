/**
 * Máy chủ ký pass Apple Wallet cho app "Thẻ Thang Máy".
 *
 * App gọi: GET /pass?name=...&code=...&format=qr|code128
 * Trả về: file .pkpass (đã ký) để iOS mở bằng Wallet.
 *
 * Chuẩn bị:
 *   wallet-server/certs/wwdr.pem
 *   wallet-server/certs/signerCert.pem
 *   wallet-server/certs/signerKey.pem       (khoá riêng, không mật khẩu)
 *   wallet-server/assets/icon.png ...       (đã kèm sẵn)
 *
 * Chạy:  npm install && npm start
 */

const express = require("express");
const fs = require("fs");
const path = require("path");
const { PKPass } = require("passkit-generator");

const app = express();
const PORT = process.env.PORT || 3000;

const certsDir = path.join(__dirname, "certs");
const assetsDir = path.join(__dirname, "assets");

function readIfExists(file) {
  return fs.existsSync(file) ? fs.readFileSync(file) : null;
}

function loadFiles() {
  const files = {};
  if (fs.existsSync(assetsDir)) {
    for (const name of fs.readdirSync(assetsDir)) {
      files[name] = fs.readFileSync(path.join(assetsDir, name));
    }
  }
  return files;
}

app.get("/pass", (req, res) => {
  try {
    const name = String(req.query.name || "Thẻ nhà").slice(0, 40);
    const code = String(req.query.code || "").trim();
    const isCode128 = String(req.query.format || "qr") === "code128";

    if (!code) {
      return res.status(400).send("Thiếu tham số ?code=");
    }

    const certificates = {
      wwdr: readIfExists(path.join(certsDir, "wwdr.pem")),
      signerCert: readIfExists(path.join(certsDir, "signerCert.pem")),
      signerKey: readIfExists(path.join(certsDir, "signerKey.pem")),
      signerKeyPassphrase: process.env.PASS_PHRASE || undefined,
    };

    if (!certificates.wwdr || !certificates.signerCert || !certificates.signerKey) {
      return res
        .status(500)
        .send("Thiếu chứng chỉ trong wallet-server/certs (xem README.md).");
    }

    const pass = new PKPass(loadFiles(), certificates, {});

    pass.type = "generic";
    pass.organizationName = "Thẻ Thang Máy";
    pass.description = name;
    pass.serialNumber = `${code}-${Date.now()}`;
    pass.logoText = "Thẻ Thang Máy";
    pass.backgroundColor = "rgb(15,118,110)";
    pass.foregroundColor = "rgb(255,255,255)";
    pass.labelColor = "rgb(204,251,241)";

    pass.primaryFields.push({
      key: "name",
      label: "THẺ",
      value: name,
    });

    pass.secondaryFields.push({
      key: "code",
      label: "MÃ",
      value: code,
    });

    pass.barcodes = [
      {
        format: isCode128 ? "PKBarcodeFormatCode128" : "PKBarcodeFormatQR",
        message: code,
        messageEncoding: "iso-8859-1",
        altText: code,
      },
    ];

    const buffer = pass.getAsBuffer();
    res.set("Content-Type", "application/vnd.apple.pkpass");
    res.set(
      "Content-Disposition",
      `attachment; filename="${encodeURIComponent(name)}.pkpass"`
    );
    res.send(buffer);
  } catch (error) {
    console.error(error);
    res.status(500).send(String(error.message || error));
  }
});

app.get("/", (req, res) => {
  res.send("Thẻ Thang Máy wallet server đang chạy. Dùng /pass?code=...");
});

app.listen(PORT, () => {
  console.log(`Wallet server: http://localhost:${PORT}/pass?code=TEST`);
});
