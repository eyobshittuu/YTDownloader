# YouTube Cookies Setup Script for Windows

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  YouTube Cookies Setup" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "⚠️  IMPORTANT: YouTube now REQUIRES cookies!" -ForegroundColor Yellow
Write-Host ""
Write-Host "Without cookies, you'll get 403 Forbidden errors on ALL requests." -ForegroundColor Red
Write-Host "With cookies, 99%+ of videos work perfectly." -ForegroundColor Green
Write-Host ""

# Check if cookies.txt already exists
$cookiesPath = Join-Path $PSScriptRoot "cookies.txt"
if (Test-Path $cookiesPath) {
    Write-Host "✓ Found existing cookies.txt" -ForegroundColor Green
    $fileSize = (Get-Item $cookiesPath).Length
    Write-Host "  File size: $fileSize bytes" -ForegroundColor Gray
    Write-Host ""
    
    $response = Read-Host "Cookies file exists. Test it? (y/n)"
    if ($response -eq 'y' -or $response -eq 'Y') {
        Write-Host ""
        Write-Host "Testing cookies..." -ForegroundColor Yellow
        
        # Test with yt-dlp
        try {
            $testUrl = "https://www.youtube.com/watch?v=jNQXAC9IVRw"
            
            # Try Python module first
            $hasPython = Get-Command python -ErrorAction SilentlyContinue
            if ($hasPython) {
                Write-Host "Running: python -m yt_dlp --cookies cookies.txt --dump-json $testUrl" -ForegroundColor Gray
                $result = python -m yt_dlp --cookies $cookiesPath --dump-json $testUrl 2>&1
                
                if ($LASTEXITCODE -eq 0) {
                    $json = $result | ConvertFrom-Json
                    Write-Host ""
                    Write-Host "✓ SUCCESS! Cookies are working!" -ForegroundColor Green
                    Write-Host ""
                    Write-Host "Video Title: $($json.title)" -ForegroundColor White
                    Write-Host "Duration: $($json.duration) seconds" -ForegroundColor White
                    Write-Host ""
                    Write-Host "Your YouTube downloader should work now!" -ForegroundColor Green
                    exit 0
                } else {
                    Write-Host ""
                    Write-Host "✗ Cookies test FAILED" -ForegroundColor Red
                    Write-Host $result -ForegroundColor Gray
                    Write-Host ""
                    Write-Host "Your cookies may be expired or invalid." -ForegroundColor Yellow
                }
            }
        } catch {
            Write-Host "Could not test cookies: $_" -ForegroundColor Red
        }
    }
    Write-Host ""
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  How to Get YouTube Cookies" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Step 1: Install Browser Extension" -ForegroundColor Yellow
Write-Host ""
Write-Host "Chrome/Edge users:" -ForegroundColor White
Write-Host "  https://chrome.google.com/webstore/detail/get-cookiestxt-locally/cclelndahbckbenkjhflpdbgdldlbecc" -ForegroundColor Cyan
Write-Host ""
Write-Host "Firefox users:" -ForegroundColor White
Write-Host "  https://addons.mozilla.org/en-US/firefox/addon/cookies-txt/" -ForegroundColor Cyan
Write-Host ""

Write-Host "Step 2: Log into YouTube" -ForegroundColor Yellow
Write-Host "  1. Open youtube.com in your browser" -ForegroundColor White
Write-Host "  2. Sign in with your Google account" -ForegroundColor White
Write-Host "  3. Watch any video to confirm you're logged in" -ForegroundColor White
Write-Host ""

Write-Host "Step 3: Export Cookies" -ForegroundColor Yellow
Write-Host "  1. Click the extension icon in your browser" -ForegroundColor White
Write-Host "  2. Select 'youtube.com' from the dropdown" -ForegroundColor White
Write-Host "  3. Click 'Export' or 'Download'" -ForegroundColor White
Write-Host "  4. Save as 'cookies.txt' in this directory:" -ForegroundColor White
Write-Host "     $PSScriptRoot" -ForegroundColor Cyan
Write-Host ""

Write-Host "Step 4: Verify Cookie Format" -ForegroundColor Yellow
Write-Host "  Open cookies.txt and verify it looks like this:" -ForegroundColor White
Write-Host ""
Write-Host "  # Netscape HTTP Cookie File" -ForegroundColor Gray
Write-Host "  .youtube.com" -NoNewline -ForegroundColor Gray
Write-Host "  TRUE  /  TRUE  1735689600  CONSENT  YES+..." -ForegroundColor Gray
Write-Host "  .youtube.com" -NoNewline -ForegroundColor Gray
Write-Host "  TRUE  /  TRUE  1735689600  __Secure-1PSID  ..." -ForegroundColor Gray
Write-Host ""

Write-Host "Step 5: Test Your Server" -ForegroundColor Yellow
Write-Host "  npm start" -ForegroundColor Cyan
Write-Host ""

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Quick Links" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Browser Extension (Chrome/Edge):" -ForegroundColor White
$chromeUrl = "https://chrome.google.com/webstore/detail/get-cookiestxt-locally/cclelndahbckbenkjhflpdbgdldlbecc"
Write-Host $chromeUrl -ForegroundColor Cyan
Write-Host ""

$openBrowser = Read-Host "Open browser extension page now? (y/n)"
if ($openBrowser -eq 'y' -or $openBrowser -eq 'Y') {
    Start-Process $chromeUrl
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "After you export cookies, run this script again to test them!" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
