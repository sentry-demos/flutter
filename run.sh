#!/bin/bash
# Enhanced Multi-Platform Build Script for Flutter with Sentry Integration
# Usage: ./run.sh [platform] [build-type] [--run]
#
# Platforms: android, ios, web, macos, linux, windows, all
# Build Types: debug, profile, release (default: release)
# Options: --run (launch app after building)
#
# Examples:
#   ./run.sh android           # Build Android APK (release)
#   ./run.sh android --run     # Build and run Android APK
#   ./run.sh ios debug         # Build iOS app (debug)
#   ./run.sh ios debug --run   # Build and run iOS app (debug)
#   ./run.sh web --run         # Build and serve web app
#   ./run.sh all               # Build for all platforms (release)

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Parse arguments
PLATFORM="${1:-android}"
BUILD_TYPE="release"
RUN_AFTER_BUILD=false

# Parse remaining arguments
for arg in "${@:2}"; do
    if [ "$arg" = "--run" ]; then
        RUN_AFTER_BUILD=true
    else
        BUILD_TYPE="$arg"
    fi
done

DEBUG_INFO_PATH="build/debug-info"

# Function to print colored messages
print_info() {
    echo -e "${BLUE}ℹ ${NC}$1"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

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
        # Check Homebrew installation
        HOMEBREW_FLUTTER="/opt/homebrew/Caskroom/flutter/3.38.7/flutter/bin/flutter"
        if [ -f "$HOMEBREW_FLUTTER" ]; then
            FLUTTER_CMD="$HOMEBREW_FLUTTER"
            print_success "Flutter found (Homebrew): $($FLUTTER_CMD --version | head -n 1)"
            print_info "Tip: Add to PATH with: source flutter_alias.sh"
        else
            print_error "Flutter is not installed or not in PATH"
            print_info "Please install Flutter: https://flutter.dev/docs/get-started/install"
            exit 1
        fi
    fi
}

# Flutter command wrapper
run_flutter() {
    $FLUTTER_CMD "$@"
}

# Check if Sentry CLI is installed
check_sentry_cli() {
    if ! command -v sentry-cli &> /dev/null; then
        print_warning "sentry-cli not found - size analysis uploads will be skipped"
        print_info "Install: curl -sL https://sentry.io/get-cli/ | bash"
        return 1
    fi
    return 0
}

# Get dependencies
get_dependencies() {
    print_info "Getting Flutter dependencies..."
$FLUTTER_CMD pub get
    print_success "Dependencies installed"
}

# Build for Android
build_android() {
    print_header "Building Android APK ($BUILD_TYPE)"

    if [ "$BUILD_TYPE" = "release" ]; then
        print_info "Building with obfuscation and symbol map generation..."
    $FLUTTER_CMD build apk \
            --$BUILD_TYPE \
            --obfuscate \
            --split-debug-info=$DEBUG_INFO_PATH \
            --extra-gen-snapshot-options=--save-obfuscation-map=build/app/obfuscation.map.json \
            --dart-define=SENTRY_DSN="$SENTRY_DSN" \
            --dart-define=SENTRY_RELEASE="$SENTRY_RELEASE" \
            --dart-define=SENTRY_ENVIRONMENT="$SENTRY_ENVIRONMENT"
    else
    $FLUTTER_CMD build apk --$BUILD_TYPE
    fi

    local apk_path="build/app/outputs/flutter-apk/app-$BUILD_TYPE.apk"
    print_success "Android APK built successfully"
    print_info "APK location: $apk_path"

    # Upload for size analysis
    if [ "$BUILD_TYPE" = "release" ]; then
        upload_size_analysis "$apk_path" "Android"
    fi
}

# Build for iOS
build_ios() {
    print_header "Building iOS App ($BUILD_TYPE)"

    if [ "$(uname)" != "Darwin" ]; then
        print_error "iOS builds require macOS"
        exit 1
    fi

    if [ "$BUILD_TYPE" = "release" ]; then
        print_info "Building with obfuscation and symbol map generation..."
    $FLUTTER_CMD build ios \
            --$BUILD_TYPE \
            --obfuscate \
            --split-debug-info=$DEBUG_INFO_PATH \
            --extra-gen-snapshot-options=--save-obfuscation-map=build/app/obfuscation.map.json \
            --dart-define=SENTRY_DSN="$SENTRY_DSN" \
            --dart-define=SENTRY_RELEASE="$SENTRY_RELEASE" \
            --dart-define=SENTRY_ENVIRONMENT="$SENTRY_ENVIRONMENT"
    else
    $FLUTTER_CMD build ios --$BUILD_TYPE
    fi

    print_success "iOS app built successfully"
    print_info "Build location: build/ios/iphoneos/Runner.app"

    # Upload for size analysis (iOS requires IPA, which needs manual creation via Xcode)
    # Note: Flutter doesn't create IPA directly, it needs to be created via Xcode Archive
    if [ "$BUILD_TYPE" = "release" ]; then
        print_info "For iOS size analysis, create an IPA via Xcode and upload manually:"
        print_info "  sentry-cli build upload YourApp.ipa --org your-org --project your-project --build-configuration Release"
    fi
}

