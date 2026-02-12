#!/bin/bash
# Setup Verification Script
# Checks if all required configurations are in place

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
print_header() {
    echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
}

ISSUES=0

print_header "Verifying Flutter + Sentry Setup"

# Check Flutter
print_info "Checking Flutter installation..."
if command -v flutter &> /dev/null; then
    FLUTTER_VERSION=$(flutter --version | head -n 1)
    print_success "Flutter found: $FLUTTER_VERSION"
else
    print_error "Flutter not found in PATH"
    print_info "Install Flutter: https://docs.flutter.dev/get-started/install"
    ISSUES=$((ISSUES + 1))
fi

# Check .env file
print_info "Checking .env configuration..."
if [ -f .env ]; then
    print_success ".env file exists"

    # Check for placeholder values
    if grep -q "your_dsn" .env || grep -q "your_auth_token" .env; then
        print_warning ".env contains placeholder values - needs configuration"
        print_info "Update .env with your actual Sentry credentials"
        ISSUES=$((ISSUES + 1))
    else
        print_success ".env appears to be configured"
    fi

    # Check for required variables
    if grep -q "SENTRY_DSN=" .env && [ -n "$(grep SENTRY_DSN= .env | cut -d= -f2)" ]; then
        print_success "SENTRY_DSN is set"
    else
        print_warning "SENTRY_DSN not set in .env"
        ISSUES=$((ISSUES + 1))
    fi
else
    print_warning ".env file not found"
    print_info "Copy .env.example to .env and configure it"
    ISSUES=$((ISSUES + 1))
fi

# Check sentry.properties
print_info "Checking sentry.properties configuration..."
if [ -f sentry.properties ]; then
    print_success "sentry.properties exists"

    # Check for org
    if grep -q "^org=" sentry.properties; then
        ORG=$(grep "^org=" sentry.properties | cut -d= -f2)
        print_success "Organization: $ORG"
    fi

    # Check for project
    if grep -q "^project=" sentry.properties; then
        PROJECT=$(grep "^project=" sentry.properties | cut -d= -f2)
        print_success "Project: $PROJECT"
    fi

    # Check for auth token
    if grep -q "^auth_token=" sentry.properties; then
        print_success "Auth token is configured"
    else
        print_warning "Auth token not set in sentry.properties"
        ISSUES=$((ISSUES + 1))
    fi
else
    print_warning "sentry.properties not found (optional)"
    print_info "Debug symbols will use .env configuration"
fi

# Check build script
print_info "Checking build scripts..."
if [ -x run.sh ]; then
    print_success "run.sh is executable"
else
    print_warning "run.sh is not executable"
    print_info "Run: chmod +x run.sh"
    ISSUES=$((ISSUES + 1))
fi

if [ -x upload_size_analysis.sh ]; then
    print_success "upload_size_analysis.sh is executable"
else
    print_warning "upload_size_analysis.sh is not executable"
    print_info "Run: chmod +x upload_size_analysis.sh"
    ISSUES=$((ISSUES + 1))
fi

# Check Sentry CLI (optional)
print_info "Checking Sentry CLI (optional for size analysis)..."
if command -v sentry-cli &> /dev/null; then
    SENTRY_CLI_VERSION=$(sentry-cli --version | head -n 1)
    print_success "Sentry CLI found: $SENTRY_CLI_VERSION"
else
    print_info "Sentry CLI not found (optional)"
    print_info "Install for size analysis: curl -sL https://sentry.io/get-cli/ | bash"
fi

# Check pubspec.yaml
print_info "Checking pubspec.yaml..."
if [ -f pubspec.yaml ]; then
    if grep -q "sentry_flutter: \^9.10.0" pubspec.yaml; then
        print_success "Sentry Flutter SDK 9.10.0 configured"
    else
        print_warning "Sentry Flutter SDK version mismatch"
        ISSUES=$((ISSUES + 1))
    fi
fi

# Check key Dart files
print_info "Checking instrumentation files..."
REQUIRED_FILES=(
    "lib/main.dart"
    "lib/sentry_setup.dart"
    "lib/navbar_destination.dart"
    "lib/product_details.dart"
    "lib/checkout.dart"
)

for file in "${REQUIRED_FILES[@]}"; do
    if [ -f "$file" ]; then
        print_success "$file exists"
    else
        print_error "$file not found"
        ISSUES=$((ISSUES + 1))
    fi
done

# Summary
print_header "Verification Summary"

if [ $ISSUES -eq 0 ]; then
    print_success "All checks passed! ✨"
    echo ""
    print_info "Next steps:"
    echo "  1. Run: flutter pub get"
    echo "  2. Update .env with your Sentry credentials (if needed)"
    echo "  3. Run: ./run.sh android debug"
    echo "  4. Test the app and check Sentry dashboard"
    echo ""
    print_info "Documentation: See NEXT_STEPS.md for detailed instructions"
else
    print_warning "Found $ISSUES issue(s) that need attention"
    echo ""
    print_info "Please address the issues above before proceeding"
    print_info "See NEXT_STEPS.md for detailed setup instructions"
fi

exit 0
