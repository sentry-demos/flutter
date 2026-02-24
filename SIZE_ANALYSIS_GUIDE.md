# Size Analysis Guide - Flutter App Size Monitoring with Sentry

This guide explains how to set up and use Sentry's Size Analysis feature to monitor your Flutter application's build sizes and prevent size regressions.

## What is Size Analysis?

Size Analysis helps you:
- **Monitor app size trends** across builds
- **Detect size regressions** before they reach users
- **Understand size impact** of code changes
- **Optimize download and installation** rates

Smaller app sizes lead to better installation rates, especially for users with limited storage or slower connections.

## Prerequisites

### 1. Install Sentry CLI

The Sentry CLI (version 2.58.2 or later) is required for size analysis uploads.

**Install on macOS/Linux:**
```bash
curl -sL https://sentry.io/get-cli/ | bash
```

**Or via Homebrew:**
```bash
brew install getsentry/tools/sentry-cli
```

**Or via npm:**
```bash
npm install -g @sentry/cli
```

**Verify installation:**
```bash
sentry-cli --version
```

### 2. Authenticate Sentry CLI

Create an auth token with the required scopes:

1. Visit: https://sentry.io/settings/account/api/auth-tokens/
2. Click "Create New Token"
3. Name: "Size Analysis Upload"
4. Scopes: `project:write`, `org:read`
5. Copy the token

**Set the token in your environment:**
```bash
export SENTRY_AUTH_TOKEN=your-token-here
```

Or add to your `.env` file:
```bash
SENTRY_AUTH_TOKEN=your-token-here
```

## Configuration

### Option 1: Using .env (Recommended)

Add the following to your `.env` file:

```bash
# Sentry Configuration
SENTRY_ORG=your-org-slug
SENTRY_PROJECT=your-project-slug
SENTRY_AUTH_TOKEN=your-auth-token

# Enable Size Analysis
SENTRY_SIZE_ANALYSIS_ENABLED=true

# Optional: Git metadata (usually auto-detected)
# CI_COMMIT_SHA=abc123
# CI_MERGE_REQUEST_DIFF_BASE_SHA=def456
# CI_COMMIT_REF_NAME=feature-branch
# GITHUB_PR_NUMBER=42
```

### Option 2: Using sentry.properties

Add to your `sentry.properties` file:

```properties
# Required
org=your-org-slug
project=your-project-slug
auth_token=your-auth-token

# Size analysis (handled by build script)
# Note: Set SENTRY_SIZE_ANALYSIS_ENABLED=true in environment
```

## Usage

### Building with Size Analysis

The unified `demo.sh` script automatically uploads builds for size analysis when enabled.

#### Android

```bash
# Enable size analysis
export SENTRY_SIZE_ANALYSIS_ENABLED=true

# Build and upload
./demo.sh build android
```

The script will:
1. Build the Android APK with obfuscation
2. Upload debug symbols
3. **Upload APK for size analysis**
4. Display the Sentry URL to view results

**Build output:**
```
✓ Android APK built successfully
ℹ APK location: build/app/outputs/flutter-apk/app-release.apk

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Uploading Android Build for Size Analysis
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ℹ Uploading: build/app/outputs/flutter-apk/app-release.apk
ℹ Organization: your-org
ℹ Project: your-project
✓ Size analysis data uploaded successfully
ℹ View results: https://sentry.io/organizations/your-org/projects/your-project/size-analysis/
```

#### iOS

For iOS, Flutter doesn't directly create IPA files. You need to create an archive first:

**Option 1: Use Xcode**
1. Build with the script:
   ```bash
   export SENTRY_SIZE_ANALYSIS_ENABLED=true
   ./demo.sh build ios
   ```
2. Open the project in Xcode:
   ```bash
   open ios/Runner.xcworkspace
   ```
3. Archive the app: Product → Archive
4. Export the IPA
5. Upload manually:
   ```bash
   sentry-cli build upload YourApp.ipa \
     --org your-org \
     --project your-project \
     --build-configuration Release
   ```

