# Migration to Unified Script

This guide helps you transition from the old separate scripts to the new unified `demo.sh` script.

## Quick Reference

| Old Command | New Command |
|------------|-------------|
| `./run.sh android` | `./demo.sh build android` |
| `./run.sh android --run` | `./demo.sh build android && ./demo.sh run android` |
| `./upload_size_analysis.sh file.aab android` | `./demo.sh upload-size file.aab android` |
| `./verify_setup.sh` | `./demo.sh verify` |

## What's New?

### ✨ Integrated Release Management

The biggest change is automatic Sentry release management. When you build with `demo.sh`, it automatically:

1. **Creates release** from pubspec.yaml version
2. **Associates commits** using git metadata
3. **Builds** the application
4. **Uploads symbols** and source maps
5. **Finalizes release** after successful build
6. **Creates deploy** when you run the app

**Before (manual):**
```bash
# Had to manually manage releases
./run.sh android release
sentry-cli releases new com.example.empower_flutter@1.0.0+2
sentry-cli releases set-commits com.example.empower_flutter@1.0.0+2 --auto
sentry-cli releases finalize com.example.empower_flutter@1.0.0+2
```

**After (automatic):**
```bash
# Everything is handled automatically
./demo.sh build android
```

### 🎯 Subcommand Pattern

The new script uses a modern CLI pattern similar to `git` or `docker`:

```bash
./demo.sh <command> [arguments]
```

Commands:
- `build` - Build with release management
- `run` - Run app with deploy tracking
- `upload-size` - Upload size analysis
- `verify` - Verify setup
- `help` - Show help

### 🔢 Version Management

Version is now automatically extracted from `pubspec.yaml`:

```yaml
version: 1.0.0+2
```

No need to manually specify release names - the script creates:
```
com.example.empower_flutter@1.0.0+2
```

## Common Workflows

### 1. Building for Android

**Old way:**
```bash
./run.sh android release
```

**New way:**
```bash
./demo.sh build android
```

**What changed:**
- Release management is automatic
- Version is read from pubspec.yaml
- Commits are automatically associated
- Release is finalized after build

### 2. Building AAB for Play Store

**Old way:**
```bash
./run.sh android release
# Then manually build AAB or modify script
```

**New way:**
```bash
./demo.sh build aab
```

**What changed:**
- Dedicated `aab` platform for App Bundles
- Same release management as APK
- Clearer intent in command

### 3. Running the App

**Old way:**
```bash
./run.sh android release --run
```

**New way:**
```bash
./demo.sh build android    # Build first
./demo.sh run android      # Then run with deploy tracking
```

**What changed:**
- Separate build and run commands
- Deploy record created automatically
- Tracks when app launches in production

### 4. Size Analysis

**Old way:**
```bash
./upload_size_analysis.sh build/app/outputs/bundle/release/app-release.aab android
```

**New way:**
```bash
./demo.sh upload-size build/app/outputs/bundle/release/app-release.aab android
```

**What changed:**
- Integrated into main script
- Consistent command structure
- Same functionality

### 5. Verifying Setup

**Old way:**
```bash
./verify_setup.sh
```

**New way:**
```bash
./demo.sh verify
```

**What changed:**
- Integrated into main script
- Checks release management setup
- Validates sentry-cli installation

## Complete Demo Flow

### Old Flow (Manual)
```bash
# 1. Verify setup
./verify_setup.sh

# 2. Build
./run.sh android release

# 3. Manually create release
sentry-cli releases new com.example.empower_flutter@1.0.0+2
sentry-cli releases set-commits com.example.empower_flutter@1.0.0+2 --auto

# 4. Upload size analysis
./upload_size_analysis.sh build/app/outputs/flutter-apk/app-release.apk android

# 5. Finalize release
sentry-cli releases finalize com.example.empower_flutter@1.0.0+2

# 6. Run app
./run.sh android --run

# 7. Create deploy
sentry-cli releases deploys com.example.empower_flutter@1.0.0+2 new -e production
```

### New Flow (Automatic)
```bash
# 1. Verify setup
./demo.sh verify

# 2. Build (with automatic release management)
./demo.sh build android

# 3. Run (with automatic deploy tracking)
./demo.sh run android
```

**Result:** 7 manual steps → 3 automatic steps

## Feature Comparison

