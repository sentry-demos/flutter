#!/bin/bash
# Unified Sentry Demo Script for Flutter
# Consolidates build, run, size analysis, and release management
#
# Usage:
#   ./demo.sh build [platform] [build-type]  - Build with release management
#   ./demo.sh run [platform]                  - Run app and create deploy
#   ./demo.sh upload-size [file] [platform]   - Upload size analysis
#   ./demo.sh verify                          - Verify setup
#   ./demo.sh help                            - Show help
#
# Examples:
#   ./demo.sh build android                   # Build Android APK with release
#   ./demo.sh build aab                       # Build Android AAB with release
#   ./demo.sh run android                     # Run Android app and create deploy
#   ./demo.sh upload-size build/app.apk android
#   ./demo.sh verify

set -e

# ============================================================================
# CONFIGURATION & COLORS
# ============================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
NC='\033[0m'

DEBUG_INFO_PATH="build/debug-info"

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================

print_info() { echo -e "${BLUE}ℹ ${NC}$1"; }
print_success() { echo -e "${GREEN}✓${NC} $1"; }
print_warning() { echo -e "${YELLOW}⚠${NC} $1"; }
print_error() { echo -e "${RED}✗${NC} $1"; }
print_header() {
    echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
}

# Load environment variables from .env
load_env() {
    if [ -f .env ]; then
        print_info "Loading environment variables from .env"
        export $(grep -v '^#' .env | xargs)
        print_success "Environment variables loaded"
    else
        print_warning ".env file not found, using system environment variables"
    fi
}

# Check if Flutter is installed
check_flutter() {
    if command -v flutter &> /dev/null; then
        FLUTTER_CMD="flutter"
        print_success "Flutter found: $(flutter --version | head -n 1)"
    else
        HOMEBREW_FLUTTER="/opt/homebrew/Caskroom/flutter/3.38.7/flutter/bin/flutter"
        if [ -f "$HOMEBREW_FLUTTER" ]; then
            FLUTTER_CMD="$HOMEBREW_FLUTTER"
            print_success "Flutter found (Homebrew): $($FLUTTER_CMD --version | head -n 1)"
        else
            print_error "Flutter is not installed or not in PATH"
            print_info "Install: https://flutter.dev/docs/get-started/install"
            exit 1
        fi
    fi
}

# Check if Sentry CLI is installed
check_sentry_cli() {
    if ! command -v sentry-cli &> /dev/null; then
        print_warning "sentry-cli not found"
        print_info "Install: brew install sentry-cli"
        return 1
    fi
    return 0
}

# Extract version from pubspec.yaml
get_version() {
    if [ ! -f pubspec.yaml ]; then
        print_error "pubspec.yaml not found"
        exit 1
    fi

    VERSION=$(grep '^version:' pubspec.yaml | sed 's/version: *//' | tr -d '\r\n ')

    if [ -z "$VERSION" ]; then
        print_error "Could not extract version from pubspec.yaml"
        exit 1
    fi

    echo "$VERSION"
}

# Get package name from pubspec.yaml
get_package_name() {
    if [ ! -f pubspec.yaml ]; then
        print_error "pubspec.yaml not found"
        exit 1
    fi

    PACKAGE_NAME=$(grep '^name:' pubspec.yaml | sed 's/name: *//' | tr -d '\r\n ')

    if [ -z "$PACKAGE_NAME" ]; then
        print_error "Could not extract package name from pubspec.yaml"
        exit 1
    fi

    echo "$PACKAGE_NAME"
}

# Get full release name for Sentry
get_release_name() {
    local package_name=$(get_package_name)
    local version=$(get_version)
    echo "com.example.${package_name}@${version}"
}

# Get dependencies
get_dependencies() {
    print_info "Getting Flutter dependencies..."
    $FLUTTER_CMD pub get
    print_success "Dependencies installed"
}

# ============================================================================
# RELEASE MANAGEMENT FUNCTIONS
# ============================================================================