**Option 2: Use flutter build ipa (requires Xcode setup)**
```bash
# Build IPA
flutter build ipa --release --obfuscate --split-debug-info=build/debug-info

# Upload for size analysis
sentry-cli build upload build/ios/ipa/Runner.ipa \
  --org your-org \
  --project your-project \
  --build-configuration Release
```

### Viewing Size Analysis Results

After uploading, view your size analysis dashboard:

```
https://sentry.io/organizations/<your-org>/projects/<your-project>/size-analysis/
```

The dashboard shows:
- **Size trends** over time
- **Size breakdown** by component
- **Size comparisons** between builds
- **Regression detection** alerts

## Build Metadata

The build script automatically detects and includes metadata:

| Field | Source | Description |
|-------|--------|-------------|
| `org` | `SENTRY_ORG` | Organization slug (required) |
| `project` | `SENTRY_PROJECT` | Project slug (required) |
| `build-configuration` | Hardcoded | Always "Release" |
| `head-sha` | Git or `CI_COMMIT_SHA` | Current commit SHA |
| `base-sha` | Git merge-base or `CI_MERGE_REQUEST_DIFF_BASE_SHA` | Base commit for comparison |
| `head-ref` | Git branch or `CI_COMMIT_REF_NAME` | Current branch name |
| `base-ref` | `CI_MERGE_REQUEST_TARGET_BRANCH_NAME` | Base branch (default: main) |
| `pr-number` | `CI_MERGE_REQUEST_IID` or `GITHUB_PR_NUMBER` | Pull request number |

## CI/CD Integration

### GitHub Actions

```yaml
name: Build and Size Analysis

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  build-android:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
        with:
          fetch-depth: 0  # Required for git metadata

      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.22.0'

      - name: Install Sentry CLI
        run: |
          curl -sL https://sentry.io/get-cli/ | bash

      - name: Build and Upload
        env:
          SENTRY_ORG: ${{ secrets.SENTRY_ORG }}
          SENTRY_PROJECT: ${{ secrets.SENTRY_PROJECT }}
          SENTRY_AUTH_TOKEN: ${{ secrets.SENTRY_AUTH_TOKEN }}
          SENTRY_SIZE_ANALYSIS_ENABLED: true
          GITHUB_PR_NUMBER: ${{ github.event.pull_request.number }}
        run: ./demo.sh build android
```

### GitLab CI

```yaml
build-android:
  stage: build
  image: ghcr.io/cirruslabs/flutter:stable
  before_script:
    - curl -sL https://sentry.io/get-cli/ | bash
  script:
    - export SENTRY_SIZE_ANALYSIS_ENABLED=true
    - ./demo.sh build android
  variables:
    SENTRY_ORG: your-org
    SENTRY_PROJECT: your-project
    SENTRY_AUTH_TOKEN: $SENTRY_AUTH_TOKEN
  only:
    - merge_requests
    - main
```

## Manual Upload

If you need to upload builds manually:

### Android APK

```bash
sentry-cli build upload build/app/outputs/flutter-apk/app-release.apk \
  --org your-org \
  --project your-project \
  --build-configuration Release \
  --head-sha $(git rev-parse HEAD) \
  --base-sha $(git merge-base HEAD origin/main) \
  --head-ref $(git branch --show-current) \
  --base-ref main
```

### Android AAB (Preferred)

```bash
# Build AAB
flutter build appbundle --release --obfuscate --split-debug-info=build/debug-info

# Upload
sentry-cli build upload build/app/outputs/bundle/release/app-release.aab \
  --org your-org \
  --project your-project \
  --build-configuration Release
```

### iOS IPA

```bash
sentry-cli build upload YourApp.ipa \
  --org your-org \
  --project your-project \
  --build-configuration Release \
  --head-sha $(git rev-parse HEAD) \
  --base-sha $(git merge-base HEAD origin/main)
```

## Troubleshooting

### Sentry CLI Not Found

```
⚠ sentry-cli not found - size analysis uploads will be skipped
```

