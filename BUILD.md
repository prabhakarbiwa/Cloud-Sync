# Building Cloud-Sync (Round Sync)

This document provides instructions for building the Cloud-Sync Android application from source.

## Prerequisites

Before building, ensure you have the following installed:

- **Go 1.20+** - Required for building the rclone native components
- **Java 17+** - Required for the Android build system
- **Android SDK** with command-line tools OR the NDK version specified in `gradle.properties`
- **Git** - For cloning the repository

## Building from Source

### 1. Clone the Repository

```bash
git clone https://github.com/prabhakarbiwa/Cloud-Sync.git
cd Cloud-Sync
```

### 2. Build Debug APK (Recommended for Development)

```bash
./gradlew assembleOssDebug
```

This creates a debug APK with:
- Debug signing (no production keystore required)
- Debug application ID suffix (`.debug`)
- Debug app name and icon
- All debugging features enabled

### 3. Build Release APK

```bash
./gradlew assembleOssRelease
```

For production release builds, you can:

#### Option A: Use Debug Signing (Default)
The build system automatically falls back to debug signing if no production keystore is provided. This is suitable for testing and development.

#### Option B: Use Production Keystore
For official releases, create the production keystore:

1. Create the keystore directory:
   ```bash
   mkdir -p app/.config/android
   ```

2. Generate or copy your production keystore:
   ```bash
   # Generate new keystore (for new projects)
   keytool -genkey -v -keystore app/.config/android/roundsync.keystore \
           -alias fdroid -keyalg RSA -keysize 2048 -validity 10000

   # OR copy your existing keystore
   cp /path/to/your/keystore app/.config/android/roundsync.keystore
   ```

3. Set keystore passwords in `gradle.properties` or environment variables:
   ```properties
   KEYSTORE_PASSWORD=your_keystore_password
   KEY_PASSWORD=your_key_password
   ```

### 4. Build All Variants

```bash
# Build all debug variants
./gradlew assembleDebug

# Build all release variants  
./gradlew assembleRelease

# Build everything
./gradlew assemble
```

## Available Build Variants

The project includes multiple build variants:

### Flavors
- **oss** - Open Source build (recommended for most users)
- **rs** - GitHub/Google Play build

### Build Types
- **debug** - Development build with debugging enabled
- **release** - Production build with optimizations

### Architecture Splits
APKs are generated for multiple architectures:
- `armeabi-v7a` - ARM 32-bit (older devices)
- `arm64-v8a` - ARM 64-bit (most modern devices) **[Recommended]**
- `x86` - Intel/AMD 32-bit (some tablets/TV boxes)
- `x86_64` - Intel/AMD 64-bit (emulators)
- `universal` - All architectures (larger file size)

## Output Locations

Built APKs are located in:
```
app/build/outputs/apk/
├── oss/
│   ├── debug/
│   │   ├── app-oss-arm64-v8a-debug.apk
│   │   ├── app-oss-armeabi-v7a-debug.apk
│   │   ├── app-oss-universal-debug.apk
│   │   ├── app-oss-x86-debug.apk
│   │   └── app-oss-x86_64-debug.apk
│   └── release/
│       ├── app-oss-arm64-v8a-release.apk
│       ├── app-oss-armeabi-v7a-release.apk
│       ├── app-oss-universal-release.apk
│       ├── app-oss-x86-release.apk
│       └── app-oss-x86_64-release.apk
└── rs/
    ├── debug/
    └── release/
```

## Quick Build Scripts

**🚀 Convenient One-Command Solution:**

```bash
# Build release APK with automatic prerequisite checks (RECOMMENDED)
./build-apk.sh

# Test prerequisites without building
./build-apk.sh --test-only

# Show help and options
./build-apk.sh --help
```

The `build-apk.sh` script provides:
- ✅ Automatic prerequisite validation (Go 1.20+, Java 17+)
- ✅ Clear progress indicators and error handling
- ✅ Highlights the recommended arm64-v8a APK
- ✅ Shows final APK location and installation instructions

**Manual Gradle Commands:**

For convenience, you can also use these direct Gradle commands:

```bash
# Quick debug build (fastest)
./gradlew assembleOssDebug

# Quick release build
./gradlew assembleOssRelease

# Build with clean (recommended for release)
./gradlew clean assembleOssRelease

# Build specific architecture only
./gradlew assembleOssReleaseArm64_v8a
```

## Troubleshooting

### Common Issues

1. **Build fails with Go/NDK errors**: Ensure Go 1.20+ is installed and in your PATH
2. **Out of memory errors**: Add to `gradle.properties`:
   ```properties
   org.gradle.jvmargs=-Xmx4g -Dfile.encoding=UTF-8
   ```
3. **Long build times**: The first build downloads and compiles rclone, which takes 5-10 minutes

### Build Environment

You can check your build environment with:
```bash
./gradlew --version
go version
java --version
```

## CI/CD

For automated builds, ensure:
- Go is available in the build environment
- Android SDK is properly configured
- Consider using Gradle Build Cache for faster builds

## Contributing

When contributing:
- Always test both debug and release builds
- Ensure builds work without production keystores
- Update this guide if build requirements change

For more information, see [CONTRIBUTING.md](CONTRIBUTING.md).