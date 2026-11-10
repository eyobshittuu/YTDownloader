# Test Render Deployment Script

param(
    [string]$renderUrl = "https://ytdownloader-rq53.onrender.com"
)

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "  Render Deployment Diagnostic Test" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# Test URL
$testVideoUrl = "https://www.youtube.com/watch?v=jNQXAC9IVRw"
$videoId = "jNQXAC9IVRw"

Write-Host "Testing Render deployment at:" -ForegroundColor Yellow
Write-Host "  $renderUrl" -ForegroundColor White
Write-Host ""

# Test 1: Health Check
Write-Host "[Test 1/4] Health Check..." -ForegroundColor Yellow
try {
    $healthUrl = "$renderUrl/api/health"
    Write-Host "  GET $healthUrl" -ForegroundColor Gray
    
    $response = Invoke-RestMethod -Uri $healthUrl -Method Get -TimeoutSec 30
    
    Write-Host "  ✓ Service is running" -ForegroundColor Green
    Write-Host "  Version: $($response.version)" -ForegroundColor Gray
    Write-Host "  Uptime: $([math]::Round($response.uptime, 2)) seconds" -ForegroundColor Gray
    
    if ($response.hasCookiesEnv) {
        Write-Host "  ✓ YOUTUBE_COOKIES environment variable detected" -ForegroundColor Green
        Write-Host "  Cookie length: $($response.cookiesLength) bytes" -ForegroundColor Gray
        
        if ($response.cookiesLength -lt 500) {
            Write-Host "  ⚠ WARNING: Cookies seem too short (< 500 bytes)" -ForegroundColor Yellow
            Write-Host "    A complete cookies.txt is usually 1000-5000 bytes" -ForegroundColor Yellow
        }
    } else {
        Write-Host "  ✗ NO COOKIES FOUND in environment!" -ForegroundColor Red
        Write-Host "    Add YOUTUBE_COOKIES environment variable in Render" -ForegroundColor Yellow
    }
    
} catch {
    Write-Host "  ✗ Health check failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    Write-Host "Is your Render service running?" -ForegroundColor Yellow
    exit 1
}

Write-Host ""

# Test 2: Cookie Debug Endpoint
Write-Host "[Test 2/4] Cookie Configuration Check..." -ForegroundColor Yellow
try {
    $debugUrl = "$renderUrl/api/debug-cookies"
    Write-Host "  GET $debugUrl" -ForegroundColor Gray
    
    $cookieInfo = Invoke-RestMethod -Uri $debugUrl -Method Get -TimeoutSec 30
    
    if ($cookieInfo.exists) {
        Write-Host "  ✓ Cookie file created on server" -ForegroundColor Green
        Write-Host "  Size: $($cookieInfo.size) bytes" -ForegroundColor Gray
        Write-Host "  Lines: $($cookieInfo.linesCount)" -ForegroundColor Gray
        
        if ($cookieInfo.hasYoutubeDomain) {
            Write-Host "  ✓ Contains youtube.com cookies" -ForegroundColor Green
        } else {
            Write-Host "  ✗ No youtube.com cookies found!" -ForegroundColor Red
        }
        
        if ($cookieInfo.sampleDomains -and $cookieInfo.sampleDomains.Count -gt 0) {
            Write-Host "  Sample domains: $($cookieInfo.sampleDomains -join ', ')" -ForegroundColor Gray
        }
    } else {
        Write-Host "  ✗ No cookie file on server" -ForegroundColor Red
        if ($cookieInfo.hasEnv) {
            Write-Host "  Environment variable exists but file wasn't created" -ForegroundColor Yellow
            Write-Host "  Check Render logs for cookie parsing errors" -ForegroundColor Yellow
        }
    }
    
} catch {
    Write-Host "  ⚠ Could not check cookie debug info" -ForegroundColor Yellow
}

Write-Host ""

# Test 3: Video Info Extraction
Write-Host "[Test 3/4] Video Info API Test..." -ForegroundColor Yellow
Write-Host "  Testing with video: $videoId" -ForegroundColor Gray