**Solution:** Install the Sentry CLI:
```bash
curl -sL https://sentry.io/get-cli/ | bash
```

### Authentication Failed

```
✗ Failed to upload size analysis data
```

**Solutions:**
1. Check that `SENTRY_AUTH_TOKEN` is set correctly
2. Verify the token has `project:write` and `org:read` scopes
3. Test authentication:
   ```bash
   sentry-cli login
   ```

### Missing Organization or Project

```
⚠ SENTRY_ORG and SENTRY_PROJECT must be set for size analysis
```

**Solution:** Add to `.env`:
```bash
SENTRY_ORG=your-org-slug
SENTRY_PROJECT=your-project-slug
```

### Build File Not Found

```
⚠ Build file not found: build/app/outputs/flutter-apk/app-release.apk
```

**Solution:** Ensure the build completed successfully. Check:
```bash
find . -name "*.apk"
```

### Size Analysis Disabled

```
ℹ Size analysis disabled. Set SENTRY_SIZE_ANALYSIS_ENABLED=true to enable
```

**Solution:** Enable in your environment:
```bash
export SENTRY_SIZE_ANALYSIS_ENABLED=true
./demo.sh build android
```

## Best Practices

### 1. Enable in CI/CD Only

Size analysis is most valuable in CI/CD pipelines. Enable it for:
- Pull request builds (to catch regressions before merge)
- Main branch builds (to track trends)

```bash
# In CI environment
if [ -n "$CI" ]; then
  export SENTRY_SIZE_ANALYSIS_ENABLED=true
fi
```

### 2. Use Consistent Build Configurations

Always use the same build configuration for comparisons:
- iOS: Use "Release" configuration
- Android: Use "release" build type

### 3. Include Git Metadata

Accurate comparisons require git metadata:
- Ensure `git` is available in CI
- Use `fetch-depth: 0` in GitHub Actions checkout
- Set base branch correctly for PR builds

### 4. Upload AAB for Android (When Possible)

AAB provides more accurate size estimates:
```bash
flutter build appbundle --release
```

### 5. Monitor Trends Regularly

- Set up alerts for size increases > 5%
- Review size analysis dashboard weekly
- Investigate unexpected size increases promptly

## Advanced Configuration

### Custom Metadata

Override auto-detected metadata:

```bash
sentry-cli build upload app.apk \
  --org your-org \
  --project your-project \
  --build-configuration Release \
  --head-sha custom-sha \
  --base-sha base-sha \
  --head-ref feature-branch \
  --base-ref main \
  --pr-number 123 \
  --head-repo-name org/repo \
  --base-repo-name org/repo \
  --vcs-provider github
```

### Different Build Configurations

Track different build configurations separately:

```bash
# Release build
sentry-cli build upload app-release.apk \
  --build-configuration Release

# Debug build (if needed)
sentry-cli build upload app-debug.apk \
  --build-configuration Debug
```

## Size Optimization Tips

When size analysis detects regressions, consider:

1. **Code Analysis**
   - Remove unused dependencies
   - Use tree shaking
   - Enable code minification

2. **Asset Optimization**
   - Compress images (WebP format)
   - Use vector graphics (SVG)
   - Remove unused assets

3. **Build Optimization**
   - Enable obfuscation: `--obfuscate`
   - Split debug info: `--split-debug-info`
   - Use app bundles (Android)

4. **Dependency Audit**
   ```bash
   flutter pub deps --no-dev
   ```

5. **Size Analysis**
   ```bash
   flutter build apk --analyze-size
   ```

## Summary

Sentry Size Analysis integrated into your Flutter build pipeline provides:
- ✅ Automated size tracking
- ✅ Regression detection
- ✅ Historical trends
- ✅ Comparative analysis
- ✅ CI/CD integration

For more information:
- [Sentry Size Analysis Documentation](https://docs.sentry.io/product/insights/size-analysis/)
- [Sentry CLI Documentation](https://docs.sentry.io/product/cli/)
- [Flutter Build Optimization](https://docs.flutter.dev/perf/app-size)
