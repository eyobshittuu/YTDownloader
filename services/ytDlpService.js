const { spawn } = require('child_process');
const path = require('path');
const fs = require('fs');
const os = require('os');

// Temporary downloads storage directory with serverless fallback
let DOWNLOADS_DIR = path.join(__dirname, '..', 'temp_downloads');
try {
  if (!fs.existsSync(DOWNLOADS_DIR)) {
    fs.mkdirSync(DOWNLOADS_DIR, { recursive: true });
  }
} catch (e) {
  // Read-only filesystem fallback (e.g. Vercel Serverless / AWS Lambda)
  DOWNLOADS_DIR = path.join(os.tmpdir(), 'fab_temp_downloads');
  try {
    if (!fs.existsSync(DOWNLOADS_DIR)) {
      fs.mkdirSync(DOWNLOADS_DIR, { recursive: true });
    }
  } catch (err) {}
}

// In-memory active jobs tracker
const jobs = new Map();

// Helper to sanitize filenames for Windows & Unix
function sanitizeFilename(name) {
  return (name || 'video')
    .replace(/[/\\?%*:|"<>]/g, '_')
    .replace(/\s+/g, ' ')
    .trim();
}

// Format seconds into HH:MM:SS or MM:SS
function formatDuration(seconds) {
  if (!seconds || isNaN(seconds)) return '0:00';
  const hrs = Math.floor(seconds / 3600);
  const mins = Math.floor((seconds % 3600) / 60);
  const secs = Math.floor(seconds % 60);
  if (hrs > 0) {
    return `${hrs}:${mins < 10 ? '0' : ''}${mins}:${secs < 10 ? '0' : ''}${secs}`;
  }
  return `${mins}:${secs < 10 ? '0' : ''}${secs}`;
}

// Format view counts
function formatViews(views) {
  if (!views || isNaN(views)) return '0';
  if (views >= 1_000_000_000) return (views / 1_000_000_000).toFixed(1) + 'B';
  if (views >= 1_000_000) return (views / 1_000_000).toFixed(1) + 'M';
  if (views >= 1_000) return (views / 1_000).toFixed(1) + 'K';
  return views.toString();
}

// Format byte sizes
function formatBytes(bytes) {
  if (!bytes || isNaN(bytes)) return null;
  if (bytes >= 1024 * 1024 * 1024) return (bytes / (1024 * 1024 * 1024)).toFixed(1) + ' GB';
  if (bytes >= 1024 * 1024) return (bytes / (1024 * 1024)).toFixed(1) + ' MB';
  if (bytes >= 1024) return (bytes / 1024).toFixed(1) + ' KB';
  return bytes + ' B';
}

// Clean up old temporary files (older than 30 minutes)
const cleanupInterval = setInterval(() => {
  const now = Date.now();
  fs.readdir(DOWNLOADS_DIR, (err, files) => {
    if (err) return;
    for (const file of files) {
      const filePath = path.join(DOWNLOADS_DIR, file);
      fs.stat(filePath, (statErr, stats) => {
        if (!statErr && now - stats.mtimeMs > 30 * 60 * 1000) {
          fs.unlink(filePath, () => {});
        }
      });
    }
  });
}, 10 * 60 * 1000);
if (cleanupInterval.unref) {
  cleanupInterval.unref();
}

/**
 * Locate yt-dlp and ffmpeg executables
 */
function getExecutionConfig() {
  const localBin = path.join(__dirname, '..', 'bin');
  const localYtDlpWin = path.join(localBin, 'yt-dlp.exe');
  const localYtDlpUnix = path.join(localBin, 'yt-dlp');

  let command = 'python';
  let baseArgs = ['-m', 'yt_dlp'];

  if (process.platform === 'win32' && fs.existsSync(localYtDlpWin)) {
    command = localYtDlpWin;
    baseArgs = [];
  } else if (process.platform !== 'win32' && fs.existsSync(localYtDlpUnix)) {
    // On Linux / Serverless environments (Vercel, Railway, Render), ensure executable in /tmp
    const tmpBin = path.join(os.tmpdir(), 'yt-dlp');
    try {
      if (!fs.existsSync(tmpBin) || fs.statSync(tmpBin).size !== fs.statSync(localYtDlpUnix).size) {
        fs.copyFileSync(localYtDlpUnix, tmpBin);
      }
      fs.chmodSync(tmpBin, 0o755);
      command = tmpBin;
      baseArgs = [];
    } catch (e) {
      command = localYtDlpUnix;
      baseArgs = [];
    }
  }

  // Detect FFmpeg path (Windows, Linux, system PATH)
  const candidateFfmpegDirs = [
    path.join(os.homedir(), 'AppData', 'Local', 'Microsoft', 'WinGet', 'Links'),
    localBin,
    '/usr/bin',
    '/usr/local/bin',
    'C:\\ffmpeg\\bin',
    'C:\\Program Files\\ffmpeg\\bin'
  ];

  let ffmpegLocation = null;
  for (const dir of candidateFfmpegDirs) {
    if (fs.existsSync(path.join(dir, 'ffmpeg.exe')) || fs.existsSync(path.join(dir, 'ffmpeg'))) {
      ffmpegLocation = dir;
      break;
    }
  }

  return { command, baseArgs, ffmpegLocation };
}

/**
 * Fetch video metadata and available formats using yt-dlp
 */
async function getVideoInfo(url) {
  return new Promise((resolve, reject) => {
    const { command, baseArgs, ffmpegLocation } = getExecutionConfig();

    const args = [
      ...baseArgs,
      '--dump-single-json',
      '--no-playlist',
      '--no-warnings',
      '--no-check-certificates'
    ];

    if (ffmpegLocation) {
      args.push('--ffmpeg-location', ffmpegLocation);
    }

    args.push(url);

    const child = spawn(command, args);

    let stdoutData = '';
    let stderrData = '';

    child.stdout.on('data', (data) => {
      stdoutData += data.toString();
    });

    child.stderr.on('data', (data) => {
      stderrData += data.toString();
    });

    child.on('close', (code) => {
      if (code !== 0) {
        return reject(new Error(stderrData.trim() || `yt-dlp exited with code ${code}`));
      }

      try {
        const raw = JSON.parse(stdoutData);

        // Select highest quality thumbnail
        let thumbnail = raw.thumbnail;
        if (Array.isArray(raw.thumbnails) && raw.thumbnails.length > 0) {
          const sorted = [...raw.thumbnails].sort((a, b) => (b.width || 0) - (a.width || 0));
          if (sorted[0]?.url) {
            thumbnail = sorted[0].url;
          }
        }

        const rawFormats = raw.formats || [];
        const availableHeights = new Set();

        rawFormats.forEach(f => {
          if (f.height && f.vcodec !== 'none') {
            availableHeights.add(f.height);
          }
        });

        // Target resolutions
        const standardResolutions = [
          { height: 2160, label: '4K Ultra HD (2160p)', quality: '2160' },
          { height: 1440, label: '2K Quad HD (1440p)', quality: '1440' },
          { height: 1080, label: 'Full HD (1080p)', quality: '1080' },
          { height: 720, label: 'HD (720p)', quality: '720' },
          { height: 480, label: 'Standard (480p)', quality: '480' },
          { height: 360, label: 'Medium (360p)', quality: '360' },
          { height: 240, label: 'Low (240p)', quality: '240' },
          { height: 144, label: 'Mobile (144p)', quality: '144' }
        ];

        const videoFormats = [];
        standardResolutions.forEach(res => {
          const hasHeight = availableHeights.has(res.height) || Array.from(availableHeights).some(h => h >= res.height);
          if (hasHeight) {
            const matchingVideo = rawFormats.find(f => f.height === res.height && f.vcodec !== 'none') ||
                                  rawFormats.find(f => f.vcodec !== 'none');
            const estimatedBytes = matchingVideo?.filesize || matchingVideo?.filesize_approx;

            videoFormats.push({
              format: 'mp4',
              resolution: `${res.height}p`,
              quality: res.quality,
              label: res.label,
              ext: 'mp4',
              estimatedSize: formatBytes(estimatedBytes),
              codec: matchingVideo?.vcodec ? matchingVideo.vcodec.split('.')[0] : 'h264'
            });
          }
        });

        // If no matching resolution above 360, provide best fallback
        if (videoFormats.length === 0) {
          videoFormats.push({
            format: 'mp4',
            resolution: 'Best Available',
            quality: 'best',
            label: 'Best Available Quality (MP4)',
            ext: 'mp4',
            estimatedSize: null,
            codec: 'auto'
          });
        }

        // Comprehensive Audio Formats
        const audioFormats = [
          {
            format: 'mp3',
            quality: '320',
            label: 'MP3 - High Quality (320 kbps)',
            ext: 'mp3',
            isAudioOnly: true
          },
          {
            format: 'mp3',
            quality: '192',
            label: 'MP3 - Standard Quality (192 kbps)',
            ext: 'mp3',
            isAudioOnly: true
          },
          {
            format: 'mp3',
            quality: '128',
            label: 'MP3 - Normal Quality (128 kbps)',
            ext: 'mp3',
            isAudioOnly: true
          },
          {
            format: 'm4a',
            quality: 'best',
            label: 'M4A / AAC - Original Audio (Fast)',
            ext: 'm4a',
            isAudioOnly: true
          },
          {
            format: 'wav',
            quality: 'lossless',
            label: 'WAV - Uncompressed Studio Audio',
            ext: 'wav',
            isAudioOnly: true
          },
          {
            format: 'flac',
            quality: 'lossless',
            label: 'FLAC - Lossless Audio',
            ext: 'flac',
            isAudioOnly: true
          }
        ];

        const videoInfo = {
          id: raw.id,
          title: raw.title,
          description: raw.description ? raw.description.slice(0, 300) : '',
          thumbnail,
          duration: raw.duration,
          durationFormatted: formatDuration(raw.duration),
          channel: raw.uploader || raw.channel || 'Unknown Channel',
          channelUrl: raw.uploader_url || raw.channel_url,
          viewCount: raw.view_count,
          viewCountFormatted: formatViews(raw.view_count),
          uploadDate: raw.upload_date,
          webpage_url: raw.webpage_url || url,
          videoFormats,
          audioFormats
        };

        resolve(videoInfo);
      } catch (err) {
        reject(new Error(`Failed to parse video information: ${err.message}`));
      }
    });

    child.on('error', (err) => {
      reject(new Error(`Failed to execute yt-dlp: ${err.message}`));
    });
  });
}

/**
 * Start a download job
 */
function startDownload({ url, format, quality, isAudioOnly, title }) {
  const jobId = 'job_' + Date.now() + '_' + Math.random().toString(36).substring(2, 8);
  const cleanTitle = sanitizeFilename(title || 'youtube_download');
  const ext = format || (isAudioOnly ? 'mp3' : 'mp4');
  const finalFilename = `${cleanTitle}.${ext}`;
  const outputTemplate = path.join(DOWNLOADS_DIR, `${jobId}_%(title)s.%(ext)s`);

  const job = {
    id: jobId,
    url,
    title: cleanTitle,
    format,
    quality,
    isAudioOnly,
    finalFilename,
    status: 'initializing', // initializing | downloading | converting | completed | error
    progress: 0,
    speed: '',
    eta: '',
    size: '',
    error: null,
    filePath: null,
    startedAt: Date.now()
  };

  jobs.set(jobId, job);

  const { command, baseArgs, ffmpegLocation } = getExecutionConfig();

  // Build yt-dlp command args
  const args = [
    ...baseArgs,
    '--newline',
    '--no-playlist',
    '--no-check-certificates',
    '--no-mtime',
    '-o', outputTemplate
  ];

  if (ffmpegLocation) {
    args.push('--ffmpeg-location', ffmpegLocation);
  }

  if (isAudioOnly) {
    args.push('-x'); // Extract audio
    args.push('--audio-format', format || 'mp3');
    if (format === 'mp3') {
      const bit = quality === '320' ? '320k' : quality === '192' ? '192k' : '128k';
      args.push('--audio-quality', bit);
    }
  } else {
    // Video with audio merged
    const q = quality || '1080';
    if (format === 'webm') {
      args.push('-f', `bestvideo[height<=${q}][ext=webm]+bestaudio[ext=webm]/bestvideo[height<=${q}]+bestaudio/best[height<=${q}]`);
      args.push('--merge-output-format', 'webm');
    } else {
      // Default MP4 with AAC
      args.push('-f', `bestvideo[height<=${q}][ext=mp4]+bestaudio[ext=m4a]/bestvideo[height<=${q}]+bestaudio/best[height<=${q}]`);
      args.push('--merge-output-format', 'mp4');
    }
  }

  args.push(url);

  const child = spawn(command, args);

  job.status = 'downloading';

  child.stdout.on('data', (chunk) => {
    const text = chunk.toString();
    // Parse download progress: [download]  45.2% of ~  25.40MiB at  4.12MiB/s ETA 00:03
    const match = text.match(/\[download\]\s+(\d+\.?\d*)%\s+of\s+~?([^\s]+)\s+at\s+([^\s]+)\s+ETA\s+([^\s]+)/);
    if (match) {
      job.progress = parseFloat(match[1]);
      job.size = match[2];
      job.speed = match[3];
      job.eta = match[4];
      job.status = 'downloading';
    } else if (text.includes('[ExtractAudio]') || text.includes('[Merger]') || text.includes('[Fixup]')) {
      job.status = 'converting';
      job.progress = 98;
    }
  });

  child.stderr.on('data', (chunk) => {
    const text = chunk.toString();
    if (text.includes('ERROR:')) {
      job.error = text.trim();
    }
  });

  child.on('close', (code) => {
    if (code !== 0) {
      job.status = 'error';
      job.error = job.error || `Process exited with error code ${code}`;
      return;
    }

    // Locate the resulting file in DOWNLOADS_DIR matching jobId
    fs.readdir(DOWNLOADS_DIR, (err, files) => {
      if (err) {
        job.status = 'error';
        job.error = 'Failed to locate downloaded file';
        return;
      }

      const matchFile = files.find(f => f.startsWith(jobId));
      if (matchFile) {
        job.filePath = path.join(DOWNLOADS_DIR, matchFile);
        job.status = 'completed';
        job.progress = 100;
      } else {
        job.status = 'error';
        job.error = 'Downloaded file not found on server';
      }
    });
  });

  child.on('error', (err) => {
    job.status = 'error';
    job.error = err.message;
  });

  return jobId;
}

/**
 * Get job status
 */
function getJobStatus(jobId) {
  return jobs.get(jobId) || null;
}

module.exports = {
  getVideoInfo,
  startDownload,
  getJobStatus,
  getExecutionConfig,
  DOWNLOADS_DIR
};
