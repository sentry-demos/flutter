# Size Analysis Demo - Intentional Bloat

This document describes the intentional bloat added to demonstrate Sentry's Size Analysis insights.

## Build Size Impact

**Before bloat:** 45.8MB (AAB)
**After bloat:** 136.0MB (AAB)
**Total bloat added:** ~90MB

## Intentional Issues Added

### 1. Large Unoptimized Images (45MB)
**Triggers:** Large Images, Image Optimization insights

Files:
- `assets/images/bloat/hero_splash.png` (15MB) - Oversized hero image
- `assets/images/bloat/background_pattern.png` (12MB) - Large background
- `assets/images/bloat/product_showcase.jpg` (10MB) - Unoptimized product image
- `assets/images/bloat/banner_full.png` (8MB) - Banner image

**Expected Insights:**
- ⚠️ Large Images: Flags images > 10MB that could be served remotely
- ⚠️ WebP Optimization: Suggests converting PNG/JPEG to lossless WebP

### 2. Duplicate Files (89MB)
**Triggers:** Duplicate Files insight

Duplicates:
- `hero_splash.png` duplicated 3 times (45MB total)
- `background_pattern.png` duplicated 2 times (24MB total)
- `product_showcase.jpg` duplicated 2 times (20MB total)

**Expected Insight:**
- ⚠️ Duplicate Files: Identifies identical files by hash that can be consolidated

### 3. Large Video Files (27MB)
**Triggers:** Large Videos insight

Files:
- `assets/videos/onboarding_tutorial.mp4` (15MB)
- `assets/videos/product_demo.mp4` (12MB)

**Expected Insight:**
- ⚠️ Large Videos: Suggests streaming videos > 10MB instead of bundling

### 4. Large Audio Files (14MB)
**Triggers:** Large Audio insight

Files:
- `assets/audio/background_music.mp3` (8MB)
- `assets/audio/notification_sound.wav` (6MB)

**Expected Insight:**
- ⚠️ Large Audio: Recommends recompressing or streaming audio > 5MB

### 5. Unnecessary Files
**Triggers:** Unnecessary Files insight (iOS)

Files:
- `assets/docs/ARCHITECTURE.md` - Developer documentation
- `assets/docs/CHANGELOG.md` - Version history
- `assets/docs/CONTRIBUTING.md` - Contribution guidelines
- `assets/docs/build.sh` - Build script
- `assets/docs/build_config.json` - Build configuration

**Expected Insight:**
- ⚠️ Unnecessary Files: Points out docs, scripts, and configs that don't need to be bundled

### 6. Small Files (iOS)
**Triggers:** Small Files insight (iOS only)

Files:
- 30 icon files (512 bytes each) - waste ~3.5KB each due to 4KB block size
- 20 badge files (256 bytes each) - waste ~3.75KB each
- 15 config files (~30 bytes each) - waste ~3.97KB each

**Expected Insight:**
- ⚠️ Small Files: Identifies tiny files wasting space due to 4KB filesystem blocks

## Expected Total Savings

If all insights are addressed:
- **Remove duplicates:** ~89MB
- **Optimize/remove large images:** ~40MB
- **Stream videos instead:** ~27MB
- **Recompress/stream audio:** ~14MB
- **Remove unnecessary files:** ~50KB
- **Consolidate small files:** ~200KB

**Total potential savings:** ~170MB (includes overhead)

## How to Demo

1. View Size Analysis dashboard: https://sentry.io/organizations/prithvi-0c/projects/flutter/size-analysis/

2. Navigate to the latest build to see insights

3. Compare this build (136MB) to the previous clean build (45.8MB)

4. Review each insight category to see specific recommendations

## Cleanup

To remove all bloat:
```bash
git rm -rf assets/audio assets/videos assets/docs assets/config
git rm -rf assets/images/bloat assets/images/duplicates
git rm -rf assets/images/icons assets/images/badges
git checkout pubspec.yaml
flutter build appbundle --release
```
