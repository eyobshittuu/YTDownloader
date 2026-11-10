#!/bin/bash
# Render Build Script
# Ensures yt-dlp is installed and updated

echo "=== Render Build Script ==="
echo ""

# Install Node dependencies
echo "📦 Installing Node dependencies..."
npm install

echo ""

# Install/Update yt-dlp
echo "🎬 Installing/Updating yt-dlp..."

# Try pip first
if command -v pip &> /dev/null; then
    echo "   Using pip..."
    pip install -U yt-dlp --break-system-packages || pip install -U yt-dlp || {
        echo "   ⚠️  pip install failed, trying pip3..."
        pip3 install -U yt-dlp --break-system-packages || pip3 install -U yt-dlp
    }
elif command -v pip3 &> /dev/null; then
    echo "   Using pip3..."
    pip3 install -U yt-dlp --break-system-packages || pip3 install -U yt-dlp
else
    echo "   ⚠️  pip not found, downloading binary..."
    mkdir -p bin
    curl -L https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp -o bin/yt-dlp
    chmod +x bin/yt-dlp
fi

echo ""

# Verify installation
echo "✅ Verifying yt-dlp installation..."
if command -v yt-dlp &> /dev/null; then
    YT_DLP_VERSION=$(yt-dlp --version)
    echo "   yt-dlp version: $YT_DLP_VERSION"
elif python -m yt_dlp --version &> /dev/null; then
    YT_DLP_VERSION=$(python -m yt_dlp --version)
    echo "   yt-dlp version (Python module): $YT_DLP_VERSION"
elif [ -f bin/yt-dlp ]; then
    YT_DLP_VERSION=$(bin/yt-dlp --version)
    echo "   yt-dlp version (local binary): $YT_DLP_VERSION"
else
    echo "   ⚠️  WARNING: Could not verify yt-dlp installation"
fi

echo ""
echo "=== Build Complete ==="
