# Unified Demo Script

This document describes the new unified `demo.sh` script that consolidates all Sentry demo functionality.

## Overview

The `demo.sh` script replaces three separate scripts:
- ~~run.sh~~ → `demo.sh build` and `demo.sh run`
- ~~upload_size_analysis.sh~~ → `demo.sh upload-size`
- ~~verify_setup.sh~~ → `demo.sh verify`

## Key Features

### 1. Integrated Release Management

The unified script automatically handles Sentry release lifecycle:

```bash
./demo.sh build android  # Creates, builds, and finalizes release
```

**Release Workflow:**
1. **Extract version** from `pubspec.yaml` (e.g., `9.13.0+1`)
2. **Create release**: `com.example.empower_flutter@9.13.0+1`
3. **Set commits**: Associates git commits using `--auto`
4. **Build**: Compiles the application with obfuscation
5. **Upload symbols**: Sends debug symbols and source maps
6. **Finalize release**: Marks release as complete
7. **Create deploy**: Records deployment when app runs

### 2. Subcommand Pattern

Like `git` or `docker`, the script uses subcommands:

```bash
./demo.sh build android      # Build with release
./demo.sh run android         # Run and deploy
./demo.sh upload-size file.aab android  # Size analysis
./demo.sh verify              # Check setup
./demo.sh help                # Show help
```

### 3. Automatic Version Management

Version is automatically read from `pubspec.yaml`:

```yaml
version: 9.13.0+1
```

Becomes release: `com.example.empower_flutter@9.13.0+1`

## Usage Examples

### Build APK with Release Management
```bash
./demo.sh build android
```

This will:
- Create Sentry release `com.example.empower_flutter@9.13.0+1`
- Associate git commits
- Build Android APK with obfuscation
- Upload debug symbols and source maps
- Finalize the release
- Upload size analysis (if enabled)

### Build Android App Bundle (AAB)
```bash
./demo.sh build aab
```

Preferred format for Google Play Store uploads.

### Build Debug Version
```bash
./demo.sh build android debug
```

Skips release management and obfuscation.

### Run App and Create Deploy
```bash
./demo.sh run android
```

This will:
- Create a deploy record in Sentry
- Install APK on connected device
- Launch the application
- Track deployment in Sentry dashboard

### Upload Size Analysis Manually
```bash
./demo.sh upload-size build/app/outputs/bundle/release/app-release.aab android
```

### Verify Setup
```bash
./demo.sh verify
```

Checks:
- Flutter installation
- Environment variables (.env)
- sentry-cli installation
- Project files
- Configuration values

## Command Reference

### build
```bash
./demo.sh build <platform> [build-type]
```

**Platforms:** android, aab, ios, web, macos, linux, windows
**Build Types:** debug, profile, release (default)

**Examples:**
```bash
./demo.sh build android          # APK release build
./demo.sh build aab              # AAB release build
./demo.sh build ios              # iOS release build
./demo.sh build android debug    # APK debug build
```

### run
```bash
./demo.sh run <platform>
```

**Platforms:** android, ios, web, macos, linux, windows

**Examples:**
```bash
./demo.sh run android    # Run on Android device/emulator
./demo.sh run ios        # Run on iOS simulator
./demo.sh run web        # Serve web app on localhost:8080
```

### upload-size
```bash
./demo.sh upload-size <file> <platform>
```

**Examples:**
```bash
./demo.sh upload-size build/app/outputs/flutter-apk/app-release.apk android
./demo.sh upload-size build/app/outputs/bundle/release/app-release.aab android
./demo.sh upload-size YourApp.ipa ios
```

### verify
```bash
./demo.sh verify
```

Validates:
- Flutter SDK installation
- Sentry configuration (.env)
- Required project files
- sentry-cli presence

### help
```bash
./demo.sh help
```

Shows comprehensive help documentation.

## Environment Configuration

Configure in `.env` file:

