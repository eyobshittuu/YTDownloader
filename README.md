# 🚀 FAB Downloader — 4K YouTube Video & Audio Engine

A high-performance media extraction web application built with **Node.js**, **Express**, **yt-dlp**, and **FFmpeg**, featuring an interactive **Antigravity WebGL2** particle simulation background and a sleek **ShapeWaves** intro preloader.

---

## ✨ Features

- **📺 Ultra HD Video Downloads**: Download YouTube videos in **4K (2160p)**, **2K (1440p)**, **1080p Full HD**, **720p HD**, **480p**, and **360p** in standard `.mp4` format.
- **🎵 Studio-Quality Audio**: Extract high-fidelity audio in **MP3 (320kbps, 192kbps, 128kbps)**, **M4A / AAC**, **WAV**, and **FLAC** lossless formats.
- **⚡ Real-Time Progress Tracking**: Live Server-Sent Events (SSE) update the frontend with instant download speeds (MB/s), ETA, and percentage completion.
- **✨ 3D Antigravity Particle Background**: 1,500 interactive WebGL2 particles reacting dynamically to cursor position, magnetic fields, and click bursts.
- **🌊 ShapeWaves Preloader**: Smooth geometric wave simulation intro (`</>` shape mask) with automatic transition.
- **🏷️ Signature FAB Downloader UI**: Custom clean light theme with ice-blue accents, signature pill badge, and bold red action buttons.
- **🔄 Automated Stream Merging**: Seamlessly combines high-res video and audio streams using local **FFmpeg**.
- **🧹 Automatic Storage Cleanup**: Server auto-purges temporary media files after 30 minutes to preserve disk space.

---

## 📁 Project Structure

```text
YTDownloader/
├── bin/
│   └── yt-dlp.exe          # Standalone yt-dlp binary (Windows)
├── public/
│   ├── css/
│   │   └── antigravity.css # Antigravity canvas styling
│   ├── js/
│   │   ├── antigravity.js  # Antigravity WebGL2 particle simulation
│   │   └── shapewaves.js   # ShapeWaves 2D canvas simulation
│   └── index.html          # Main application interface
├── services/
│   └── ytDlpService.js     # yt-dlp engine wrapper & background job manager
├── temp_downloads/         # Temporary download cache directory (auto-managed)
├── index.js                # Express API & static server
├── package.json            # Node.js dependencies & scripts
└── README.md               # Documentation
```

---

## 🚀 Quick Start

### 1. Prerequisites
- **Node.js** (v18 or higher recommended)
- **FFmpeg** installed and accessible in system PATH (or WinGet)

### 2. Installation
Clone the repository and install dependencies:

```bash
git clone https://github.com/eyobshittuu/YTDownloader.git
cd YTDownloader
npm install
```

### 3. Start the Server

```bash
npm start
```

Open your browser and navigate to:
```
http://localhost:5000
```

---

## 📡 API Endpoints

| Method | Endpoint                    | Description                                                    |
| :----- | :-------------------------- | :------------------------------------------------------------- |
| `GET`  | `/api/health`               | Health check endpoint                                          |
| `POST` | `/api/info`                 | Fetches metadata and available formats for a given YouTube URL |
| `POST` | `/api/download`             | Starts a download job with selected format and quality         |
| `GET`  | `/api/events/:jobId`        | Server-Sent Events (SSE) stream for live download progress     |
| `GET`  | `/api/progress/:jobId`      | Standard JSON status polling endpoint for a job                |
| `GET`  | `/api/download/file/:jobId` | Streams the finished file to the browser                       |

---

## 📄 License
MIT License. Free for personal and educational use.
