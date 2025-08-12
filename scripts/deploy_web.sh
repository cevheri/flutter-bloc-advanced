#!/bin/bash

# Flutter Web Build and Deploy Script
# This script builds the Flutter web app and prepares it for deployment

set -e  # Exit on any error

echo "🚀 Starting Flutter Web Build and Deploy Process..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if we're in the correct directory
if [ ! -f "pubspec.yaml" ]; then
    print_error "pubspec.yaml not found. Please run this script from the Flutter project root."
    exit 1
fi

# Clean previous builds
print_status "Cleaning previous builds..."
flutter clean

# Get dependencies
print_status "Getting dependencies..."
flutter pub get

# Generate localization files
print_status "Generating localization files..."
flutter gen-l10n

# Build for web
print_status "Building for web..."
flutter build web \
    --base-href /flutter-bloc-advanced/ \
    --target lib/main/main_local.dart \
    --release

# Check if build was successful
if [ $? -eq 0 ]; then
    print_success "Web build completed successfully!"
    
    # Display build information
    print_status "Build information:"
    echo "  - Build directory: build/web/"
    echo "  - Main file: build/web/main.dart.js"
    echo "  - Index file: build/web/index.html"
    
    # Show file sizes
    if [ -f "build/web/main.dart.js" ]; then
        MAIN_JS_SIZE=$(du -h build/web/main.dart.js | cut -f1)
        print_status "Main.dart.js size: $MAIN_JS_SIZE"
    fi
    
    # List all files in build directory
    print_status "Build directory contents:"
    ls -la build/web/
    
    print_success "🎉 Build process completed! Your web app is ready for deployment."
    print_status "You can now deploy the contents of 'build/web/' to your web server."
    
    # Optional: Create a deployment package
    if [ "$1" = "--package" ]; then
        print_status "Creating deployment package..."
        tar -czf flutter_web_deploy_$(date +%Y%m%d_%H%M%S).tar.gz -C build web/
        print_success "Deployment package created!"
    fi
    
else
    print_error "Build failed! Please check the error messages above."
    exit 1
fi

print_status "Deployment script completed successfully!" 