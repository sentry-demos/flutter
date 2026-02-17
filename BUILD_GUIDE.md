# Build Guide - Multi-Platform Flutter with Sentry

This guide explains how to use the unified `demo.sh` script to build your Flutter application for all platforms with automatic Sentry release management and instrumentation.

## Quick Start

```bash
# Verify setup
./demo.sh verify

# Build for Android APK
./demo.sh build android

# Build for Android App Bundle (preferred)
./demo.sh build aab

# Build for iOS
./demo.sh build ios

# Build for Web
./demo.sh build web

# Run the app
./demo.sh run android
```

## Complete Usage

```bash
./demo.sh build [platform] [build-type]
./demo.sh run [platform]
./demo.sh verify
```

### Supported Platforms

| Platform | Command | OS Requirement | Output Location |
|----------|---------|----------------|-----------------|
| Android APK | `./demo.sh build android` | Any | `build/app/outputs/flutter-apk/app-release.apk` |
| Android AAB | `./demo.sh build aab` | Any | `build/app/outputs/bundle/release/app-release.aab` |
| iOS | `./demo.sh build ios` | macOS only | `build/ios/iphoneos/Runner.app` |
| Web | `./demo.sh build web` | Any | `build/web/` |
| macOS | `./demo.sh build macos` | macOS only | `build/macos/Build/Products/Release/empower_flutter.app` |
| Linux | `./demo.sh build linux` | Linux preferred | `build/linux/x64/release/bundle/` |
| Windows | `./demo.sh build windows` | Windows only | `build/windows/x64/runner/Release/` |

### Build Types

| Type | Command | Description | Obfuscation | Release Management |
|------|---------|-------------|-------------|-------------------|
| Release | `./demo.sh build android` | Production build | ✅ Yes | ✅ Yes |
| Profile | `./demo.sh build android profile` | Performance profiling | ❌ No | ❌ No |
| Debug | `./demo.sh build android debug` | Development build | ❌ No | ❌ No |

**Default:** Release build with obfuscation, symbol upload, and automatic release management

## What the Script Does

### 1. Environment Setup
- Checks for Flutter installation
- Loads environment variables from `.env` file
- Validates platform compatibility

### 2. Dependency Management
- Runs `flutter pub get` to ensure all dependencies are up to date

### 3. Platform Build
- Executes platform-specific build command
- For **release builds**:
  - Enables code obfuscation (`--obfuscate`)
  - Generates debug symbols (`--split-debug-info`)
  - Includes Sentry environment variables
- For **debug/profile builds**:
  - Standard build without obfuscation

### 4. Sentry Integration (Release Only)
- Automatically uploads debug symbols to Sentry
- Uploads source maps (for web)
- Associates symbols with release version
- **Optional:** Uploads builds for size analysis (when enabled)

## Platform-Specific Examples

### Android Development

```bash
# Debug build for testing
./demo.sh build android debug

# Release build for distribution
./demo.sh build android release
```

After building, install on emulator:
```bash
# Find the APK
find . -name '*.apk'

# Drag and drop to emulator, or use adb:
adb install build/app/outputs/flutter-apk/app-release.apk
```

### iOS Development

```bash
# Debug build
./demo.sh build ios debug

# Release build
./demo.sh build ios release
```

Then open in Xcode:
```bash
open ios/Runner.xcworkspace
```

### Web Development

```bash
# Build for web
./demo.sh build web release

# Serve locally for testing
cd build/web
python3 -m http.server 8000
```

Open browser to `http://localhost:8000`

### macOS Desktop

```bash
# Build macOS app
./demo.sh build macos release
```

Run the app:
```bash
open build/macos/Build/Products/Release/empower_flutter.app
```

### Building for All Platforms

```bash
# Build everything available on your OS
./demo.sh build all release
```

**On macOS:** Builds Android, iOS, Web, and macOS
**On Linux:** Builds Android, Web, and Linux
**On Windows:** Builds Android, Web, and Windows

## Configuring Sentry Symbol Upload

The script automatically uploads symbols for release builds if Sentry is configured.

### Option 1: Using .env (Recommended)

Add to your `.env` file:
```bash
SENTRY_DSN=https://your-key@o0.ingest.sentry.io/0000000
SENTRY_RELEASE=myapp@1.0.0+1
SENTRY_ENVIRONMENT=production
```

### Option 2: Using sentry.properties

Create `sentry.properties`:
```properties
org=your-org-slug
project=your-project-name
auth_token=your-sentry-auth-token
```

### Creating a Sentry Auth Token