# Build for Web
build_web() {
    print_header "Building Web App ($BUILD_TYPE)"

    if [ "$BUILD_TYPE" = "release" ]; then
        print_info "Building with source maps..."
    $FLUTTER_CMD build web \
            --$BUILD_TYPE \
            --source-maps \
            --dart-define=SENTRY_DSN="$SENTRY_DSN" \
            --dart-define=SENTRY_RELEASE="$SENTRY_RELEASE" \
            --dart-define=SENTRY_ENVIRONMENT="$SENTRY_ENVIRONMENT"
    else
    $FLUTTER_CMD build web --$BUILD_TYPE
    fi

    print_success "Web app built successfully"
    print_info "Build location: build/web/"
}

# Build for macOS
build_macos() {
    print_header "Building macOS App ($BUILD_TYPE)"

    if [ "$(uname)" != "Darwin" ]; then
        print_error "macOS builds require macOS"
        exit 1
    fi

    if [ "$BUILD_TYPE" = "release" ]; then
        print_info "Building with obfuscation and symbol map generation..."
    $FLUTTER_CMD build macos \
            --$BUILD_TYPE \
            --obfuscate \
            --split-debug-info=$DEBUG_INFO_PATH \
            --extra-gen-snapshot-options=--save-obfuscation-map=build/app/obfuscation.map.json \
            --dart-define=SENTRY_DSN="$SENTRY_DSN" \
            --dart-define=SENTRY_RELEASE="$SENTRY_RELEASE" \
            --dart-define=SENTRY_ENVIRONMENT="$SENTRY_ENVIRONMENT"
    else
    $FLUTTER_CMD build macos --$BUILD_TYPE
    fi

    print_success "macOS app built successfully"
    print_info "Build location: build/macos/Build/Products/Release/empower_flutter.app"
}

# Build for Linux
build_linux() {
    print_header "Building Linux App ($BUILD_TYPE)"

    if [ "$(uname)" != "Linux" ]; then
        print_warning "Linux builds are optimized on Linux systems"
    fi

    if [ "$BUILD_TYPE" = "release" ]; then
        print_info "Building with obfuscation and symbol map generation..."
    $FLUTTER_CMD build linux \
            --$BUILD_TYPE \
            --obfuscate \
            --split-debug-info=$DEBUG_INFO_PATH \
            --extra-gen-snapshot-options=--save-obfuscation-map=build/app/obfuscation.map.json \
            --dart-define=SENTRY_DSN="$SENTRY_DSN" \
            --dart-define=SENTRY_RELEASE="$SENTRY_RELEASE" \
            --dart-define=SENTRY_ENVIRONMENT="$SENTRY_ENVIRONMENT"
    else
    $FLUTTER_CMD build linux --$BUILD_TYPE
    fi

    print_success "Linux app built successfully"
    print_info "Build location: build/linux/x64/release/bundle/"
}

# Build for Windows
build_windows() {
    print_header "Building Windows App ($BUILD_TYPE)"

    if [ "$(uname)" = "Darwin" ]; then
        print_error "Windows builds cannot be performed on macOS"
        exit 1
    fi

    if [ "$BUILD_TYPE" = "release" ]; then
        print_info "Building with obfuscation and symbol map generation..."
    $FLUTTER_CMD build windows \
            --$BUILD_TYPE \
            --obfuscate \
            --split-debug-info=$DEBUG_INFO_PATH \
            --extra-gen-snapshot-options=--save-obfuscation-map=build/app/obfuscation.map.json \
            --dart-define=SENTRY_DSN="$SENTRY_DSN" \
            --dart-define=SENTRY_RELEASE="$SENTRY_RELEASE" \
            --dart-define=SENTRY_ENVIRONMENT="$SENTRY_ENVIRONMENT"
    else
    $FLUTTER_CMD build windows --$BUILD_TYPE
    fi

    print_success "Windows app built successfully"
    print_info "Build location: build/windows/x64/runner/Release/"
}

