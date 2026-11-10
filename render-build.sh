#!/bin/bash
# Render Build Script
# Ensures yt-dlp is installed and updated to the LATEST version

echo "=== Render Build Script ==="
echo ""

# Install Node dependencies
echo "📦 Installing Node dependencies..."
npm install

echo ""

# Install/Update yt-dlp to LATEST (nightly if needed)
echo "🎬 Installing/Updating yt-dlp to LATEST version..."

# Try pip first with nightly build
if command -v pip &> /dev/null; then
    echo "   Using pip for latest yt-dlp..."
    # Try stable version first
    pip install -U yt-dlp --break-system-packages 2>/dev/null || pip install -U yt-dlp 2>/dev/null
    
    # If still failing, try nightly build
    if ! python -m yt_dlp --version &> /dev/null; then
        echo "   Installing nightly build for latest fixes..."
        pip install -U --pre yt-dlp --break-system-packages 2>/dev/null || pip install -U --pre yt-dlp 2>/dev/null
    fi
elif command -v pip3 &> /dev/null; then
    echo "   Using pip3 for latest yt-dlp..."
    pip3 install -U yt-dlp --break-system-packages 2>/dev/null || pip3 install -U yt-dlp 2>/dev/null
    
    # If still failing, try nightly build
    if ! python3 -m yt_dlp --version &> /dev/null; then
        echo "   Installing nightly build for latest fixes..."
        pip3 install -U --pre yt-dlp --break-system-packages 2>/dev/null || pip3 install -U --pre yt-dlp 2>/dev/null
    fi
else
    echo "   ⚠️  pip not found, downloading latest binary..."
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
elif python3 -m yt_dlp --version &> /dev/null; then
    YT_DLP_VERSION=$(python3 -m yt_dlp --version)
    echo "   yt-dlp version (Python3 module): $YT_DLP_VERSION"
elif [ -f bin/yt-dlp ]; then
    YT_DLP_VERSION=$(bin/yt-dlp --version)
    echo "   yt-dlp version (local binary): $YT_DLP_VERSION"
else
    echo "   ⚠️  WARNING: Could not verify yt-dlp installation"
fi

echo ""
echo "=== Build Complete ==="
