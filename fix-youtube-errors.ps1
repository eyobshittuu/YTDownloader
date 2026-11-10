# YouTube Downloader Fix Script
# Resolves 429/403 errors from YouTube

Write-Host "================================" -ForegroundColor Cyan
Write-Host "YouTube Downloader Error Fix" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan
Write-Host ""

# Step 1: Update yt-dlp
Write-Host "[1/3] Updating yt-dlp to latest version..." -ForegroundColor Yellow

$hasPython = Get-Command python -ErrorAction SilentlyContinue
if ($hasPython) {
    Write-Host "   Found Python, updating via pip..." -ForegroundColor Gray
    python -m pip install --upgrade yt-dlp
    if ($LASTEXITCODE -eq 0) {
        Write-Host "   yt-dlp updated successfully!" -ForegroundColor Green
    } else {
        Write-Host "   Warning: Could not update yt-dlp via pip" -ForegroundColor Red
    }
} else {
    Write-Host "   Python not found. Please install Python or download yt-dlp.exe manually" -ForegroundColor Red
    Write-Host "   Download from: https://github.com/yt-dlp/yt-dlp/releases" -ForegroundColor Yellow
}

Write-Host ""

# Step 2: Check for cookies
Write-Host "[2/3] Checking for cookies.txt..." -ForegroundColor Yellow
$cookiesFile = Join-Path $PSScriptRoot "cookies.txt"

if (Test-Path $cookiesFile) {
    Write-Host "   Found cookies.txt!" -ForegroundColor Green
    $cookiesSize = (Get-Item $cookiesFile).Length
    Write-Host "   File size: $cookiesSize bytes" -ForegroundColor Gray
} else {
    Write-Host "   No cookies.txt found" -ForegroundColor Yellow
    Write-Host "   To fix 429/403 errors, you need to add YouTube cookies" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "   How to get cookies:" -ForegroundColor Cyan
    Write-Host "   1. Install browser extension 'Get cookies.txt LOCALLY'" -ForegroundColor White
    Write-Host "   2. Log into YouTube in your browser" -ForegroundColor White
    Write-Host "   3. Export cookies for youtube.com" -ForegroundColor White
    Write-Host "   4. Save as 'cookies.txt' in this directory" -ForegroundColor White
}

Write-Host ""

# Step 3: Test configuration
Write-Host "[3/3] Testing yt-dlp configuration..." -ForegroundColor Yellow

$testUrl = "https://www.youtube.com/watch?v=jNQXAC9IVRw"  # "Me at the zoo" - first YouTube video
$testArgs = @("--dump-json", "--no-playlist", $testUrl)

if (Test-Path $cookiesFile) {
    $testArgs = @("--cookies", $cookiesFile) + $testArgs
}

try {
    if ($hasPython) {
        $result = python -m yt_dlp $testArgs 2>&1
    } else {
        $ytdlpExe = "yt-dlp"
        $result = & $ytdlpExe $testArgs 2>&1
    }
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "   Test successful! yt-dlp is working correctly" -ForegroundColor Green
    } else {
        Write-Host "   Test failed. Error output:" -ForegroundColor Red
        Write-Host $result -ForegroundColor Gray
    }
} catch {
    Write-Host "   Could not run yt-dlp test" -ForegroundColor Red
    Write-Host "   Error: $_" -ForegroundColor Gray
}

Write-Host ""
Write-Host "================================" -ForegroundColor Cyan
Write-Host "Next Steps:" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan
Write-Host "1. If you don't have cookies.txt, create one (see instructions above)" -ForegroundColor White
Write-Host "2. Restart your server: npm start" -ForegroundColor White
Write-Host "3. Read YOUTUBE_AUTH_SETUP.md for detailed instructions" -ForegroundColor White
Write-Host ""