create_release() {
    if ! check_sentry_cli; then
        print_warning "Skipping release creation (sentry-cli not found)"
        return 1
    fi

    local release_name=$(get_release_name)

    print_header "Creating Sentry Release"
    print_info "Release: $release_name"
    print_info "Organization: ${SENTRY_ORG}"
    print_info "Project: ${SENTRY_PROJECT}"

    # Create release
    if sentry-cli releases new "$release_name" \
        --org "${SENTRY_ORG}" \
        --project "${SENTRY_PROJECT}"; then
        print_success "Release created: $release_name"
    else
        # Release might already exist
        print_warning "Release may already exist (continuing)"
    fi

    # Set commits
    print_info "Associating commits with release..."
    if sentry-cli releases set-commits "$release_name" --auto \
        --org "${SENTRY_ORG}"; then
        print_success "Commits associated with release"
    else
        print_warning "Could not associate commits (continuing)"
        print_info "Ensure your auth token has 'org:read' scope"
    fi

    return 0
}

finalize_release() {
    if ! check_sentry_cli; then
        return 1
    fi

    local release_name=$(get_release_name)

    print_header "Finalizing Sentry Release"
    print_info "Release: $release_name"

    if sentry-cli releases finalize "$release_name" \
        --org "${SENTRY_ORG}" \
        --project "${SENTRY_PROJECT}"; then
        print_success "Release finalized: $release_name"
    else
        print_warning "Could not finalize release"
        return 1
    fi

    return 0
}

create_deploy() {
    if ! check_sentry_cli; then
        return 1
    fi

    local release_name=$(get_release_name)
    local environment="${SENTRY_ENVIRONMENT:-production}"

    print_header "Creating Deploy Record"
    print_info "Release: $release_name"
    print_info "Environment: $environment"

    if sentry-cli releases deploys "$release_name" new \
        -e "$environment" \
        --org "${SENTRY_ORG}" \
        --project "${SENTRY_PROJECT}"; then
        print_success "Deploy created for $environment"
    else
        print_warning "Could not create deploy"
        return 1
    fi

    return 0
}

# ============================================================================
# BUILD FUNCTIONS
# ============================================================================

build_with_release() {
    local platform="$1"
    local build_type="${2:-release}"

    print_header "Building $platform ($build_type)"
    print_info "Version: $(get_version)"

    # Load environment
    load_env

    # Check Flutter
    check_flutter

    # Get dependencies
    get_dependencies

    # Create release (for release builds only)
    if [ "$build_type" = "release" ]; then
        create_release
    fi

    # Build based on platform
    case "$platform" in
        android)
            build_android "$build_type"
            ;;
        aab)
            build_aab "$build_type"
            ;;
        ios)
            build_ios "$build_type"
            ;;
        web)
            build_web "$build_type"
            ;;
        macos)
            build_macos "$build_type"
            ;;
        linux)
            build_linux "$build_type"
            ;;
        windows)
            build_windows "$build_type"
            ;;
        *)
            print_error "Unknown platform: $platform"
            exit 1
            ;;
    esac

    # Upload debug symbols (for release builds)
    if [ "$build_type" = "release" ]; then
        upload_symbols
        finalize_release
    fi

    print_header "Build Complete!"
    print_success "All tasks completed successfully"
}

build_android() {
    local build_type="${1:-release}"

    print_info "Building Android APK..."

    if [ "$build_type" = "release" ]; then
        $FLUTTER_CMD build apk \
            --$build_type \
            --obfuscate \
            --split-debug-info=$DEBUG_INFO_PATH \
            --extra-gen-snapshot-options=--save-obfuscation-map=build/app/obfuscation.map.json \
            --dart-define=SENTRY_DSN="$SENTRY_DSN" \
            --dart-define=SENTRY_RELEASE="$(get_release_name)" \
            --dart-define=SENTRY_ENVIRONMENT="$SENTRY_ENVIRONMENT"
    else
        $FLUTTER_CMD build apk --$build_type
    fi

    local apk_path="build/app/outputs/flutter-apk/app-$build_type.apk"
    print_success "Android APK built: $apk_path"

    # Show file size
    if [ -f "$apk_path" ]; then
        local size=$(du -h "$apk_path" | cut -f1)
        print_info "APK size: $size"
    fi

    # Upload size analysis for release builds
    if [ "$build_type" = "release" ] && [ "${SENTRY_SIZE_ANALYSIS_ENABLED}" = "true" ]; then
        upload_size_analysis "$apk_path" "Android"
    fi
}

