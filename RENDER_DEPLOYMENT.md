# Render Deployment Guide

## Updated: Cookie-Free Operation

This YouTube downloader now works on Render **WITHOUT requiring cookies**! The updated configuration uses advanced bypass techniques.

## What Changed

✅ Multi-client fallback strategy (iOS → mobile web → Android)
✅ Enhanced user agent spoofing
✅ IPv4 forcing (avoids IPv6 issues)
✅ Automatic retry logic (3 retries on failure)
✅ Extended socket timeout (30 seconds)
✅ Optimized extractor arguments for cookie-less operation

## Render Setup Instructions

### 1. Create New Web Service

1. Go to [Render Dashboard](https://dashboard.render.com/)
2. Click **New +** → **Web Service**
3. Connect your GitHub repository: `eyobshittuu/YTDownloader`

### 2. Configure Build Settings

**Environment:** `Node`

**Build Command:**
```bash
npm install && pip install -U yt-dlp
```

**Start Command:**
```bash
npm start
```

### 3. Environment Variables (Optional)

You don't need any environment variables for basic operation! But you can add these for enhanced functionality:

| Variable | Value | Purpose |
|----------|-------|---------|
| `PORT` | `5000` | Server port (auto-set by Render) |
| `NODE_ENV` | `production` | Production mode |

### 4. Advanced Settings

**Instance Type:** Free (or Starter for better performance)
**Region:** Choose closest to your users
**Health Check Path:** `/api/health`

## How It Works Without Cookies

The updated code uses multiple strategies:

1. **Multi-Client Fallback**: Tries iOS player → mobile web → Android client
2. **Player Skip**: Bypasses unnecessary webpage parsing
3. **User Agent Spoofing**: Uses latest Chrome user agent
4. **Retry Logic**: Automatically retries failed requests 3 times
5. **Network Optimizations**: Forces IPv4, extends timeouts

## Testing on Render

After deployment, test with:

```bash
curl "https://your-app.onrender.com/api/health"
```

Should return:
```json
{
  "status": "ok",
  "version": "1.0.5-cookie-normalize",
  "timestamp": "2024-11-10T...",
  "uptime": 123
}
```

Test video info:
```bash
curl -X POST "https://your-app.onrender.com/api/info" \
  -H "Content-Type: application/json" \
  -d '{"url":"https://www.youtube.com/watch?v=jNQXAC9IVRw"}'
```

## Troubleshooting

### Still Getting 429/403 Errors?

If you still encounter issues after deployment:

1. **Update yt-dlp version in build command:**
   ```bash
   npm install && pip install -U yt-dlp --break-system-packages
   ```

2. **Check Render logs** for specific error messages

3. **Try adding a delay** between requests in your frontend (rate limiting)

4. **As last resort**, add cookies via environment variable:
   - Export cookies from your browser
   - Add `YOUTUBE_COOKIES` environment variable in Render
   - Paste entire cookies.txt content

### Build Failures

If Python/pip isn't available:

**Alternative Build Command:**
```bash
npm install && curl -L https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp -o /tmp/yt-dlp && chmod +x /tmp/yt-dlp
```

Then update `getExecutionConfig()` to check `/tmp/yt-dlp`

### Performance Issues

Free tier on Render sleeps after 15 minutes of inactivity. Consider:
- Upgrading to Starter plan ($7/month)
- Adding a cron job to ping your service every 14 minutes
- Using a service like UptimeRobot for keep-alive

## Expected Behavior

✅ Works for most public YouTube videos
✅ No cookies required
✅ Automatic fallback to different clients
✅ Retry logic handles temporary failures
⚠️ May occasionally fail for very new videos (< 5 minutes old)
⚠️ Age-restricted content may need cookies

## Keep yt-dlp Updated

YouTube frequently changes their API. To stay current:

1. Enable **Auto-Deploy** on Render
2. Render will rebuild when you push updates
3. Manually redeploy to update yt-dlp:
   - Go to your service → **Manual Deploy** → **Deploy latest commit**

## Performance Optimization

For production, consider:

1. **Add caching** for video metadata (reduces API calls)
2. **Implement job queue** for downloads (Bull/Redis)
3. **Use CDN** for serving downloaded files
4. **Add database** to track download history
5. **Implement rate limiting per user** (already built-in per IP)

## Cost Estimate

- **Free Tier**: 750 hours/month (sleeps after 15min inactivity)
- **Starter**: $7/month (always on, 512MB RAM)
- **Standard**: $25/month (1GB RAM, better for high traffic)

## Support

If issues persist:
1. Check Render logs for errors
2. Test yt-dlp directly: `yt-dlp --version`
3. Verify network connectivity in Render shell
4. Open GitHub issue with error logs

## Success! 🎉

Once deployed, your YouTube downloader should work reliably on Render without any cookies or authentication!
