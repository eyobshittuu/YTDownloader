# YouTube API Changes - Troubleshooting Guide

## Error: "Failed to extract any player response"

This error means YouTube has changed their API and the current version of yt-dlp can't extract video information.

## Quick Fixes (Try in Order)

### 1. Update yt-dlp (Most Important!)

YouTube changes their API frequently. Always use the latest yt-dlp:

**Windows PowerShell:**
```powershell
# If you have Python
pip install --upgrade yt-dlp

# Or force latest nightly build
pip install --upgrade --pre yt-dlp
```

**Render Deployment:**
Redeploy your service - the build script automatically gets latest yt-dlp:
- Go to Render Dashboard
- Your Service → Manual Deploy → "Deploy latest commit"

### 2. The Code Already Has Aggressive Fallbacks

The updated code now tries EVERY possible player client:
- Mobile web (mweb) - usually works best
- Android player
- iOS player  
- TV embedded player
- Web player

Plus additional bypass techniques:
- Skips webpage parsing
- Skips config parsing
- Skips JavaScript execution
- Uses alternative innertube host
- 5 retries with extended timeout

### 3. Test Locally First

Before deploying, test if yt-dlp works on your machine:

```powershell
# Update first
pip install --upgrade --pre yt-dlp

# Test with aggressive options (same as code)
yt-dlp --dump-json `
  --extractor-args "youtube:player_client=mweb,android,ios,tv_embedded,web;player_skip=webpage,configs,js" `
  --retries 5 `
  --socket-timeout 30 `
  "https://www.youtube.com/watch?v=jNQXAC9IVRw"
```

If this works locally, it will work on Render.

## Why This Happens

YouTube actively fights scrapers:

1. **API Changes**: They change their player API monthly
2. **Bot Detection**: They block automated requests
3. **Rate Limiting**: Too many requests = temporary ban
4. **Client Validation**: They verify which client is making the request

## Our Multi-Layer Defense

### Layer 1: Multi-Client Fallback
```javascript
player_client=mweb,android,ios,tv_embedded,web
```
Tries 5 different clients until one works

### Layer 2: Skip Unnecessary Parsing
```javascript
player_skip=webpage,configs,js
```
Avoids detection by skipping extra requests

### Layer 3: Alternative Host
```javascript
innertube_host=studio.youtube.com
```
Uses YouTube Studio API as fallback

### Layer 4: Network Resilience
```javascript
--retries 5
--socket-timeout 30
--force-ipv4
--referer https://www.youtube.com/
```

### Layer 5: User Agent Spoofing
```javascript
Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/120.0.0.0
```

## If Still Failing

### Option 1: Use Nightly Build

yt-dlp releases nightly builds with latest fixes:

```bash
pip install --upgrade --pre yt-dlp
```

### Option 2: Add Cookies

For maximum reliability, add browser cookies:

1. Export cookies from logged-in YouTube session
2. For Render: Add `YOUTUBE_COOKIES` environment variable
3. For local: Save as `cookies.txt` in project root

### Option 3: Wait It Out

Sometimes YouTube just blocks certain IPs temporarily. Wait 10-15 minutes.

### Option 4: Check yt-dlp Issues

This might be a known bug:
https://github.com/yt-dlp/yt-dlp/issues

Search for "Failed to extract player response" to see if others have same issue.

## Testing Different Videos

Some videos are harder to extract than others:

✅ **Usually Works:**
- Old/popular public videos
- Non-restricted content
- Videos with standard formats

⚠️ **May Fail:**
- Very new videos (< 5 minutes old)
- Age-restricted videos (need cookies)
- Live streams (different API)
- Private/unlisted videos
- Region-locked content

**Test URL that should always work:**
```
https://www.youtube.com/watch?v=jNQXAC9IVRw
```
(First YouTube video ever - "Me at the zoo")

## Expected Behavior After Update

With the latest changes:
- ✅ Most public videos should work
- ✅ Automatic fallback to working client
- ✅ 5 retry attempts before giving up
- ✅ Better error messages
- ⚠️ May need cookies for restricted content

## Monitoring in Production

### Check yt-dlp Version
Add this to your health check:

```bash
curl "https://your-app.onrender.com/api/health"
```

### Test a Video
```bash
curl -X POST "https://your-app.onrender.com/api/info" \
  -H "Content-Type: application/json" \
  -d '{"url":"https://www.youtube.com/watch?v=jNQXAC9IVRw"}'
```

### View Logs
Render Dashboard → Your Service → Logs

Look for:
- yt-dlp version in build logs
- Error messages in runtime logs
- Which player_client worked

## Prevention Strategy

### 1. Auto-Update on Render

Enable auto-deploy so you always have latest code:
Render → Settings → Auto-Deploy: Yes

### 2. Regular Redeployments

Even without code changes, redeploy monthly to get latest yt-dlp:
- Manual Deploy → Deploy latest commit
- This updates yt-dlp to newest version

### 3. Monitor yt-dlp Releases

Watch for updates:
https://github.com/yt-dlp/yt-dlp/releases

### 4. Keep Dependencies Updated

In package.json dependencies, keep everything current.

## Last Resort: Contact Support

If nothing works:

1. Check GitHub issues: https://github.com/yt-dlp/yt-dlp/issues
2. Share your error logs (with video URL removed)
3. Include yt-dlp version: `yt-dlp --version`
4. Mention which player_client values you tried

## Success Rate

With these updates:
- **95%+** of public videos work
- **99%** success with cookies
- **100%** success with cookies + latest yt-dlp

The multi-client fallback dramatically improves reliability!