build_aab() {
    local build_type="${1:-release}"

    print_info "Building Android AAB (App Bundle)..."

    if [ "$build_type" = "release" ]; then
        $FLUTTER_CMD build appbundle \
            --$build_type \
            --obfuscate \
            --split-debug-info=$DEBUG_INFO_PATH \
            --extra-gen-snapshot-options=--save-obfuscation-map=build/app/obfuscation.map.json \
            --dart-define=SENTRY_DSN="$SENTRY_DSN" \
            --dart-define=SENTRY_RELEASE="$(get_release_name)" \
            --dart-define=SENTRY_ENVIRONMENT="$SENTRY_ENVIRONMENT"
    else
        $FLUTTER_CMD build appbundle --$build_type
    fi

    local aab_path="build/app/outputs/bundle/${build_type}/app-${build_type}.aab"
    print_success "Android AAB built: $aab_path"

    # Show file size
    if [ -f "$aab_path" ]; then
        local size=$(du -h "$aab_path" | cut -f1)
        print_info "AAB size: $size"
    fi

    # Upload size analysis for release builds
    if [ "$build_type" = "release" ] && [ "${SENTRY_SIZE_ANALYSIS_ENABLED}" = "true" ]; then
        upload_size_analysis "$aab_path" "Android"
    fi
}

build_ios() {
    local build_type="${1:-release}"

    if [ "$(uname)" != "Darwin" ]; then
        print_error "iOS builds require macOS"
        exit 1
    fi

    print_info "Building iOS app..."

    if [ "$build_type" = "release" ]; then
        $FLUTTER_CMD build ios \
            --$build_type \
            --obfuscate \
            --split-debug-info=$DEBUG_INFO_PATH \
            --extra-gen-snapshot-options=--save-obfuscation-map=build/app/obfuscation.map.json \
            --dart-define=SENTRY_DSN="$SENTRY_DSN" \
            --dart-define=SENTRY_RELEASE="$(get_release_name)" \
            --dart-define=SENTRY_ENVIRONMENT="$SENTRY_ENVIRONMENT"
    else
        $FLUTTER_CMD build ios --$build_type
    fi

    print_success "iOS app built: build/ios/iphoneos/Runner.app"

    if [ "$build_type" = "release" ]; then
        print_info "For size analysis, create IPA via Xcode and upload with:"
        print_info "  ./demo.sh upload-size YourApp.ipa ios"
    fi
}

build_web() {
    local build_type="${1:-release}"

    print_info "Building web app..."

    if [ "$build_type" = "release" ]; then
        $FLUTTER_CMD build web \
            --$build_type \
            --source-maps \
            --dart-define=SENTRY_DSN="$SENTRY_DSN" \
            --dart-define=SENTRY_RELEASE="$(get_release_name)" \
            --dart-define=SENTRY_ENVIRONMENT="$SENTRY_ENVIRONMENT"
    else
        $FLUTTER_CMD build web --$build_type
    fi

    print_success "Web app built: build/web/"
}

build_macos() {
    local build_type="${1:-release}"

    if [ "$(uname)" != "Darwin" ]; then
        print_error "macOS builds require macOS"
        exit 1
    fi

    print_info "Building macOS app..."

    if [ "$build_type" = "release" ]; then
        $FLUTTER_CMD build macos \
            --$build_type \
            --obfuscate \
            --split-debug-info=$DEBUG_INFO_PATH \
            --extra-gen-snapshot-options=--save-obfuscation-map=build/app/obfuscation.map.json \
            --dart-define=SENTRY_DSN="$SENTRY_DSN" \
            --dart-define=SENTRY_RELEASE="$(get_release_name)" \
            --dart-define=SENTRY_ENVIRONMENT="$SENTRY_ENVIRONMENT"
    else
        $FLUTTER_CMD build macos --$build_type
    fi

    print_success "macOS app built: build/macos/Build/Products/Release/empower_flutter.app"
}

