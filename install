#!/bin/bash

# TweakCompiler Installation Script
# This script installs TweakCompiler directly on the device

echo "📱 Installing TweakCompiler..."

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "❌ Please run as root (use 'sudo' or 'su')"
    exit 1
fi

# Check if Theos is installed
if [ ! -d "$THEOS" ]; then
    echo "❌ Theos not found! Please install Theos first."
    echo "   Visit: https://theos.dev/docs/installation"
    exit 1
fi

# Build and install
echo "🔨 Building and installing TweakCompiler..."

# Clean previous builds
make clean

# Build the package
make package

# Install the package
if [ $? -eq 0 ]; then
    echo "📦 Installing package..."
    make install
    
    if [ $? -eq 0 ]; then
        echo "✅ Installation successful!"
        echo "📱 TweakCompiler has been installed to /Applications/"
        echo "🔄 Respringing device..."
        uicache
        echo "📱 TweakCompiler will appear on your home screen!"
    else
        echo "❌ Installation failed!"
        exit 1
    fi
else
    echo "❌ Build failed!"
    exit 1
fi