# Run Android app
run_android() {
    print_header "Launching Android App"

    # Find adb
    local ADB_CMD="adb"
    if ! command -v adb &> /dev/null; then
        # Check common Android SDK locations
        if [ -f "$HOME/Library/Android/sdk/platform-tools/adb" ]; then
            ADB_CMD="$HOME/Library/Android/sdk/platform-tools/adb"
        elif [ -f "$HOME/Android/Sdk/platform-tools/adb" ]; then
            ADB_CMD="$HOME/Android/Sdk/platform-tools/adb"
        else
            print_error "adb not found. Install Android SDK platform-tools"
            return 1
        fi
    fi

    local device_count=$($ADB_CMD devices | grep -w "device" | wc -l)
    if [ "$device_count" -eq 0 ]; then
        print_error "No Android device/emulator connected"
        print_info "Start an emulator or connect a device first"
        return 1
    fi

    local apk_path="build/app/outputs/flutter-apk/app-$BUILD_TYPE.apk"

    print_info "Installing APK on device..."
    $ADB_CMD install -r "$apk_path"

    print_info "Launching app..."
    $ADB_CMD shell am start -n com.example.empower_flutter/.MainActivity

    print_success "Android app launched successfully"
    print_info "View logs with: $ADB_CMD logcat | grep flutter"
}

# Run iOS app
run_ios() {
    print_header "Launching iOS App"

    if [ "$(uname)" != "Darwin" ]; then
        print_error "iOS apps can only be run on macOS"
        return 1
    fi

    print_info "Launching iOS simulator..."

    # Use flutter run to launch on simulator
    $FLUTTER_CMD run -d ios --$BUILD_TYPE

    print_success "iOS app launched on simulator"
}

# Run Web app
run_web() {
    print_header "Serving Web App"

    print_info "Starting local web server on port 8080..."
    print_info "Press Ctrl+C to stop the server"

    # Serve the web build
    cd build/web

    if command -v python3 &> /dev/null; then
        python3 -m http.server 8080
    elif command -v python &> /dev/null; then
        python -m SimpleHTTPServer 8080
    else
        print_error "Python not found. Cannot start web server"
        print_info "Install Python or use: flutter run -d chrome"
        return 1
    fi
}

# Run macOS app
run_macos() {
    print_header "Launching macOS App"

    if [ "$(uname)" != "Darwin" ]; then
        print_error "macOS apps can only be run on macOS"
        return 1
    fi

    local app_path="build/macos/Build/Products/Release/empower_flutter.app"

    if [ ! -d "$app_path" ]; then
        app_path="build/macos/Build/Products/Debug/empower_flutter.app"
    fi

    if [ ! -d "$app_path" ]; then
        print_error "App bundle not found at: $app_path"
        return 1
    fi

    print_info "Launching macOS app..."
    open "$app_path"

    print_success "macOS app launched successfully"
}

# Run Linux app
run_linux() {
    print_header "Launching Linux App"

    local exe_path="build/linux/x64/release/bundle/empower_flutter"

    if [ ! -f "$exe_path" ]; then
        exe_path="build/linux/x64/debug/bundle/empower_flutter"
    fi

    if [ ! -f "$exe_path" ]; then
        print_error "Executable not found at: $exe_path"
        return 1
    fi

    print_info "Launching Linux app..."
    "$exe_path" &

    print_success "Linux app launched successfully"
}

# Run Windows app
run_windows() {
    print_header "Launching Windows App"

    local exe_path="build/windows/x64/runner/Release/empower_flutter.exe"

    if [ ! -f "$exe_path" ]; then
        exe_path="build/windows/x64/runner/Debug/empower_flutter.exe"
    fi

    if [ ! -f "$exe_path" ]; then
        print_error "Executable not found at: $exe_path"
        return 1
    fi

    print_info "Launching Windows app..."
    start "$exe_path"

    print_success "Windows app launched successfully"
}