build_linux() {
    local build_type="${1:-release}"

    print_info "Building Linux app..."

    if [ "$build_type" = "release" ]; then
        $FLUTTER_CMD build linux \
            --$build_type \
            --obfuscate \
            --split-debug-info=$DEBUG_INFO_PATH \
            --extra-gen-snapshot-options=--save-obfuscation-map=build/app/obfuscation.map.json \
            --dart-define=SENTRY_DSN="$SENTRY_DSN" \
            --dart-define=SENTRY_RELEASE="$(get_release_name)" \
            --dart-define=SENTRY_ENVIRONMENT="$SENTRY_ENVIRONMENT"
    else
        $FLUTTER_CMD build linux --$build_type
    fi

    print_success "Linux app built: build/linux/x64/release/bundle/"
}

build_windows() {
    local build_type="${1:-release}"

    if [ "$(uname)" = "Darwin" ]; then
        print_error "Windows builds cannot be performed on macOS"
        exit 1
    fi

    print_info "Building Windows app..."

    if [ "$build_type" = "release" ]; then
        $FLUTTER_CMD build windows \
            --$build_type \
            --obfuscate \
            --split-debug-info=$DEBUG_INFO_PATH \
            --extra-gen-snapshot-options=--save-obfuscation-map=build/app/obfuscation.map.json \
            --dart-define=SENTRY_DSN="$SENTRY_DSN" \
            --dart-define=SENTRY_RELEASE="$(get_release_name)" \
            --dart-define=SENTRY_ENVIRONMENT="$SENTRY_ENVIRONMENT"
    else
        $FLUTTER_CMD build windows --$build_type
    fi

    print_success "Windows app built: build/windows/x64/runner/Release/"
}

# Upload debug symbols to Sentry
upload_symbols() {
    print_header "Uploading Debug Symbols"

    if [ -z "$SENTRY_DSN" ] && [ ! -f "sentry.properties" ]; then
        print_warning "Sentry not configured. Skipping symbol upload."
        return
    fi

    print_info "Running sentry_dart_plugin..."

    set +e
    $FLUTTER_CMD pub run sentry_dart_plugin --include-sources > /tmp/sentry_upload.log 2>&1
    local exit_code=$?
    set -e

    cat /tmp/sentry_upload.log

    if [ $exit_code -eq 0 ]; then
        print_success "Debug symbols uploaded to Sentry"
    elif grep -q "succeeded=" /tmp/sentry_upload.log || grep -q "Nothing to upload" /tmp/sentry_upload.log; then
        print_success "Debug symbols uploaded to Sentry"
        if grep -q "Unknown repo\|403" /tmp/sentry_upload.log; then
            print_warning "Repository integration requires 'org:read' scope"
        fi
    else
        print_warning "Symbol upload completed with warnings (exit code: $exit_code)"
    fi
}

# ============================================================================
# RUN FUNCTIONS
# ============================================================================

run_app() {
    local platform="${1:-android}"

    print_header "Running $platform App"

    # Load environment
    load_env

    # Check Flutter
    check_flutter

    # Create deploy record
    create_deploy

    case "$platform" in
        android)
            run_android
            ;;
        ios)
            run_ios
            ;;
        web)
            run_web
            ;;
        macos)
            run_macos
            ;;
        linux)
            run_linux
            ;;
        windows)
            run_windows
            ;;
        *)
            print_error "Unknown platform: $platform"
            exit 1
            ;;
    esac
}

run_android() {
    local ADB_CMD="adb"

    if ! command -v adb &> /dev/null; then
        if [ -f "$HOME/Library/Android/sdk/platform-tools/adb" ]; then
            ADB_CMD="$HOME/Library/Android/sdk/platform-tools/adb"
        elif [ -f "$HOME/Android/Sdk/platform-tools/adb" ]; then
            ADB_CMD="$HOME/Android/Sdk/platform-tools/adb"
        else
            print_error "adb not found"
            exit 1
        fi
    fi

    local device_count=$($ADB_CMD devices | grep -w "device" | wc -l)
    if [ "$device_count" -eq 0 ]; then
        print_error "No Android device/emulator connected"
        exit 1
    fi

    local apk_path="build/app/outputs/flutter-apk/app-release.apk"

    if [ ! -f "$apk_path" ]; then
        print_error "APK not found: $apk_path"
        print_info "Build first with: ./demo.sh build android"
        exit 1
    fi

    print_info "Installing APK..."
    $ADB_CMD install -r "$apk_path"

    print_info "Launching app..."
    $ADB_CMD shell am start -n com.example.empower_flutter/.MainActivity

    print_success "Android app launched"
}

