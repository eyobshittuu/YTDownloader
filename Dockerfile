# Use official lightweight Node.js 20 LTS base image
FROM node:20-bullseye-slim

# Install FFmpeg, Python 3, and yt-dlp
RUN apt-get update && apt-get install -y --no-install-recommends \
    ffmpeg \
    python3 \
    python3-pip \
    curl \
    ca-certificates \
 && pip3 install --no-cache-dir yt-dlp \
 && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy package descriptors and install dependencies
COPY package*.json ./
RUN npm ci --only=production

# Copy application files
COPY . .

# Ensure bin directory has execute permissions on Linux
RUN chmod +x bin/yt-dlp 2>/dev/null || true

# Set environment
ENV NODE_ENV=production
ENV PORT=5000

# Expose port
EXPOSE 5000

# Start server
CMD ["node", "index.js"]

