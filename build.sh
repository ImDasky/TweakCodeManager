#!/bin/bash

# TweakCompiler Build Script
# This script compiles TweakCompiler as a .deb package using Theos

echo "🔨 Building TweakCompiler..."

# Check if Theos is installed
if [ ! -d "$THEOS" ]; then
    echo "❌ Theos not found! Please install Theos first."
    echo "   Visit: https://theos.dev/docs/installation"
    exit 1
fi

# Clean previous builds
echo "🧹 Cleaning previous builds..."
make clean

# Build the package
echo "📦 Building package..."
make package

# Check if build was successful
if [ $? -eq 0 ]; then
    echo "✅ Build successful!"
    echo "📱 Package created in packages/ directory"
    
    # List created packages
    echo "📋 Created packages:"
    ls -la packages/*.deb 2>/dev/null || echo "   No .deb files found"
    
    echo ""
    echo "🚀 Installation instructions:"
    echo "   1. Copy the .deb file to your device"
    echo "   2. Install using Sileo, Zebra, or Filza"
    echo "   3. Respring your device"
    echo ""
    echo "📱 TweakCompiler will appear on your home screen!"
else
    echo "❌ Build failed!"
    exit 1
fi