# Upload debug symbols to Sentry
upload_symbols() {
    if [ "$BUILD_TYPE" != "release" ]; then
        print_info "Skipping debug symbol upload for $BUILD_TYPE build"
        return
    fi

    print_header "Uploading Debug Symbols to Sentry"

    # Check if sentry.properties or .env has required config
    if [ -z "$SENTRY_DSN" ] && [ ! -f "sentry.properties" ]; then
        print_warning "Sentry not configured. Skipping symbol upload."
        print_info "To enable: Create sentry.properties or set SENTRY_DSN in .env"
        return
    fi

    print_info "Running sentry_dart_plugin with source upload..."

    # Run sentry_dart_plugin and capture output
    # --include-sources uploads source code for better stack trace context
    set +e  # Temporarily allow errors
    $FLUTTER_CMD pub run sentry_dart_plugin --include-sources > /tmp/sentry_upload.log 2>&1
    local exit_code=$?
    set -e  # Re-enable exit on error

    # Display the output
    cat /tmp/sentry_upload.log

    # Check results
    # Check if symbols and release were created successfully, regardless of final exit code
    local symbols_uploaded=false
    if grep -q "Dart symbol map upload summary.*succeeded=[1-9].*failed=0" /tmp/sentry_upload.log || \
       grep -q "Nothing to upload, all files are on the server" /tmp/sentry_upload.log; then
        symbols_uploaded=true
    fi

    local release_created=false
    if grep -q "Created release" /tmp/sentry_upload.log; then
        release_created=true
    fi

    if [ $exit_code -eq 0 ]; then
        print_success "Debug symbols uploaded to Sentry"
    elif [ "$symbols_uploaded" = true ] && [ "$release_created" = true ]; then
        # Symbols uploaded successfully but got non-zero exit (usually repo integration)
        if grep -q "Unknown repo" /tmp/sentry_upload.log; then
            print_success "Debug symbols uploaded to Sentry"
            print_warning "Repository integration skipped (commits=skip in sentry.properties)"
            print_info "To enable commit tracking, update your auth token with 'org:read' scope and set commits=auto"
        elif grep -q "403" /tmp/sentry_upload.log; then
            print_success "Debug symbols uploaded to Sentry"
            print_warning "Repository integration failed (403 - missing org:read permission)"
            print_info "Your auth token needs 'org:read' scope for full repository integration"
        else
            print_success "Debug symbols uploaded to Sentry"
            print_warning "Repository integration failed with exit code $exit_code"
        fi
    else
        print_error "Failed to upload debug symbols"
        print_info "Check your sentry.properties configuration"
    fi
}

# Upload build for size analysis
upload_size_analysis() {
    local build_file="$1"
    local platform="$2"

    if [ "$BUILD_TYPE" != "release" ]; then
        print_info "Skipping size analysis for $BUILD_TYPE build"
        return
    fi

    # Check if size analysis is enabled
    if [ "${SENTRY_SIZE_ANALYSIS_ENABLED}" != "true" ]; then
        print_info "Size analysis disabled. Set SENTRY_SIZE_ANALYSIS_ENABLED=true to enable"
        return
    fi

    # Check if sentry-cli is installed
    if ! check_sentry_cli; then
        return
    fi

    # Check if build file exists
    if [ ! -f "$build_file" ]; then
        print_warning "Build file not found: $build_file"
        return
    fi

    print_header "Uploading $platform Build for Size Analysis"

    # Get metadata from environment or git
    local org="${SENTRY_ORG}"
    local project="${SENTRY_PROJECT}"
    local head_sha="${CI_COMMIT_SHA:-$(git rev-parse HEAD 2>/dev/null || echo '')}"
    local base_sha="${CI_MERGE_REQUEST_DIFF_BASE_SHA:-$(git merge-base HEAD origin/main 2>/dev/null || echo '')}"
    local head_ref="${CI_COMMIT_REF_NAME:-$(git branch --show-current 2>/dev/null || echo '')}"
    local base_ref="${CI_MERGE_REQUEST_TARGET_BRANCH_NAME:-main}"
    local pr_number="${CI_MERGE_REQUEST_IID:-${GITHUB_PR_NUMBER:-}}"

    # Check required fields
    if [ -z "$org" ] || [ -z "$project" ]; then
        print_warning "SENTRY_ORG and SENTRY_PROJECT must be set for size analysis"
        print_info "Add them to .env or sentry.properties"
        return
    fi

    print_info "Uploading: $build_file"
    print_info "Organization: $org"
    print_info "Project: $project"

    # Build the sentry-cli command
    local cmd="sentry-cli build upload \"$build_file\" --org \"$org\" --project \"$project\" --build-configuration Release"

    # Add optional metadata
    [ -n "$head_sha" ] && cmd="$cmd --head-sha \"$head_sha\""
    [ -n "$base_sha" ] && cmd="$cmd --base-sha \"$base_sha\""
    [ -n "$head_ref" ] && cmd="$cmd --head-ref \"$head_ref\""
    [ -n "$base_ref" ] && cmd="$cmd --base-ref \"$base_ref\""
    [ -n "$pr_number" ] && cmd="$cmd --pr-number \"$pr_number\""

    print_info "Running: sentry-cli build upload..."

    # Execute the command
    if eval "$cmd"; then
        print_success "Size analysis data uploaded successfully"
        print_info "View results: https://sentry.io/organizations/$org/projects/$project/size-analysis/"
    else
        print_error "Failed to upload size analysis data"
        print_info "Check your sentry-cli authentication and configuration"
    fi
}