1. Visit: https://sentry.io/settings/account/api/auth-tokens/
2. Click "Create New Token"
3. Name: "Flutter Debug Symbol Upload"
4. Scopes: `project:releases` (or `project:write`) and `org:read`
5. Copy the token to `sentry.properties`

## Size Analysis

Monitor your app's build sizes to prevent regressions and optimize downloads.

### Enable Size Analysis

**Prerequisites:**
- Install Sentry CLI: `curl -sL https://sentry.io/get-cli/ | bash`
- Configure Sentry auth token (see above)

**Configuration:**

Add to your `.env` file:
```bash
SENTRY_SIZE_ANALYSIS_ENABLED=true
SENTRY_ORG=your-org-slug
SENTRY_PROJECT=your-project-slug
```

**Usage:**

```bash
# Build with size analysis
./demo.sh build android release
```

The script will automatically:
1. Build your app
2. Upload debug symbols
3. **Upload build for size analysis**

**Output:**
```
✓ Android APK built successfully
ℹ APK location: build/app/outputs/flutter-apk/app-release.apk

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Uploading Android Build for Size Analysis
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✓ Size analysis data uploaded successfully
ℹ View results: https://sentry.io/organizations/your-org/projects/your-project/size-analysis/
```

**Supported Platforms:**
- ✅ **Android** - APK/AAB automatic upload
- ⚠️ **iOS** - Requires manual IPA creation and upload (see [SIZE_ANALYSIS_GUIDE.md](SIZE_ANALYSIS_GUIDE.md))

For detailed instructions and CI/CD integration, see the [Size Analysis Guide](SIZE_ANALYSIS_GUIDE.md).

## Troubleshooting

### Flutter Not Found

```
✗ Flutter is not installed or not in PATH
```

**Solution:** Install Flutter or add to PATH:
```bash
export PATH="$PATH:/path/to/flutter/bin"
```

### iOS Build on Non-macOS

```
✗ iOS builds require macOS
```

**Solution:** iOS and macOS builds can only be performed on macOS systems.

### Symbol Upload Failed

```
✗ Failed to upload debug symbols
```

**Solutions:**
1. Check `sentry.properties` configuration
2. Verify auth token has correct scopes
3. Ensure `SENTRY_DSN` is set in `.env`
4. Check network connectivity

### Missing Dependencies

```
Error: Package not found
```

**Solution:**
```bash
flutter pub get
flutter clean
./demo.sh build android
```

## Build Script Features

### ✅ Automatic Features

- Dependency installation
- Environment variable loading
- Platform compatibility checking
- Colored output for easy reading
- Error handling and validation
- Build location reporting

### ✅ Release Build Features

- Code obfuscation
- Debug symbol generation
- Sentry symbol upload
- Source map generation (web)
- Release version tagging

### ✅ Multi-Platform Support

- Cross-platform compatible
- Platform-specific optimizations
- Intelligent fallback handling
- OS detection and validation

## Advanced Usage

### Custom Build Flags

Edit `run.sh` to add custom flags:

```bash
# Example: Add custom build name
flutter build android \
    --$BUILD_TYPE \
    --build-name=2.0.0 \
    --build-number=42 \
    --obfuscate \
    --split-debug-info=$DEBUG_INFO_PATH
```

### Environment Variables

Available environment variables:
- `SENTRY_DSN` - Sentry Data Source Name
- `SENTRY_RELEASE` - Release version
- `SENTRY_ENVIRONMENT` - Environment (production, staging, etc.)

### CI/CD Integration

Use in CI/CD pipelines:

```yaml
# GitHub Actions example
- name: Build Android Release
  run: ./demo.sh build android release
  env:
    SENTRY_DSN: ${{ secrets.SENTRY_DSN }}
    SENTRY_RELEASE: ${{ github.ref_name }}
    SENTRY_ENVIRONMENT: production
```

## Performance Tips

### Build Speed

- Use `debug` builds during development
- Use `profile` builds for performance testing
- Use `release` builds for distribution only

### Build Artifacts

Clean build artifacts periodically:
```bash
flutter clean
rm -rf build/
./demo.sh build android
```

### Parallel Builds

On multi-core systems, Flutter automatically uses parallel builds. For faster builds:
```bash
# Clear cache and rebuild
flutter clean
flutter pub get
./demo.sh build all
```

## Summary

The enhanced `run.sh` script provides a unified, automated build system for Flutter applications with full Sentry integration. It handles all platform-specific configurations, symbol uploads, and build optimizations automatically.

For questions or issues, refer to:
- [Flutter Documentation](https://docs.flutter.dev)
- [Sentry Flutter Documentation](https://docs.sentry.io/platforms/flutter/)
- Project README.md
