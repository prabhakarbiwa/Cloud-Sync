#!/bin/bash

# build-apk.sh - Convenient APK builder for Cloud-Sync Android Application
# 
# This script provides a simple one-command solution for building the Cloud-Sync APK
# with comprehensive prerequisite checks, progress indicators, and error handling.
#
# Usage: ./build-apk.sh [--test-only]
#   --test-only: Only run prerequisite checks without building

set -e  # Exit on any error

# Parse command line arguments
TEST_ONLY=false
SHOW_HELP=false

for arg in "$@"; do
    case $arg in
        --test-only)
            TEST_ONLY=true
            shift
            ;;
        --help|-h)
            SHOW_HELP=true
            shift
            ;;
        *)
            echo "Unknown option: $arg"
            SHOW_HELP=true
            ;;
    esac
done

if [ "$SHOW_HELP" = true ]; then
    echo "Cloud-Sync APK Builder"
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --test-only    Only run prerequisite checks without building"
    echo "  --help, -h     Show this help message"
    echo ""
    echo "This script builds a release APK for the Cloud-Sync Android application"
    echo "targeting the arm64-v8a architecture (most common for modern Android devices)."
    echo ""
    echo "Prerequisites:"
    echo "  - Go 1.20 or later"
    echo "  - Java 17 or later"
    echo "  - Run from Cloud-Sync project root directory"
    echo ""
    echo "Build time: 5-10 minutes for first build (due to rclone compilation)"
    echo "Output: app/build/outputs/apk/oss/release/"
    echo ""
    exit 0
fi

# Color codes for better output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Progress indicator function
show_progress() {
    local message="$1"
    echo -e "${CYAN}🔄 ${message}${NC}"
}

# Success indicator function
show_success() {
    local message="$1"
    echo -e "${GREEN}✅ ${message}${NC}"
}

# Error indicator function
show_error() {
    local message="$1"
    echo -e "${RED}❌ ${message}${NC}"
}

# Warning indicator function
show_warning() {
    local message="$1"
    echo -e "${YELLOW}⚠️  ${message}${NC}"
}

# Info indicator function
show_info() {
    local message="$1"
    echo -e "${BLUE}ℹ️  ${message}${NC}"
}

# Function to check command existence
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check version requirements
check_version() {
    local command="$1"
    local required_version="$2"
    local version_check="$3"
    
    if eval "$version_check"; then
        return 0
    else
        return 1
    fi
}

