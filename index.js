const express = require('express');
const cors = require('cors');
const path = require('path');
const fs = require('fs');
require('dotenv').config();

const {
  getVideoInfo,
  startDownload,
  getJobStatus,
  DOWNLOADS_DIR
} = require('./services/ytDlpService');

const app = express();
const PORT = process.env.PORT || 5000;

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Serve static frontend assets from public/ if present
const publicDir = path.join(__dirname, 'public');
if (fs.existsSync(publicDir)) {
  app.use(express.static(publicDir));
}

// Health check endpoint
app.get('/api/health', (req, res) => {
  res.json({
    status: 'ok',
    version: '1.0.5-cookie-normalize',
    hasCookiesEnv: Boolean(process.env.YOUTUBE_COOKIES && process.env.YOUTUBE_COOKIES.length > 50),
    cookiesLength: process.env.YOUTUBE_COOKIES ? process.env.YOUTUBE_COOKIES.length : 0,
    timestamp: new Date().toISOString(),
    uptime: process.uptime()
  });
});

// Diagnostic endpoint to inspect cookie normalization (no private values revealed)
app.get('/api/debug-cookies', (req, res) => {
  const os = require('os');
  const tmpCookies = path.join(os.tmpdir(), 'youtube_cookies.txt');
  if (fs.existsSync(tmpCookies)) {
    const content = fs.readFileSync(tmpCookies, 'utf8');
    const lines = content.split('\n');
    res.json({
      exists: true,
      size: content.length,
      linesCount: lines.length,
      firstLine: lines[0]?.slice(0, 40),
      hasYoutubeDomain: content.includes('youtube.com'),
      sampleDomains: lines.filter(l => l && !l.startsWith('#')).slice(0, 5).map(l => l.split('\t')[0])
    });
  } else {
    res.json({
      exists: false,
      hasEnv: Boolean(process.env.YOUTUBE_COOKIES),
      envLength: process.env.YOUTUBE_COOKIES ? process.env.YOUTUBE_COOKIES.length : 0
    });
  }
});

// Fetch video info and formats
app.post('/api/info', async (req, res) => {
  try {
    const { url } = req.body;
    if (!url || typeof url !== 'string' || !url.trim()) {
      return res.status(400).json({ error: 'Please provide a valid YouTube URL.' });
    }

    const info = await getVideoInfo(url.trim());
    return res.json({ success: true, data: info });
  } catch (error) {
    console.error('Error fetching video info:', error.message);
    return res.status(500).json({
      error: error.message || 'Failed to fetch video information. Make sure yt-dlp is installed and the URL is accessible.'
    });
  }
});

// Support GET /api/info?url=...
app.get('/api/info', async (req, res) => {
  try {
    const { url } = req.query;
    if (!url || typeof url !== 'string' || !url.trim()) {
      return res.status(400).json({ error: 'Please provide a valid YouTube URL in the url query parameter.' });
    }

    const info = await getVideoInfo(url.trim());
    return res.json({ success: true, data: info });
  } catch (error) {
    console.error('Error fetching video info:', error.message);
    return res.status(500).json({
      error: error.message || 'Failed to fetch video information.'
    });
  }
});

// Start a download job
app.post('/api/download', (req, res) => {
  try {
    const { url, format, quality, isAudioOnly, title } = req.body;

    if (!url || typeof url !== 'string' || !url.trim()) {
      return res.status(400).json({ error: 'Video URL is required.' });
    }

    const jobId = startDownload({
      url: url.trim(),
      format: format || (isAudioOnly ? 'mp3' : 'mp4'),
      quality: quality || '1080',
      isAudioOnly: Boolean(isAudioOnly),
      title: title || 'download'
    });

    return res.json({
      success: true,
      message: 'Download job initialized',
      jobId
    });
  } catch (error) {
    console.error('Error starting download:', error.message);
    return res.status(500).json({
      error: error.message || 'Failed to initiate download job.'
    });
  }
});

// Get job status via standard REST polling
app.get('/api/progress/:jobId', (req, res) => {
  const { jobId } = req.params;
  const job = getJobStatus(jobId);

  if (!job) {
    return res.status(404).json({ error: 'Job not found or has expired.' });
  }

  return res.json({
    id: job.id,
    title: job.title,
    status: job.status,
    progress: job.progress,
    speed: job.speed,
    eta: job.eta,
    size: job.size,
    error: job.error,
    isAudioOnly: job.isAudioOnly,
    format: job.format,
    finalFilename: job.finalFilename
  });
});

// Real-time progress updates via Server-Sent Events (SSE)
app.get('/api/events/:jobId', (req, res) => {
  const { jobId } = req.params;
  const job = getJobStatus(jobId);

  if (!job) {
    return res.status(404).send('Job not found');
  }

  res.setHeader('Content-Type', 'text/event-stream');
  res.setHeader('Cache-Control', 'no-cache');
  res.setHeader('Connection', 'keep-alive');
  res.flushHeaders?.();

  // Send initial event
  res.write(`data: ${JSON.stringify(job)}\n\n`);

  const intervalId = setInterval(() => {
    const currentJob = getJobStatus(jobId);
    if (!currentJob) {
      clearInterval(intervalId);
      res.end();
      return;
    }

    res.write(`data: ${JSON.stringify(currentJob)}\n\n`);

    if (currentJob.status === 'completed' || currentJob.status === 'error') {
      clearInterval(intervalId);
      res.end();
    }
  }, 500);

  req.on('close', () => {
    clearInterval(intervalId);
  });
});

// Download the finished file
app.get('/api/download/file/:jobId', (req, res) => {
  const { jobId } = req.params;
  const job = getJobStatus(jobId);

  if (!job) {
    return res.status(404).json({ error: 'Job not found or expired.' });
  }

  if (job.status !== 'completed' || !job.filePath) {
    return res.status(400).json({ error: 'Download is not yet ready or has failed.' });
  }

  if (!fs.existsSync(job.filePath)) {
    return res.status(404).json({ error: 'Processed file could not be found on server disk.' });
  }

  res.download(job.filePath, job.finalFilename, (err) => {
    if (err && !res.headersSent) {
      console.error('File download error:', err);
      res.status(500).json({ error: 'Failed to transfer file to client.' });
    }
  });
});

// Fallback route for SPA
app.get('*', (req, res, next) => {
  const indexPath = path.join(publicDir, 'index.html');
  if (fs.existsSync(indexPath)) {
    return res.sendFile(indexPath);
  }
  next();
});

// Start Express Server only when run directly (local / container environments)
if (require.main === module) {
  app.listen(PORT, () => {
    console.log(`YouTube Downloader Backend running at http://localhost:${PORT}`);
  });
}

// Export for serverless environments (Vercel)
module.exports = app;

