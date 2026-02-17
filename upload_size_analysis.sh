#!/bin/bash
# Manual Size Analysis Upload Script for Flutter
# Usage: ./upload_size_analysis.sh [build-file] [platform]
#
# Examples:
#   ./upload_size_analysis.sh build/app/outputs/flutter-apk/app-release.apk android
#   ./upload_size_analysis.sh build/app/outputs/bundle/release/app-release.aab android
#   ./upload_size_analysis.sh YourApp.ipa ios
#   ./upload_size_analysis.sh YourApp.xcarchive ios

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_error() { echo -e "${RED}✗${NC} $1"; }
print_success() { echo -e "${GREEN}✓${NC} $1"; }
print_info() { echo -e "${BLUE}ℹ${NC} $1"; }
print_warning() { echo -e "${YELLOW}⚠${NC} $1"; }

# Check arguments
if [ $# -lt 2 ]; then
    print_error "Missing arguments"
    echo ""
    echo "Usage: ./upload_size_analysis.sh [build-file] [platform]"
    echo ""
    echo "Examples:"
    echo "  ./upload_size_analysis.sh build/app/outputs/flutter-apk/app-release.apk android"
    echo "  ./upload_size_analysis.sh YourApp.ipa ios"
    echo "  ./upload_size_analysis.sh build/app/outputs/bundle/release/app-release.aab android"
    echo ""
    exit 1
fi

BUILD_FILE="$1"
PLATFORM="$2"

# Load .env if exists
if [ -f .env ]; then
    print_info "Loading environment from .env"
    export $(grep -v '^#' .env | xargs)
fi

# Check if sentry-cli is installed
if ! command -v sentry-cli &> /dev/null; then
    print_error "sentry-cli is not installed"
    print_info "Install: curl -sL https://sentry.io/get-cli/ | bash"
    exit 1
fi

# Check if build file exists
if [ ! -f "$BUILD_FILE" ]; then
    print_error "Build file not found: $BUILD_FILE"
    exit 1
fi

# Check required environment variables
if [ -z "$SENTRY_AUTH_TOKEN" ]; then
    print_error "SENTRY_AUTH_TOKEN is not set"
    print_info "Set in .env or export SENTRY_AUTH_TOKEN=your-token"
    print_info "Generate token: https://sentry.io/settings/account/api/auth-tokens/"
    exit 1
fi

if [ -z "$SENTRY_ORG" ]; then
    print_error "SENTRY_ORG is not set"
    print_info "Set in .env or export SENTRY_ORG=your-org-slug"
    exit 1
fi

if [ -z "$SENTRY_PROJECT" ]; then
    print_error "SENTRY_PROJECT is not set"
    print_info "Set in .env or export SENTRY_PROJECT=your-project-slug"
    exit 1
fi

# Detect build format
BUILD_FORMAT=""
if [[ "$BUILD_FILE" == *.aab ]]; then
    BUILD_FORMAT="AAB (preferred for Android)"
elif [[ "$BUILD_FILE" == *.apk ]]; then
    BUILD_FORMAT="APK"
elif [[ "$BUILD_FILE" == *.xcarchive ]]; then
    BUILD_FORMAT="XCArchive (preferred for iOS)"
elif [[ "$BUILD_FILE" == *.ipa ]]; then
    BUILD_FORMAT="IPA"
else
    print_warning "Unknown build format: $BUILD_FILE"
fi

print_info "Uploading $PLATFORM build for size analysis..."
print_info "File: $BUILD_FILE"
print_info "Format: $BUILD_FORMAT"
print_info "Organization: $SENTRY_ORG"
print_info "Project: $SENTRY_PROJECT"
echo ""

# Get git metadata
HEAD_SHA=$(git rev-parse HEAD 2>/dev/null || echo "")
BASE_SHA=$(git merge-base HEAD origin/main 2>/dev/null || echo "")
HEAD_REF=$(git branch --show-current 2>/dev/null || echo "")
BASE_REF="main"

# Auto-detect repository name from git remote
GIT_REMOTE=$(git config --get remote.origin.url 2>/dev/null || echo "")
HEAD_REPO_NAME=""
VCS_PROVIDER=""

if [[ "$GIT_REMOTE" =~ github\.com[:/](.+)\.git$ ]]; then
    HEAD_REPO_NAME="${BASH_REMATCH[1]}"
    VCS_PROVIDER="github"
elif [[ "$GIT_REMOTE" =~ github\.com[:/](.+)$ ]]; then
    HEAD_REPO_NAME="${BASH_REMATCH[1]}"
    VCS_PROVIDER="github"
fi

# Check if we're in a PR (GitHub Actions sets this)
PR_NUMBER="${GITHUB_PR_NUMBER:-}"

# Display metadata being sent
print_info "Metadata:"
[ -n "$HEAD_SHA" ] && echo "  • HEAD SHA: ${HEAD_SHA:0:8}"
[ -n "$BASE_SHA" ] && echo "  • BASE SHA: ${BASE_SHA:0:8}"
[ -n "$HEAD_REF" ] && echo "  • HEAD REF: $HEAD_REF"
[ -n "$BASE_REF" ] && echo "  • BASE REF: $BASE_REF"
[ -n "$VCS_PROVIDER" ] && echo "  • VCS Provider: $VCS_PROVIDER"
[ -n "$HEAD_REPO_NAME" ] && echo "  • Repository: $HEAD_REPO_NAME"
[ -n "$PR_NUMBER" ] && echo "  • PR Number: $PR_NUMBER"
echo ""

# Build command
CMD="sentry-cli build upload \"$BUILD_FILE\" --org \"$SENTRY_ORG\" --project \"$SENTRY_PROJECT\" --build-configuration Release"

# Add optional metadata
[ -n "$HEAD_SHA" ] && CMD="$CMD --head-sha \"$HEAD_SHA\""
[ -n "$BASE_SHA" ] && CMD="$CMD --base-sha \"$BASE_SHA\""
[ -n "$HEAD_REF" ] && CMD="$CMD --head-ref \"$HEAD_REF\""
[ -n "$BASE_REF" ] && CMD="$CMD --base-ref \"$BASE_REF\""
[ -n "$VCS_PROVIDER" ] && CMD="$CMD --vcs-provider \"$VCS_PROVIDER\""
[ -n "$HEAD_REPO_NAME" ] && CMD="$CMD --head-repo-name \"$HEAD_REPO_NAME\""
[ -n "$PR_NUMBER" ] && CMD="$CMD --pr-number \"$PR_NUMBER\""

# Execute
if eval "$CMD"; then
    print_success "Size analysis upload completed"
    print_info "View results: https://sentry.io/organizations/$SENTRY_ORG/projects/$SENTRY_PROJECT/size-analysis/"
else
    print_error "Upload failed"
    exit 1
fi