# Function to extract version numbers for comparison
version_compare() {
    local version1="$1"
    local version2="$2"
    local op="$3"
    
    # Extract major.minor version parts
    local v1=$(echo "$version1" | grep -oE '[0-9]+\.[0-9]+' | head -1)
    local v2=$(echo "$version2" | grep -oE '[0-9]+\.[0-9]+' | head -1)
    
    # Convert to comparable format (remove dots)
    local v1_num=$(echo "$v1" | sed 's/\.//')
    local v2_num=$(echo "$v2" | sed 's/\.//')
    
    # Pad to same length for comparison
    while [ ${#v1_num} -lt ${#v2_num} ]; do
        v1_num="${v1_num}0"
    done
    while [ ${#v2_num} -lt ${#v1_num} ]; do
        v2_num="${v2_num}0"
    done
    
    case "$op" in
        ">=")
            [ "$v1_num" -ge "$v2_num" ]
            ;;
        ">")
            [ "$v1_num" -gt "$v2_num" ]
            ;;
        "=")
            [ "$v1_num" -eq "$v2_num" ]
            ;;
    esac
}

# Main script start
echo
echo -e "${CYAN}📱 Cloud-Sync APK Builder${NC}"
echo -e "${CYAN}================================${NC}"
echo
echo "Building a release APK for the Cloud-Sync Android application."
echo "Target: arm64-v8a architecture (most common for modern Android devices)"
echo

# Step 1: Check prerequisites
show_progress "Checking prerequisites..."
echo

# Check Go version
show_progress "Checking Go installation..."
if ! command_exists go; then
    show_error "Go is not installed or not in PATH"
    echo -e "${NC}Please install Go 1.20 or later from: https://golang.org/dl/"
    exit 1
fi

GO_VERSION=$(go version | grep -oE 'go[0-9]+\.[0-9]+' | sed 's/go//')
if version_compare "$GO_VERSION" "1.20" ">="; then
    show_success "Go $GO_VERSION (meets requirement: 1.20+)"
else
    show_error "Go version $GO_VERSION is too old (required: 1.20+)"
    echo -e "${NC}Please upgrade Go from: https://golang.org/dl/"
    exit 1
fi

# Check Java version  
show_progress "Checking Java installation..."
if ! command_exists java; then
    show_error "Java is not installed or not in PATH"
    echo -e "${NC}Please install Java 17 or later from: https://adoptium.net/"
    exit 1
fi

JAVA_VERSION=$(java --version 2>/dev/null | head -1 | grep -oE '[0-9]+' | head -1)
if [ -z "$JAVA_VERSION" ]; then
    # Fallback for older Java versions
    JAVA_VERSION=$(java -version 2>&1 | head -1 | grep -oE '1\.[0-9]+|[0-9]+' | head -1 | sed 's/1\.//')
fi

if [ "$JAVA_VERSION" -ge 17 ]; then
    show_success "Java $JAVA_VERSION (meets requirement: 17+)"
else
    show_error "Java version $JAVA_VERSION is too old (required: 17+)"
    echo -e "${NC}Please upgrade Java from: https://adoptium.net/"
    exit 1
fi

# Check Gradle wrapper
show_progress "Checking Gradle wrapper..."
if [ ! -f "./gradlew" ]; then
    show_error "Gradle wrapper (gradlew) not found in current directory"
    echo -e "${NC}Please run this script from the Cloud-Sync project root directory"
    exit 1
fi

if [ ! -x "./gradlew" ]; then
    show_warning "Making gradlew executable..."
    chmod +x ./gradlew
fi

show_success "Gradle wrapper found and ready"

echo
show_success "All prerequisites satisfied!"

if [ "$TEST_ONLY" = true ]; then
    echo
    show_info "Test mode: Prerequisites check completed successfully!"
    echo -e "${CYAN}🚀 To build APKs, run: ./build-apk.sh${NC}"
    echo -e "${NC}   This will build release APKs for all architectures (arm64-v8a highlighted)"
    echo -e "${NC}   Expected build time: 5-10 minutes for first build"
    echo -e "${NC}   Output location: app/build/outputs/apk/oss/release/"
    echo
    show_success "Script validation completed! 🎉"
    exit 0
fi

echo

# Step 2: Clean previous builds (optional but recommended)
show_progress "Cleaning previous builds..."
if ./gradlew clean --no-daemon --quiet; then
    show_success "Previous builds cleaned"
else
    show_warning "Clean failed, continuing anyway..."
fi

echo

# Step 3: Start the build process
show_progress "Starting APK build process..."
echo -e "${NC}This will build release APKs for all architectures (arm64-v8a highlighted)"
echo -e "${YELLOW}Note: First build may take 5-10 minutes due to rclone native compilation${NC}"
echo

# Build with progress indication
show_progress "Building Cloud-Sync release APKs..."
echo -e "${NC}Running: ./gradlew assembleOssRelease"
echo

# Run the actual build
if ./gradlew assembleOssRelease --no-daemon; then
    echo
    show_success "APK build completed successfully!"
else
    echo
    show_error "APK build failed!"
    echo -e "${NC}Check the error messages above for details."
    echo -e "${NC}You can also try:"
    echo -e "${NC}  1. Run './test-build-config.sh' to validate your setup"
    echo -e "${NC}  2. Check that all dependencies are properly installed"
    echo -e "${NC}  3. Ensure you have enough disk space and memory"
    exit 1
fi

echo

# Step 4: Locate and display built APKs
show_progress "Locating built APKs..."

APK_DIR="app/build/outputs/apk/oss/release"

if [ ! -d "$APK_DIR" ]; then
    show_error "APK output directory not found: $APK_DIR"
    echo -e "${NC}This could indicate the build failed or the output path has changed."
    echo -e "${NC}Please check the build output above for errors."
    exit 1
fi

echo
show_success "APKs built successfully!"
echo
echo -e "${CYAN}📦 Built APKs Location:${NC}"
echo -e "${NC}  Directory: $APK_DIR"
echo

# List all built APKs with file sizes
if ls "$APK_DIR"/*.apk >/dev/null 2>&1; then
    echo -e "${CYAN}📱 Available APK Files:${NC}"
    for apk in "$APK_DIR"/*.apk; do
        if [ -f "$apk" ]; then
            filename=$(basename "$apk")
            filesize=$(ls -lh "$apk" | awk '{print $5}')
            if [[ "$filename" == *"arm64-v8a"* ]]; then
                echo -e "${GREEN}  🎯 $filename ($filesize) ${NC}${CYAN}<-- RECOMMENDED${NC}"
            else
                echo -e "${NC}     $filename ($filesize)"
            fi
        fi
    done
else
    show_error "No APK files found in $APK_DIR"
    echo -e "${NC}This indicates the build may have failed. Check the output above."
    exit 1
fi

echo

# Step 5: Final instructions
# Find the actual arm64-v8a APK (pattern may vary)
ARM64_APK=$(ls "$APK_DIR"/*arm64-v8a-release.apk 2>/dev/null | head -1)

if [ -n "$ARM64_APK" ] && [ -f "$ARM64_APK" ]; then
    show_success "Target APK (arm64-v8a) ready for installation!"
    echo
    echo -e "${CYAN}🚀 Installation Instructions:${NC}"
    echo -e "${NC}  1. Copy the APK to your Android device:"
    echo -e "${GREEN}     $ARM64_APK${NC}"
    echo -e "${NC}  2. Enable 'Install from Unknown Sources' in Android settings"
    echo -e "${NC}  3. Open the APK file on your device to install"
    echo
    echo -e "${CYAN}💡 Quick Install Command:${NC}"
    echo -e "${NC}  adb install \"$ARM64_APK\""
    echo
else
    show_warning "arm64-v8a APK not found at expected location"
    echo -e "${NC}Check the APK directory listing above for available files."
fi

# Show additional info
echo -e "${BLUE}ℹ️  Build Information:${NC}"
echo -e "${NC}  • Architecture: arm64-v8a (recommended for most modern Android devices)"
echo -e "${NC}  • Build Type: Release (optimized, signed)"
echo -e "${NC}  • Flavor: OSS (Open Source build)"
echo -e "${NC}  • Target SDK: 34 (Android 14)"
echo -e "${NC}  • Minimum SDK: 23 (Android 6.0)"

echo
show_success "Build process completed! 🎉"
echo