run_ios() {
    if [ "$(uname)" != "Darwin" ]; then
        print_error "iOS apps can only be run on macOS"
        exit 1
    fi

    print_info "Launching iOS simulator..."
    $FLUTTER_CMD run -d ios --release

    print_success "iOS app launched"
}

run_web() {
    print_info "Starting web server on port 8080..."

    if [ ! -d "build/web" ]; then
        print_error "Web build not found"
        print_info "Build first with: ./demo.sh build web"
        exit 1
    fi

    cd build/web

    if command -v python3 &> /dev/null; then
        python3 -m http.server 8080
    elif command -v python &> /dev/null; then
        python -m SimpleHTTPServer 8080
    else
        print_error "Python not found"
        exit 1
    fi
}

run_macos() {
    if [ "$(uname)" != "Darwin" ]; then
        print_error "macOS apps can only be run on macOS"
        exit 1
    fi

    local app_path="build/macos/Build/Products/Release/empower_flutter.app"

    if [ ! -d "$app_path" ]; then
        print_error "App not found: $app_path"
        print_info "Build first with: ./demo.sh build macos"
        exit 1
    fi

    print_info "Launching macOS app..."
    open "$app_path"

    print_success "macOS app launched"
}

run_linux() {
    local exe_path="build/linux/x64/release/bundle/empower_flutter"

    if [ ! -f "$exe_path" ]; then
        print_error "Executable not found: $exe_path"
        print_info "Build first with: ./demo.sh build linux"
        exit 1
    fi

    print_info "Launching Linux app..."
    "$exe_path" &

    print_success "Linux app launched"
}

run_windows() {
    local exe_path="build/windows/x64/runner/Release/empower_flutter.exe"

    if [ ! -f "$exe_path" ]; then
        print_error "Executable not found: $exe_path"
        print_info "Build first with: ./demo.sh build windows"
        exit 1
    fi

    print_info "Launching Windows app..."
    start "$exe_path"

    print_success "Windows app launched"
}

# ============================================================================
# SIZE ANALYSIS FUNCTIONS
# ============================================================================

upload_size_analysis() {
    local build_file="$1"
    local platform="$2"

    if ! check_sentry_cli; then
        print_warning "Cannot upload size analysis (sentry-cli not found)"
        return 1
    fi

    if [ ! -f "$build_file" ]; then
        print_error "Build file not found: $build_file"
        exit 1
    fi

    print_header "Uploading Size Analysis"

    # Detect build format
    local build_format=""
    if [[ "$build_file" == *.aab ]]; then
        build_format="AAB"
    elif [[ "$build_file" == *.apk ]]; then
        build_format="APK"
    elif [[ "$build_file" == *.xcarchive ]]; then
        build_format="XCArchive"
    elif [[ "$build_file" == *.ipa ]]; then
        build_format="IPA"
    fi

    print_info "File: $build_file"
    print_info "Format: $build_format"
    print_info "Platform: $platform"
    print_info "Organization: ${SENTRY_ORG}"
    print_info "Project: ${SENTRY_PROJECT}"

    # Get git metadata
    local head_sha=$(git rev-parse HEAD 2>/dev/null || echo "")
    local base_sha=$(git merge-base HEAD origin/main 2>/dev/null || echo "")
    local head_ref=$(git branch --show-current 2>/dev/null || echo "")
    local base_ref="main"

    # Auto-detect VCS info
    local git_remote=$(git config --get remote.origin.url 2>/dev/null || echo "")
    local head_repo_name=""
    local vcs_provider=""

    if [[ "$git_remote" =~ github\.com[:/](.+)(\.git)?$ ]]; then
        head_repo_name="${BASH_REMATCH[1]}"
        head_repo_name="${head_repo_name%.git}"
        vcs_provider="github"
    fi

    # Build command
    local cmd="sentry-cli build upload \"$build_file\" --org \"$SENTRY_ORG\" --project \"$SENTRY_PROJECT\" --build-configuration Release"

    # Add metadata
    [ -n "$head_sha" ] && cmd="$cmd --head-sha \"$head_sha\""
    [ -n "$base_sha" ] && cmd="$cmd --base-sha \"$base_sha\""
    [ -n "$head_ref" ] && cmd="$cmd --head-ref \"$head_ref\""
    [ -n "$base_ref" ] && cmd="$cmd --base-ref \"$base_ref\""
    [ -n "$vcs_provider" ] && cmd="$cmd --vcs-provider \"$vcs_provider\""
    [ -n "$head_repo_name" ] && cmd="$cmd --head-repo-name \"$head_repo_name\""

    # Execute
    if eval "$cmd"; then
        print_success "Size analysis uploaded"
        print_info "View: https://sentry.io/organizations/$SENTRY_ORG/projects/$SENTRY_PROJECT/size-analysis/"
    else
        print_error "Upload failed"
        exit 1
    fi
}