```bash
# Required
SENTRY_DSN=https://your-dsn@sentry.io/project-id
SENTRY_ORG=your-org-slug
SENTRY_PROJECT=your-project-slug
SENTRY_AUTH_TOKEN=your-auth-token

# Optional
SENTRY_ENVIRONMENT=production
SENTRY_SIZE_ANALYSIS_ENABLED=true
```

## Release Name Format

Releases follow this format:
```
com.example.<package-name>@<version>
```

Example:
- Package: `empower_flutter`
- Version: `9.13.0+1`
- Release: `com.example.empower_flutter@9.13.0+1`

## Comparison with Old Scripts

### Before (3 separate scripts)

```bash
# Build
./run.sh android release

# Upload size analysis
./upload_size_analysis.sh build/app.apk android

# Verify setup
./verify_setup.sh

# Manual release management
sentry-cli releases new com.example.empower_flutter@9.13.0+1
sentry-cli releases set-commits com.example.empower_flutter@9.13.0+1 --auto
sentry-cli releases finalize com.example.empower_flutter@9.13.0+1
```

### After (1 unified script)

```bash
# Build with automatic release management
./demo.sh build android

# Upload size analysis
./demo.sh upload-size build/app.apk android

# Verify setup
./demo.sh verify

# Run with deploy tracking
./demo.sh run android
```

## Requirements

- **Flutter SDK**: For building applications
- **sentry-cli**: For release management and size analysis
  ```bash
  brew install sentry-cli
  ```
- **Git**: For commit association and metadata
- **Android SDK** (for Android builds): adb for running apps
- **Xcode** (for iOS/macOS builds, macOS only)

## Advantages

1. **Simplified Workflow**: One script, clear commands
2. **Automatic Release Management**: No manual sentry-cli commands
3. **Version Consistency**: Single source of truth (pubspec.yaml)
4. **Better Organization**: Subcommands group related functionality
5. **Deploy Tracking**: Automatic deploy records
6. **Error Handling**: Comprehensive validation and error messages
7. **Git Integration**: Automatic commit association
8. **Size Analysis**: Integrated into build workflow

## Migration Guide

If you have existing scripts:

1. **Keep old scripts** (for now) for reference
2. **Use new script** for new workflows:
   ```bash
   ./demo.sh build android
   ```
3. **Test thoroughly** before removing old scripts
4. **Update CI/CD** to use new script if applicable

## Troubleshooting

### "sentry-cli not found"
```bash
brew install sentry-cli
```

### "SENTRY_AUTH_TOKEN not set"
Add to `.env`:
```bash
SENTRY_AUTH_TOKEN=your-token-here
```

Generate token: https://sentry.io/settings/account/api/auth-tokens/

### "Could not associate commits"
Ensure auth token has `org:read` scope:
1. Go to https://sentry.io/settings/account/api/auth-tokens/
2. Create new token with `org:read` and `project:releases` scopes
3. Update `.env` with new token

### "Release already exists"
This is normal - the script will continue with existing release.

## Best Practices

1. **Always use release builds** for Sentry demos:
   ```bash
   ./demo.sh build android release
   ```

2. **Enable size analysis** in `.env`:
   ```bash
   SENTRY_SIZE_ANALYSIS_ENABLED=true
   ```

3. **Verify setup** before building:
   ```bash
   ./demo.sh verify
   ```

4. **Use AAB** for Android (preferred over APK):
   ```bash
   ./demo.sh build aab
   ```

5. **Create deploys** when running:
   ```bash
   ./demo.sh run android
   ```

## Future Enhancements

Potential additions:
- Multiple environment support (staging, production)
- Build number auto-increment
- Changelog generation from git commits
- Multi-platform batch builds
- Integration with CI/CD providers

## Support

For issues or questions:
- Check `./demo.sh help`
- Run `./demo.sh verify` to diagnose issues
- Review `.env` configuration
- Check Sentry dashboard for release status