# Build all platforms
build_all() {
    print_header "Building for All Platforms ($BUILD_TYPE)"

    local os_type="$(uname)"

    # Android (works on all platforms)
    build_android

    # Web (works on all platforms)
    build_web

    # Platform-specific builds
    if [ "$os_type" = "Darwin" ]; then
        build_ios
        build_macos
        print_warning "Skipping Linux and Windows (requires respective OS)"
    elif [ "$os_type" = "Linux" ]; then
        build_linux
        print_warning "Skipping iOS, macOS (requires macOS)"
        print_warning "Skipping Windows (requires Windows)"
    else
        # Windows
        build_windows
        print_warning "Skipping iOS, macOS (requires macOS)"
        print_warning "Skipping Linux (requires Linux)"
    fi

    upload_symbols
}

# Main execution
main() {
    print_header "Flutter Multi-Platform Build Script"
    local run_status=""
    if [ "$RUN_AFTER_BUILD" = true ]; then
        run_status=" | Run: Yes"
    fi
    print_info "Platform: $PLATFORM | Build Type: $BUILD_TYPE$run_status"

    # Check Flutter installation
    check_flutter

    # Load environment variables
    load_env

    # Get dependencies
    get_dependencies

    # Build based on platform
    case "$PLATFORM" in
        android)
            build_android
            upload_symbols
            if [ "$RUN_AFTER_BUILD" = true ]; then
                run_android
            fi
            ;;
        ios)
            build_ios
            upload_symbols
            if [ "$RUN_AFTER_BUILD" = true ]; then
                run_ios
            fi
            ;;
        web)
            build_web
            upload_symbols
            if [ "$RUN_AFTER_BUILD" = true ]; then
                run_web
            fi
            ;;
        macos)
            build_macos
            upload_symbols
            if [ "$RUN_AFTER_BUILD" = true ]; then
                run_macos
            fi
            ;;
        linux)
            build_linux
            upload_symbols
            if [ "$RUN_AFTER_BUILD" = true ]; then
                run_linux
            fi
            ;;
        windows)
            build_windows
            upload_symbols
            if [ "$RUN_AFTER_BUILD" = true ]; then
                run_windows
            fi
            ;;
        all)
            build_all
            if [ "$RUN_AFTER_BUILD" = true ]; then
                print_warning "Cannot auto-run when building for all platforms"
                print_info "Build for a specific platform with --run to auto-launch"
            fi
            ;;
        *)
            print_error "Unknown platform: $PLATFORM"
            echo ""
            echo "Usage: ./run.sh [platform] [build-type] [--run]"
            echo ""
            echo "Platforms:"
            echo "  android  - Build Android APK"
            echo "  ios      - Build iOS app (macOS only)"
            echo "  web      - Build web app"
            echo "  macos    - Build macOS app (macOS only)"
            echo "  linux    - Build Linux app"
            echo "  windows  - Build Windows app"
            echo "  all      - Build for all available platforms"
            echo ""
            echo "Build Types:"
            echo "  debug    - Debug build (no obfuscation)"
            echo "  profile  - Profile build"
            echo "  release  - Release build with obfuscation (default)"
            echo ""
            echo "Options:"
            echo "  --run    - Launch the app after building"
            echo ""
            echo "Examples:"
            echo "  ./run.sh android              # Build Android APK"
            echo "  ./run.sh android --run        # Build and run on connected device"
            echo "  ./run.sh ios debug --run      # Build iOS debug and launch simulator"
            echo "  ./run.sh web release --run    # Build web and serve locally"
            echo ""
            exit 1
            ;;
    esac

    print_header "Build Complete!"
    print_success "All tasks completed successfully"
}

# Run main function
main