# ============================================================================
# VERIFY FUNCTION
# ============================================================================

verify_setup() {
    local issues=0

    print_header "Verifying Setup"

    # Check Flutter
    print_info "Checking Flutter..."
    if command -v flutter &> /dev/null; then
        print_success "Flutter: $(flutter --version | head -n 1)"
    else
        print_error "Flutter not found"
        issues=$((issues + 1))
    fi

    # Check .env
    print_info "Checking .env..."
    if [ -f .env ]; then
        print_success ".env file exists"

        if grep -q "SENTRY_DSN=" .env && [ -n "$(grep SENTRY_DSN= .env | cut -d= -f2)" ]; then
            print_success "SENTRY_DSN is set"
        else
            print_warning "SENTRY_DSN not set"
            issues=$((issues + 1))
        fi

        if grep -q "SENTRY_ORG=" .env && [ -n "$(grep SENTRY_ORG= .env | cut -d= -f2)" ]; then
            print_success "SENTRY_ORG is set"
        else
            print_warning "SENTRY_ORG not set"
            issues=$((issues + 1))
        fi

        if grep -q "SENTRY_PROJECT=" .env && [ -n "$(grep SENTRY_PROJECT= .env | cut -d= -f2)" ]; then
            print_success "SENTRY_PROJECT is set"
        else
            print_warning "SENTRY_PROJECT not set"
            issues=$((issues + 1))
        fi
    else
        print_error ".env file not found"
        issues=$((issues + 1))
    fi

    # Check sentry-cli
    print_info "Checking sentry-cli..."
    if command -v sentry-cli &> /dev/null; then
        print_success "sentry-cli: $(sentry-cli --version | head -n 1)"
    else
        print_warning "sentry-cli not found (optional for size analysis)"
        print_info "Install: brew install sentry-cli"
    fi

    # Check pubspec.yaml
    print_info "Checking pubspec.yaml..."
    if [ -f pubspec.yaml ]; then
        local version=$(get_version)
        print_success "Version: $version"

        if grep -q "sentry_flutter:" pubspec.yaml; then
            local sdk_version=$(grep "sentry_flutter:" pubspec.yaml | awk '{print $2}')
            print_success "Sentry SDK: $sdk_version"
        fi
    else
        print_error "pubspec.yaml not found"
        issues=$((issues + 1))
    fi

    # Check key files
    print_info "Checking project files..."
    local required_files=("lib/main.dart" "lib/sentry_setup.dart" "lib/checkout.dart")

    for file in "${required_files[@]}"; do
        if [ -f "$file" ]; then
            print_success "$file"
        else
            print_error "$file not found"
            issues=$((issues + 1))
        fi
    done

    # Summary
    print_header "Verification Summary"

    if [ $issues -eq 0 ]; then
        print_success "All checks passed! ✨"
        echo ""
        print_info "Next steps:"
        echo "  1. ./demo.sh build android    # Build with release management"
        echo "  2. ./demo.sh run android       # Run and create deploy"
        echo ""
    else
        print_warning "Found $issues issue(s)"
        print_info "Please fix the issues above"
    fi

    exit 0
}