| Feature | Old Scripts | New Script |
|---------|-------------|------------|
| Build apps | ✅ run.sh | ✅ demo.sh build |
| Run apps | ✅ run.sh --run | ✅ demo.sh run |
| Size analysis | ✅ upload_size_analysis.sh | ✅ demo.sh upload-size |
| Verify setup | ✅ verify_setup.sh | ✅ demo.sh verify |
| Create releases | ❌ Manual | ✅ Automatic |
| Set commits | ❌ Manual | ✅ Automatic |
| Finalize releases | ❌ Manual | ✅ Automatic |
| Deploy tracking | ❌ Manual | ✅ Automatic |
| Version management | ❌ Manual | ✅ Automatic |
| Help documentation | ❌ Limited | ✅ Comprehensive |

## Breaking Changes

### 1. Build Type Position

**Old:**
```bash
./run.sh android debug --run
```

**New:**
```bash
./demo.sh build android debug
```

Build type moved to third position (after platform).

### 2. Run Requires Pre-built App

**Old:**
```bash
./run.sh android --run  # Builds and runs
```

**New:**
```bash
./demo.sh build android  # Build first
./demo.sh run android    # Then run
```

Run command no longer builds - you must build first.

### 3. Script Name Change

**Old:**
```bash
./run.sh
./upload_size_analysis.sh
./verify_setup.sh
```

**New:**
```bash
./demo.sh
```

Single script replaces three separate scripts.

## Environment Variables

No changes to environment variables. Continue using `.env`:

```bash
SENTRY_DSN=https://your-dsn@sentry.io/project-id
SENTRY_ORG=your-org-slug
SENTRY_PROJECT=your-project-slug
SENTRY_AUTH_TOKEN=your-auth-token
SENTRY_ENVIRONMENT=production
SENTRY_SIZE_ANALYSIS_ENABLED=true
```

## Transition Plan

### Phase 1: Test New Script (Week 1)
```bash
# Keep old scripts, test new script
./demo.sh verify
./demo.sh build android debug
./demo.sh run android
```

### Phase 2: Use New Script (Week 2-3)
```bash
# Use new script for all workflows
./demo.sh build android
./demo.sh build aab
./demo.sh run android
```

### Phase 3: Archive Old Scripts (Week 4)
```bash
# Move old scripts to archive
mkdir scripts_archive
mv run.sh scripts_archive/
mv upload_size_analysis.sh scripts_archive/
mv verify_setup.sh scripts_archive/
```

## Troubleshooting

### "Release already exists"

This is normal! The script continues with the existing release. To create a new release:

1. Update version in `pubspec.yaml`:
   ```yaml
   version: 1.0.0+3  # Increment build number
   ```

2. Rebuild:
   ```bash
   ./demo.sh build android
   ```

### "Could not associate commits"

Your auth token needs `org:read` scope:

1. Generate new token: https://sentry.io/settings/account/api/auth-tokens/
2. Select scopes: `project:releases`, `project:write`, `org:read`
3. Update `.env`:
   ```bash
   SENTRY_AUTH_TOKEN=new-token-here
   ```

### "sentry-cli not found"

Install sentry-cli:
```bash
brew install sentry-cli
```

## Rollback Plan

If you need to rollback to old scripts:

```bash
# Restore from archive
cp scripts_archive/run.sh ./
cp scripts_archive/upload_size_analysis.sh ./
cp scripts_archive/verify_setup.sh ./

# Make executable
chmod +x run.sh upload_size_analysis.sh verify_setup.sh

# Use old workflow
./run.sh android release
```

## Questions?

Run `./demo.sh help` for comprehensive documentation.

## Benefits Summary

✅ **Simpler** - One script instead of three
✅ **Automatic** - Release management handled for you
✅ **Consistent** - Single version source (pubspec.yaml)
✅ **Modern** - Subcommand pattern like git/docker
✅ **Complete** - Handles entire release lifecycle
✅ **Tracked** - Deploys recorded automatically
✅ **Validated** - Built-in verification
✅ **Documented** - Comprehensive help

## Next Steps

1. ✅ Test the new script: `./demo.sh verify`
2. ✅ Build an app: `./demo.sh build android`
3. ✅ Run the app: `./demo.sh run android`
4. ✅ Check Sentry dashboard for release data
5. ✅ Review `UNIFIED_SCRIPT.md` for details
6. ✅ Archive old scripts when comfortable
