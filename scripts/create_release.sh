#!/bin/bash

# SoDak Weather Release Script
# This script helps create a new release by building the APK and creating a git tag

set -e  # Exit on any error

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

# Check if version is provided
if [ $# -eq 0 ]; then
    print_error "Please provide a version number (e.g., ./create_release.sh 1.0.0)"
    echo "Usage: $0 <version>"
    echo "Example: $0 1.0.0"
    exit 1
fi

VERSION=$1
TAG_NAME="v$VERSION"

print_status "Creating release for version $VERSION"

# Check if we're in the right directory
if [ ! -f "pubspec.yaml" ]; then
    print_error "This script must be run from the project root directory"
    exit 1
fi

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    print_error "Flutter is not installed or not in PATH"
    exit 1
fi

# Check if git is available
if ! command -v git &> /dev/null; then
    print_error "Git is not installed or not in PATH"
    exit 1
fi

# Check if tag already exists
if git tag -l | grep -q "^$TAG_NAME$"; then
    print_error "Tag $TAG_NAME already exists"
    exit 1
fi

print_status "Cleaning previous builds..."
flutter clean

print_status "Getting dependencies..."
flutter pub get

print_status "Building APK for release..."
flutter build apk --release

# Check if build was successful
if [ ! -f "build/app/outputs/flutter-apk/app-release.apk" ]; then
    print_error "APK build failed"
    exit 1
fi

print_success "APK built successfully!"

# Get APK size
APK_SIZE=$(du -h build/app/outputs/flutter-apk/app-release.apk | cut -f1)
print_status "APK size: $APK_SIZE"

# Create git tag
print_status "Creating git tag $TAG_NAME..."
git tag -a "$TAG_NAME" -m "Release version $VERSION"

print_status "Pushing tag to remote..."
git push origin "$TAG_NAME"

print_success "Release $VERSION created successfully!"
echo ""
print_status "Next steps:"
echo "1. The GitHub Action will automatically build and create a release"
echo "2. Check the Actions tab in your GitHub repository for build progress"
echo "3. Once complete, the APK will be available at:"
echo "   https://github.com/hawkstwelve/sodak_weather/releases/tag/$TAG_NAME"
echo ""
print_status "Local APK location: build/app/outputs/flutter-apk/app-release.apk" 