<#
  SynoHub Publish Script
  ─────────────────────────────────────────
  Builds the Flutter APK, uploads it to GitHub Releases,
  updates version.json, builds the website, and deploys
  to Cloudflare Pages — all in one command.

  Requires: gh CLI (https://cli.github.com/) logged in.

  Usage:
    .\publish.ps1                    # auto-increment patch (1.0.0 -> 1.0.1)
    .\publish.ps1 -Version "1.2.0"  # explicit version
    .\publish.ps1 -Notes "Bug fixes" # with release notes
#>

param(
    [string]$Version,
    [string]$Notes = ""
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$ghRepo = "duconmang/synohubs"

# ── 1. Determine version ────────────────────────────────────────
$versionJsonPath = Join-Path $root "..\synohubs.com\public\releases\version.json"
$currentJson = Get-Content $versionJsonPath -Raw | ConvertFrom-Json

if (-not $Version) {
    # Auto-increment: bump patch version
    $parts = $currentJson.version.Split('.')
    $parts[2] = [string]([int]$parts[2] + 1)
    $Version = $parts -join '.'
}
$buildNumber = $currentJson.buildNumber + 1
$tag = "v$Version"
$apkName = "SynoHubs-$Version.apk"

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "       SynoHub Publish Pipeline             " -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Version:      $Version (build $buildNumber)" -ForegroundColor White
Write-Host "  Tag:          $tag" -ForegroundColor White
Write-Host "  APK:          $apkName" -ForegroundColor White
Write-Host "  Release notes: $(if ($Notes) { $Notes } else { '(none)' })" -ForegroundColor Gray
Write-Host ""

# ── 2. Build Flutter APK ────────────────────────────────────────
Write-Host "[1/5] Building Flutter APK..." -ForegroundColor Yellow
Push-Location $root
try {
    flutter build apk --release --build-name=$Version --build-number=$buildNumber
    if ($LASTEXITCODE -ne 0) { throw "Flutter build failed" }
} finally {
    Pop-Location
}

$apkSource = Join-Path $root "build\app\outputs\flutter-apk\app-release.apk"
$sizeMB = [math]::Round((Get-Item $apkSource).Length / 1MB, 1)
Write-Host "  APK size: ${sizeMB}MB" -ForegroundColor Gray

# ── 3. Upload APK to GitHub Releases ────────────────────────────
Write-Host "[2/5] Uploading APK to GitHub Releases ($tag)..." -ForegroundColor Yellow
$apkDest = Join-Path $root "build\$apkName"
Copy-Item $apkSource $apkDest -Force

$releaseNotes = if ($Notes) { $Notes } else { "SynoHub $tag" }

# Delete existing release if any, then create new one
$ErrorActionPreference = "Continue"
gh release delete $tag --repo $ghRepo --yes 2>$null
$ErrorActionPreference = "Stop"
gh release create $tag $apkDest --repo $ghRepo --title "SynoHub $tag" --notes $releaseNotes
if ($LASTEXITCODE -ne 0) { throw "GitHub release failed" }
Write-Host "  Uploaded to github.com/$ghRepo/releases/tag/$tag" -ForegroundColor Gray

# ── 4. Update version.json ──────────────────────────────────────
Write-Host "[3/5] Updating version.json..." -ForegroundColor Yellow
$apkUrl = "https://github.com/$ghRepo/releases/download/$tag/$apkName"
$versionData = @{
    version      = $Version
    buildNumber  = $buildNumber
    apkUrl       = $apkUrl
    releaseNotes = if ($Notes) { $Notes } else { $currentJson.releaseNotes }
    minVersion   = $currentJson.minVersion
}
$versionData | ConvertTo-Json -Depth 5 | Set-Content $versionJsonPath -Encoding UTF8
Write-Host "  version.json updated -> $Version+$buildNumber" -ForegroundColor Gray

# ── 5. Build website ────────────────────────────────────────────
Write-Host "[4/5] Building website..." -ForegroundColor Yellow
Push-Location (Join-Path $root "..\synohubs.com")
try {
    npm run build
    if ($LASTEXITCODE -ne 0) { throw "Website build failed" }
} finally {
    Pop-Location
}

# ── 6. Deploy to Cloudflare Pages ───────────────────────────────
Write-Host "[5/5] Deploying to Cloudflare Pages..." -ForegroundColor Yellow
Push-Location $root
try {
    npx wrangler pages deploy ..\synohubs.com\dist --project-name synohubs --branch synohubs --commit-dirty=true
    if ($LASTEXITCODE -ne 0) { throw "Cloudflare deploy failed" }
} finally {
    Pop-Location
}

# ── Done ────────────────────────────────────────────────────────
Write-Host ""
Write-Host "============================================" -ForegroundColor Green
Write-Host " Published SynoHub $tag (build $buildNumber)" -ForegroundColor Green
Write-Host " Web: https://synohubs.com" -ForegroundColor Green
Write-Host " APK: $apkUrl" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Green
Write-Host ""
