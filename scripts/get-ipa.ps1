# Chạy workflow build IPA trên GitHub Actions, chờ xong rồi tải .ipa về máy.
# Dùng:  pwsh -File scripts\get-ipa.ps1
param(
    [string]$Repo = "thanhduykx/the-thang-may-ios",
    [string]$Workflow = "build-ipa.yml",
    [string]$Artifact = "TheThangMay-unsigned-ipa"
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

Write-Host "==> Kích hoạt build trên $Repo" -ForegroundColor Cyan
gh workflow run $Workflow --repo $Repo
Start-Sleep -Seconds 8

Write-Host "==> Tìm run vừa tạo"
$runId = (gh run list --repo $Repo --workflow $Workflow --limit 1 --json databaseId --jq '.[0].databaseId').Trim()
if (-not $runId) { throw "Không lấy được run id" }
Write-Host "    run: $runId"

Write-Host "==> Chờ build (khoảng 4-6 phút)..." -ForegroundColor Cyan
gh run watch $runId --repo $Repo --exit-status
if ($LASTEXITCODE -ne 0) { throw "Build thất bại — xem: https://github.com/$Repo/actions/runs/$runId" }

Write-Host "==> Tải artifact"
if (Test-Path dist) { Remove-Item -Recurse -Force dist }
New-Item -ItemType Directory -Path dist | Out-Null
gh run download $runId --repo $Repo -n $Artifact -D dist

Get-ChildItem dist -Filter *.zip | ForEach-Object {
    Expand-Archive -LiteralPath $_.FullName -DestinationPath dist -Force
    Remove-Item $_.FullName
}

$ipa = Get-ChildItem dist -Recurse -Filter *.ipa | Select-Object -First 1
if (-not $ipa) { throw "Không thấy file .ipa trong artifact" }

Write-Host ""
Write-Host "==> XONG: $($ipa.FullName)" -ForegroundColor Green
Write-Host "==> Cài bằng Sideloadly (sideloadly.io) rồi tin cậy Apple ID trên iPhone." -ForegroundColor Green
