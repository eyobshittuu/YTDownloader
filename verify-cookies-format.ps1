# Cookie Format Verification Script

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Cookie Format Checker" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$cookiesPath = Join-Path $PSScriptRoot "cookies.txt"

if (-not (Test-Path $cookiesPath)) {
    Write-Host "❌ ERROR: cookies.txt not found!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Expected location: $cookiesPath" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Please export cookies from YouTube and save as cookies.txt" -ForegroundColor White
    Write-Host "Run .\setup-cookies.ps1 for instructions" -ForegroundColor Cyan
    exit 1
}

Write-Host "✓ Found cookies.txt" -ForegroundColor Green
$content = Get-Content $cookiesPath -Raw
$lines = Get-Content $cookiesPath

Write-Host ""
Write-Host "File Info:" -ForegroundColor Yellow
Write-Host "  Size: $($content.Length) bytes" -ForegroundColor Gray
Write-Host "  Lines: $($lines.Count)" -ForegroundColor Gray
Write-Host ""

# Check format
$errors = @()
$warnings = @()

# Check 1: Netscape header
if (-not ($lines[0] -match "^# Netscape HTTP Cookie File")) {
    $errors += "Missing Netscape header on first line"
} else {
    Write-Host "✓ Valid Netscape format header" -ForegroundColor Green
}

# Check 2: Has youtube.com entries
$youtubeCookies = $lines | Where-Object { $_ -match "\.youtube\.com" }
if ($youtubeCookies.Count -eq 0) {
    $errors += "No youtube.com cookies found!"
} else {
    Write-Host "✓ Found $($youtubeCookies.Count) youtube.com cookies" -ForegroundColor Green
}

# Check 3: Essential cookies
$essentialCookies = @(
    @{ Name = "VISITOR_INFO1_LIVE"; Found = $false },
    @{ Name = "CONSENT"; Found = $false },
    @{ Name = "SID|__Secure-1PSID"; Found = $false; Pattern = $true }
)

foreach ($check in $essentialCookies) {
    $pattern = if ($check.Pattern) { $check.Name } else { [regex]::Escape($check.Name) }
    $found = $lines | Where-Object { $_ -match $pattern }
    
    if ($found) {
        $cookieName = if ($check.Pattern) { "SID or __Secure-1PSID" } else { $check.Name }
        Write-Host "✓ Found $cookieName cookie" -ForegroundColor Green
        $check.Found = $true
    }
}

# Report missing essential cookies
$missingEssential = $essentialCookies | Where-Object { -not $_.Found }
if ($missingEssential.Count -gt 0) {
    Write-Host ""
    Write-Host "⚠ WARNING: Missing important cookies:" -ForegroundColor Yellow
    foreach ($missing in $missingEssential) {
        $name = if ($missing.Pattern) { "SID or __Secure-1PSID (auth)" } else { $missing.Name }
        Write-Host "  - $name" -ForegroundColor Red
    }
    $warnings += "Some authentication cookies missing"
}

# Check 4: Tab-separated format
$nonCommentLines = $lines | Where-Object { $_ -notmatch "^#" -and $_.Trim() -ne "" }
$tabSeparated = $nonCommentLines | Where-Object { $_ -match "\t" }

if ($nonCommentLines.Count -gt 0 -and $tabSeparated.Count -eq 0) {
    $errors += "Cookies are not tab-separated (wrong format)"
} elseif ($tabSeparated.Count -gt 0) {
    Write-Host "✓ Proper tab-separated format" -ForegroundColor Green
}

# Check 5: Not expired
$now = [int][double]::Parse((Get-Date -UFormat %s))
$expiredCount = 0
foreach ($line in $nonCommentLines) {
    $parts = $line -split "\t"
    if ($parts.Count -ge 5) {
        $expiry = [int]$parts[4]
        if ($expiry -lt $now -and $expiry -gt 0) {
            $expiredCount++
        }
    }
}

if ($expiredCount -gt 0) {
    Write-Host "⚠ $expiredCount cookies are expired" -ForegroundColor Yellow
    $warnings += "$expiredCount expired cookies"
} else {
    Write-Host "✓ No expired cookies" -ForegroundColor Green
}

# Display first few lines (redacted)
Write-Host ""
Write-Host "Cookie File Preview (first 5 lines):" -ForegroundColor Yellow
for ($i = 0; $i -lt [Math]::Min(5, $lines.Count); $i++) {
    $line = $lines[$i]
    if ($line -match "^#") {
        Write-Host "  $line" -ForegroundColor Gray
    } else {
        # Redact cookie values
        $parts = $line -split "\t"
        if ($parts.Count -ge 7) {
            $redacted = "$($parts[0])`t...$($parts.Count - 1) fields...`t$($parts[5])=****"
            Write-Host "  $redacted" -ForegroundColor Gray
        }
    }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Results" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

if ($errors.Count -eq 0 -and $warnings.Count -eq 0) {
    Write-Host "✓ ✓ ✓ COOKIES LOOK GOOD! ✓ ✓ ✓" -ForegroundColor Green
    Write-Host ""
    Write-Host "Your cookies file appears to be properly formatted." -ForegroundColor White
    Write-Host ""
    Write-Host "To use with Render:" -ForegroundColor Yellow
    Write-Host "1. Copy the ENTIRE contents of cookies.txt" -ForegroundColor White
    Write-Host "2. Paste into Render YOUTUBE_COOKIES environment variable" -ForegroundColor White
    Write-Host "3. Make sure you copy ALL lines (including # comments)" -ForegroundColor White
    Write-Host "4. Save and redeploy" -ForegroundColor White
    Write-Host ""
    Write-Host "Current file can be copied from:" -ForegroundColor Cyan
    Write-Host "  $cookiesPath" -ForegroundColor Gray
    
} elseif ($errors.Count -gt 0) {
    Write-Host "❌ ERRORS FOUND:" -ForegroundColor Red
    Write-Host ""
    foreach ($error in $errors) {
        Write-Host "  ✗ $error" -ForegroundColor Red
    }
    Write-Host ""
    Write-Host "Your cookies file has problems. Please re-export from browser." -ForegroundColor Yellow
    Write-Host "Run: .\setup-cookies.ps1" -ForegroundColor Cyan
    
} else {
    Write-Host "⚠ WARNINGS:" -ForegroundColor Yellow
    Write-Host ""
    foreach ($warning in $warnings) {
        Write-Host "  ! $warning" -ForegroundColor Yellow
    }
    Write-Host ""
    Write-Host "File might work but has some issues." -ForegroundColor White
    Write-Host "Consider re-exporting fresh cookies if you have problems." -ForegroundColor White
}

Write-Host ""

# Offer to copy to clipboard
if ($errors.Count -eq 0) {
    Write-Host "========================================" -ForegroundColor Cyan
    $copy = Read-Host "Copy cookies to clipboard for Render? (y/n)"
    if ($copy -eq 'y' -or $copy -eq 'Y') {
        Set-Clipboard -Value $content
        Write-Host ""
        Write-Host "✓ Copied to clipboard!" -ForegroundColor Green
        Write-Host ""
        Write-Host "Now:" -ForegroundColor Yellow
        Write-Host "1. Go to Render Dashboard" -ForegroundColor White
        Write-Host "2. YTDownloader → Environment tab" -ForegroundColor White
        Write-Host "3. Edit YOUTUBE_COOKIES variable" -ForegroundColor White
        Write-Host "4. Paste (Ctrl+V) and Save" -ForegroundColor White
        Write-Host "5. Wait for redeploy (2-3 mins)" -ForegroundColor White
    }
}

Write-Host ""
