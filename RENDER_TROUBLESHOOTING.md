# Render Deployment Troubleshooting

## Based on Your Screenshot

I can see you've added `YOUTUBE_COOKIES` to Render, but it might be incomplete. Here's what to check:

## Issue 1: Incomplete Cookie Data

From your screenshot, the value appears to only show:
```
# Netscape HTTP Cookie File
# https://curl.haxx.se/rfc/cookie_spec.html
# This is a generated file! Do not edit.
```

**Problem:** These are just the comment lines. The actual cookie data is missing!

**Solution:** You need to copy the **ENTIRE** cookies.txt file, including all the lines that look like:
```
.youtube.com	TRUE	/	FALSE	1735689600	CONSENT	YES+...
.youtube.com	TRUE	/	TRUE	1735689600	__Secure-1PSID	g.a000...
```

## How to Fix

### Step 1: Verify Local Cookies File

Run this to check your cookies.txt:
```powershell
cd C:\Users\babbo\Videos\ytdownloader\YTDownloader
.\verify-cookies-format.ps1
```

This will:
- ✅ Check if cookies.txt is valid
- ✅ Verify it has actual cookie data (not just comments)
- ✅ Offer to copy to clipboard
- ✅ Show if cookies are expired

### Step 2: Re-Export Cookies (If Needed)

If cookies.txt is missing or invalid:

1. **Open YouTube in browser** (Chrome/Edge)
2. **Make sure you're logged in**
3. **Install extension** (if not already):
   - https://chrome.google.com/webstore/detail/get-cookiestxt-locally/cclelndahbckbenkjhflpdbgdldlbecc
4. **Click extension icon**
5. **Select "youtube.com"**
6. **Click "Export"**
7. **Save as cookies.txt** in: `C:\Users\babbo\Videos\ytdownloader\YTDownloader\`

### Step 3: Copy COMPLETE Cookie File

**Option A: Use the script**
```powershell
.\verify-cookies-format.ps1
# Answer 'y' to copy to clipboard
```

**Option B: Manual copy**
1. Open `cookies.txt` in Notepad
2. **Press Ctrl+A** (select ALL - important!)
3. **Press Ctrl+C** (copy)
4. Verify you copied everything (should be 10-50 lines)

### Step 4: Update Render Environment Variable

1. Go to Render Dashboard
2. Your Service: **YTDownloader**
3. Click **Environment** tab (you're already there!)
4. Click the **Edit button** (pencil icon) next to `YOUTUBE_COOKIES`
5. **Delete the current value completely**
6. **Paste the NEW complete cookies** (Ctrl+V)
7. **Verify you see multiple lines** like:
   ```
   # Netscape HTTP Cookie File
   .youtube.com	TRUE	/	FALSE	...
   .youtube.com	TRUE	/	TRUE	...
   ... (many more lines)
   ```
8. Click **Save Changes**

### Step 5: Force Redeploy

After saving environment variables:

1. Go to **Manual Deploy** tab
2. Click **"Deploy latest commit"**
3. Wait 2-3 minutes for deployment

Or it should auto-deploy after saving environment variables.

## How to Verify It Worked

### Check Render Logs

1. Go to **Logs** tab in Render
2. Look for during startup:
   ```
   ✅ Found cookies.txt
   ```
   or
   ```
   ⚠️ No cookies found
   ```

### Test the API

```bash
curl -X POST "https://ytdownloader-rq53.onrender.com/api/info" \
  -H "Content-Type: application/json" \
  -d '{"url":"https://www.youtube.com/watch?v=jNQXAC9IVRw"}'
