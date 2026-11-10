# Quick YouTube Download Test Script

param(
    [string]$url = "https://www.youtube.com/watch?v=jNQXAC9IVRw"  # First YouTube video ever
)

Write-Host "Testing YouTube download with current configuration..." -ForegroundColor Cyan
Write-Host ""

$cookiesFile = Join-Path $PSScriptRoot "cookies.txt"
$hasCookies = Test-Path $cookiesFile

if ($hasCookies) {
    Write-Host "✓ Using cookies.txt" -ForegroundColor Green
} else {
    Write-Host "⚠ No cookies.txt found - may fail with 429/403 errors" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Testing URL: $url" -ForegroundColor White
Write-Host ""

# Build command
$args = @(
    "--dump-json",
    "--no-playlist"
)

if ($hasCookies) {
    $args += "--cookies"
    $args += $cookiesFile
}

$args += $url

# Try running yt-dlp
try {
    $hasPython = Get-Command python -ErrorAction SilentlyContinue
    
    if ($hasPython) {
        Write-Host "Running: python -m yt_dlp $($args -join ' ')" -ForegroundColor Gray
        Write-Host ""
        
        $output = python -m yt_dlp $args 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            $json = $output | ConvertFrom-Json
            Write-Host "✓ SUCCESS!" -ForegroundColor Green
            Write-Host ""
            Write-Host "Video Title: $($json.title)" -ForegroundColor White
            Write-Host "Channel: $($json.uploader)" -ForegroundColor White
            Write-Host "Duration: $([int]$json.duration) seconds" -ForegroundColor White
            Write-Host "Views: $($json.view_count)" -ForegroundColor White
            Write-Host ""
            Write-Host "Your YouTube downloader should work now!" -ForegroundColor Green
        } else {
            Write-Host "✗ FAILED" -ForegroundColor Red
            Write-Host ""
            Write-Host "Error output:" -ForegroundColor Yellow
            Write-Host $output -ForegroundColor Gray
            Write-Host ""
            
            if ($output -like "*429*" -or $output -like "*403*") {
                Write-Host "This is a rate limiting / authentication error." -ForegroundColor Yellow
                Write-Host ""
                Write-Host "Solutions:" -ForegroundColor Cyan
                Write-Host "1. Add cookies.txt file (see UPDATE_README.md)" -ForegroundColor White
                Write-Host "2. Update yt-dlp: python -m pip install --upgrade yt-dlp" -ForegroundColor White
                Write-Host "3. Wait a few minutes before trying again" -ForegroundColor White
            }
        }
    } else {
        Write-Host "Python not found. Trying yt-dlp executable..." -ForegroundColor Yellow
        $output = yt-dlp $args 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✓ SUCCESS - yt-dlp is working!" -ForegroundColor Green
        } else {
            Write-Host "✗ FAILED" -ForegroundColor Red
            Write-Host $output -ForegroundColor Gray
        }
    }
} catch {
    Write-Host "✗ Error running test: $_" -ForegroundColor Red
}

Write-Host ""
