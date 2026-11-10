# Quick Fix for YouTube 429/403 Errors

## What Happened?
YouTube has implemented aggressive bot detection, causing your downloader to fail with:
- `HTTP Error 429: Too Many Requests`
- `HTTP Error 403: Forbidden`

## Immediate Solutions

### 1. Update yt-dlp (Do This First!)
```powershell
python -m pip install --upgrade yt-dlp
```

### 2. Add YouTube Cookies (Required for Reliability)

**Easy Method:**
1. Install browser extension: [Get cookies.txt LOCALLY](https://chrome.google.com/webstore/detail/get-cookiestxt-locally/cclelndahbckbenkjhflpdbgdldlbecc)
2. Log into YouTube in your browser
3. Click the extension and export cookies for `youtube.com`
4. Save the file as `cookies.txt` in this project directory
5. Restart your server

**Test if it works:**
```powershell
yt-dlp --cookies cookies.txt "https://www.youtube.com/watch?v=dQw4w9WgXcQ"
```

### 3. What I Changed in Your Code

✅ Enhanced client spoofing (iOS instead of Android)
✅ Better API parameter handling
✅ Added rate limiting protection
✅ Support for OAuth authentication
✅ Improved error messages

## Run the Fix Script

```powershell
.\fix-youtube-errors.ps1
```

This will:
- Update yt-dlp automatically
- Check for cookies.txt
- Test your configuration

## For Detailed Instructions

See `YOUTUBE_AUTH_SETUP.md` for comprehensive authentication options including OAuth.

## Still Having Issues?

1. Clear your browser cache and get fresh cookies
2. Try using a VPN if your IP is rate-limited
3. Wait a few minutes between download attempts
4. Make sure you're using the latest yt-dlp version

## Code Changes Summary

- **ytDlpService.js**: Updated client spoofing from `android,web` to `ios,web` for better reliability
- **ytDlpService.js**: Added rate limiting (10 requests per minute per IP)
- **index.js**: Added client IP tracking for rate limiting
- All changes maintain backward compatibility with your existing frontend