```

**Success response:**
```json
{
  "success": true,
  "data": {
    "title": "Me at the zoo",
    "duration": 19,
    ...
  }
}
```

**Failure response (no cookies):**
```json
{
  "error": "HTTP Error 403: Forbidden"
}
```

## Common Mistakes

### ❌ Only copying comment lines
```
# Netscape HTTP Cookie File
# This is a generated file! Do not edit.
```
**This won't work!** You need the actual cookie data.

### ❌ Only copying first few lines
Make sure you copy **ALL** lines from cookies.txt (usually 10-50 lines)

### ❌ Adding extra formatting
Don't add quotes, JSON formatting, or escape characters. Just paste the raw file content.

### ❌ Wrong variable name
Must be exactly: `YOUTUBE_COOKIES` (case sensitive)

### ❌ Not redeploying
After changing environment variables, Render needs to redeploy.

## Issue 2: Old yt-dlp Version on Render

Even with correct cookies, old yt-dlp might fail.

**Solution:** Your `render-build.sh` script already handles this, but verify in logs:

Look for:
```
yt-dlp version: 2024.11.04 or newer
```

If you see an older version, the build script might have failed.

## Issue 3: Cookies Expired

Cookies typically last 6 months. If they're old:

1. Export fresh cookies from browser
2. Update Render environment variable
3. Redeploy

## Issue 4: Wrong YouTube Account

Make sure you exported cookies while logged into YouTube (not logged out).

To verify:
1. Open youtube.com
2. Check if you see your profile picture (top right)
3. If not logged in, log in first
4. Then export cookies again

## Complete Checklist

- [ ] cookies.txt exists locally
- [ ] cookies.txt has actual cookie data (not just comments)
- [ ] cookies.txt has 10+ lines
- [ ] Includes `.youtube.com` domain lines
- [ ] Includes authentication cookies (SID or __Secure-1PSID)
- [ ] Run `.\verify-cookies-format.ps1` - shows no errors
- [ ] Copied ENTIRE cookies.txt to clipboard
- [ ] Pasted into Render YOUTUBE_COOKIES variable
- [ ] Variable value shows multiple lines (not just comments)
- [ ] Saved changes in Render
- [ ] Redeployed (manual or auto)
- [ ] Checked Render logs - shows "Found cookies.txt"
- [ ] Tested API endpoint - returns video data

## Still Not Working?

### Test Locally First

Before debugging Render, verify cookies work on your machine:

```powershell
# Test yt-dlp directly
yt-dlp --cookies cookies.txt "https://www.youtube.com/watch?v=jNQXAC9IVRw"

# Test your server
npm start

# In another terminal
curl -X POST "http://localhost:5000/api/info" `
  -H "Content-Type: application/json" `
  -d '{"url":"https://www.youtube.com/watch?v=jNQXAC9IVRw"}'
```

If it works locally but not on Render:
- ✅ Cookies are valid
- ❌ Problem is with Render environment variable

If it doesn't work locally either:
- ❌ Cookies are invalid or expired
- → Export fresh cookies

### Get Fresh Cookies

Sometimes cookies just don't export correctly. Try:

1. **Use incognito/private window**
2. **Log into YouTube fresh**
3. **Export cookies immediately**
4. **Test right away**

### Alternative Browser

If Chrome extension doesn't work:
- Try Firefox: https://addons.mozilla.org/en-US/firefox/addon/cookies-txt/
- Or Edge (uses Chrome extensions)

## Debug Commands

Check if cookies were applied:
```bash
# In Render Shell (if available)
ls -la cookies.txt 2>/dev/null || echo "No cookie file"
echo $YOUTUBE_COOKIES | head -n 3
```

## Need Help?

1. Run `.\verify-cookies-format.ps1`
2. Share the output (it redacts sensitive data)
3. Share Render logs (from Logs tab)
4. Share API test response

## Expected Timeline

Once cookies are correctly set:
- ⏱️ Save in Render: Instant
- ⏱️ Auto-deploy: 2-3 minutes
- ⏱️ Service ready: 2-3 minutes
- ✅ **Total: ~5 minutes from save to working**

---

**Most likely issue:** The YOUTUBE_COOKIES value in Render only has the comment lines and is missing the actual cookie data.

**Quick fix:** Run `.\verify-cookies-format.ps1`, copy to clipboard, update Render, save, redeploy.
