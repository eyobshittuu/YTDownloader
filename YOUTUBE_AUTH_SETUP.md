# YouTube Authentication Setup

## Problem
YouTube has implemented aggressive rate limiting and bot detection, causing 429 (Too Many Requests) and 403 (Forbidden) errors.

## Solutions (Choose One)

### Option 1: Use Browser Cookies (Easiest)

1. Install a browser extension to export cookies:
   - **Chrome/Edge**: [Get cookies.txt LOCALLY](https://chrome.google.com/webstore/detail/get-cookiestxt-locally/cclelndahbckbenkjhflpdbgdldlbecc)
   - **Firefox**: [cookies.txt](https://addons.mozilla.org/en-US/firefox/addon/cookies-txt/)

2. Log into YouTube in your browser

3. Use the extension to export cookies for youtube.com

4. Save the exported cookies as `cookies.txt` in the project root directory

5. Restart your server

### Option 2: Use OAuth Authentication

1. Run yt-dlp with OAuth setup:
   ```powershell
   yt-dlp --username oauth2 --password '' https://www.youtube.com/watch?v=dQw4w9WgXcQ
   ```

2. Follow the prompts to authenticate with your Google account

3. yt-dlp will save authentication tokens automatically

4. Set environment variable:
   ```powershell
   $env:YOUTUBE_OAUTH = "true"
   ```

5. Restart your server

### Option 3: Update yt-dlp (Always Do This First)

```powershell
# If using Python module
python -m pip install --upgrade yt-dlp

# If using executable
yt-dlp -U
```

## Enhanced Configuration

The code now uses improved client spoofing:
- iOS player client (more reliable than Android)
- Skips unnecessary webpage parsing
- Better compatibility with YouTube's current API

## Testing

After setup, test with:
```bash
yt-dlp --cookies cookies.txt "https://www.youtube.com/watch?v=dQw4w9WgXcQ"
```

## Environment Variables

You can set these in a `.env` file:

```env
# If using cookies from environment (for cloud deployment)
YOUTUBE_COOKIES=<paste your cookies.txt content here>

# If using OAuth
YOUTUBE_OAUTH=true
```

## Troubleshooting

### Still Getting Errors?
1. Make sure yt-dlp is updated to latest version
2. Try clearing cookies and re-exporting from browser
3. Use incognito mode to generate fresh cookies
4. Add rate limiting/delays between requests in your app
5. Consider using a VPN if IP is rate-limited

### Vercel/Cloud Deployment
For serverless deployment, use the `YOUTUBE_COOKIES` environment variable method since file access may be restricted.