try {
    $infoUrl = "$renderUrl/api/info"
    $body = @{ url = $testVideoUrl } | ConvertTo-Json
    
    Write-Host "  POST $infoUrl" -ForegroundColor Gray
    
    $result = Invoke-RestMethod -Uri $infoUrl -Method Post -Body $body -ContentType "application/json" -TimeoutSec 60
    
    if ($result.success) {
        Write-Host "  ✓ ✓ ✓ SUCCESS! Video info extracted!" -ForegroundColor Green
        Write-Host ""
        Write-Host "  Video Title: $($result.data.title)" -ForegroundColor White
        Write-Host "  Duration: $($result.data.durationFormatted)" -ForegroundColor White
        Write-Host "  Channel: $($result.data.channel)" -ForegroundColor White
        Write-Host "  Views: $($result.data.viewCountFormatted)" -ForegroundColor White
        Write-Host ""
        Write-Host "  ✓ Your Render deployment is WORKING!" -ForegroundColor Green
        
    } else {
        Write-Host "  ✗ Request failed but no error thrown" -ForegroundColor Red
    }
    
} catch {
    $errorMessage = $_.Exception.Message
    Write-Host "  ✗ FAILED: Video info extraction failed" -ForegroundColor Red
    Write-Host ""
    
    # Try to parse error response
    try {
        $errorResponse = $_.ErrorDetails.Message | ConvertFrom-Json
        Write-Host "  Error: $($errorResponse.error)" -ForegroundColor Red
        
        # Check for specific errors
        if ($errorResponse.error -match "403|Forbidden") {
            Write-Host ""
            Write-Host "  ❌ 403 Forbidden Error = Cookie Problem" -ForegroundColor Yellow
            Write-Host ""
            Write-Host "  Possible causes:" -ForegroundColor White
            Write-Host "  1. Cookies are incomplete (only header comments)" -ForegroundColor Gray
            Write-Host "  2. Cookies are expired (need fresh export)" -ForegroundColor Gray
            Write-Host "  3. Cookies are from logged-out session" -ForegroundColor Gray
            Write-Host "  4. Cookie format is wrong (not Netscape format)" -ForegroundColor Gray
            
        } elseif ($errorResponse.error -match "429|Too Many Requests") {
            Write-Host ""
            Write-Host "  ⚠ 429 Rate Limit = Temporary YouTube Block" -ForegroundColor Yellow
            Write-Host "  Wait 10-15 minutes and try again" -ForegroundColor White
            
        } elseif ($errorResponse.error -match "Failed to extract") {
            Write-Host ""
            Write-Host "  ❌ Extraction Failed = Cookies + yt-dlp Issue" -ForegroundColor Yellow
            Write-Host ""
            Write-Host "  Possible causes:" -ForegroundColor White
            Write-Host "  1. yt-dlp needs updating (check Render build logs)" -ForegroundColor Gray
            Write-Host "  2. Cookies are invalid" -ForegroundColor Gray
        }
        
    } catch {
        Write-Host "  Raw error: $errorMessage" -ForegroundColor Gray
    }
}

Write-Host ""

# Test 4: Download Initialization
Write-Host "[Test 4/4] Download Job Test..." -ForegroundColor Yellow

try {
    $downloadUrl = "$renderUrl/api/download"
    $body = @{
        url = $testVideoUrl
        format = "mp4"
        quality = "720"
        isAudioOnly = $false
        title = "test_video"
    } | ConvertTo-Json
    
    Write-Host "  POST $downloadUrl" -ForegroundColor Gray
    
    $jobResult = Invoke-RestMethod -Uri $downloadUrl -Method Post -Body $body -ContentType "application/json" -TimeoutSec 60
    
    if ($jobResult.success) {
        Write-Host "  ✓ Download job initialized" -ForegroundColor Green
        Write-Host "  Job ID: $($jobResult.jobId)" -ForegroundColor Gray
    }
    
} catch {
    Write-Host "  ✗ Download initialization failed" -ForegroundColor Red
    Write-Host "  (This is expected if video info fails)" -ForegroundColor Gray
}

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "  Summary" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host ""

if (-not (Test-Path "cookies.txt")) {
    Write-Host "1. Export cookies locally:" -ForegroundColor White
    Write-Host "   .\setup-cookies.ps1" -ForegroundColor Cyan
    Write-Host ""
}

Write-Host "2. Verify cookie format:" -ForegroundColor White
Write-Host "   .\verify-cookies-format.ps1" -ForegroundColor Cyan
Write-Host ""

Write-Host "3. Update Render environment variable:" -ForegroundColor White
Write-Host "   - Go to Render Dashboard" -ForegroundColor Gray
Write-Host "   - Edit YOUTUBE_COOKIES" -ForegroundColor Gray
Write-Host "   - Paste COMPLETE cookies.txt" -ForegroundColor Gray
Write-Host "   - Save and redeploy" -ForegroundColor Gray
Write-Host ""

Write-Host "4. Check Render logs:" -ForegroundColor White
Write-Host "   - Look for 'Found cookies.txt' message" -ForegroundColor Gray
Write-Host "   - Check for yt-dlp errors" -ForegroundColor Gray
Write-Host ""

Write-Host "5. Re-run this test:" -ForegroundColor White
Write-Host "   .\test-render-deployment.ps1" -ForegroundColor Cyan
Write-Host ""

Write-Host "For detailed troubleshooting, see:" -ForegroundColor Yellow
Write-Host "  RENDER_TROUBLESHOOTING.md" -ForegroundColor Cyan
Write-Host ""