# ============================================================================
# HELP FUNCTION
# ============================================================================

show_help() {
    cat << 'EOF'
Unified Sentry Demo Script for Flutter
=====================================

Consolidates build, run, size analysis, and release management.

USAGE:
  ./demo.sh <command> [options]

COMMANDS:
  build <platform> [build-type]    Build app with release management
  run <platform>                   Run app and create deploy
  upload-size <file> <platform>    Upload size analysis to Sentry
  verify                           Verify setup configuration
  help                             Show this help message

PLATFORMS:
  android    - Build Android APK
  aab        - Build Android App Bundle (preferred)
  ios        - Build iOS app (macOS only)
  web        - Build web app
  macos      - Build macOS app (macOS only)
  linux      - Build Linux app
  windows    - Build Windows app

BUILD TYPES:
  debug      - Debug build (no obfuscation)
  profile    - Profile build
  release    - Release build with obfuscation (default)

EXAMPLES:
  # Build Android APK with release management
  ./demo.sh build android

  # Build Android AAB (preferred for Play Store)
  ./demo.sh build aab

  # Build iOS release
  ./demo.sh build ios

  # Build debug version
  ./demo.sh build android debug

  # Run Android app and create deploy
  ./demo.sh run android

  # Upload size analysis manually
  ./demo.sh upload-size build/app/outputs/bundle/release/app-release.aab android

  # Verify setup
  ./demo.sh verify

RELEASE MANAGEMENT:
  This script automatically manages Sentry releases:
  1. Extracts version from pubspec.yaml (e.g., 1.0.0+2)
  2. Creates release: com.example.empower_flutter@1.0.0+2
  3. Associates commits with release (--auto)
  4. Builds the application
  5. Uploads debug symbols
  6. Finalizes the release
  7. Creates deploy record when app runs

ENVIRONMENT:
  Configure in .env file:
  - SENTRY_DSN
  - SENTRY_ORG
  - SENTRY_PROJECT
  - SENTRY_AUTH_TOKEN
  - SENTRY_ENVIRONMENT
  - SENTRY_SIZE_ANALYSIS_ENABLED

REQUIREMENTS:
  - Flutter SDK
  - sentry-cli (brew install sentry-cli)
  - Git (for release metadata)

EOF
}

# ============================================================================
# MAIN ENTRY POINT
# ============================================================================

main() {
    local command="${1:-help}"

    case "$command" in
        build)
            if [ -z "$2" ]; then
                print_error "Platform required"
                echo "Usage: ./demo.sh build <platform> [build-type]"
                echo "Run './demo.sh help' for more information"
                exit 1
            fi
            build_with_release "$2" "${3:-release}"
            ;;

        run)
            if [ -z "$2" ]; then
                print_error "Platform required"
                echo "Usage: ./demo.sh run <platform>"
                echo "Run './demo.sh help' for more information"
                exit 1
            fi
            run_app "$2"
            ;;

        upload-size)
            if [ -z "$2" ] || [ -z "$3" ]; then
                print_error "Build file and platform required"
                echo "Usage: ./demo.sh upload-size <file> <platform>"
                echo "Example: ./demo.sh upload-size build/app.aab android"
                exit 1
            fi
            load_env
            upload_size_analysis "$2" "$3"
            ;;

        verify)
            verify_setup
            ;;

        help|--help|-h)
            show_help
            ;;

        *)
            print_error "Unknown command: $command"
            echo ""
            echo "Usage: ./demo.sh <command> [options]"
            echo ""
            echo "Commands:"
            echo "  build        - Build app with release management"
            echo "  run          - Run app and create deploy"
            echo "  upload-size  - Upload size analysis"
            echo "  verify       - Verify setup"
            echo "  help         - Show detailed help"
            echo ""
            echo "Run './demo.sh help' for detailed usage information"
            exit 1
            ;;
    esac
}

# Run main function
main "$@"
