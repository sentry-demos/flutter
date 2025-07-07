#!/bin/bash
# Usage: ./run.sh
# This script builds the Flutter app with obfuscation and uploads debug symbols to Sentry.
# It loads Sentry secrets from .env if present, otherwise uses sentry.properties or env vars.

set -e

# Load .env if it exists
if [ -f .env ]; then
  echo "Loading environment variables from .env"
  export $(grep -v '^#' .env | xargs)
fi

# Build the app (Android example)
echo "Building Flutter APK with obfuscation and split-debug-info..."
flutter build apk --obfuscate --split-debug-info=build/debug-info

echo "Uploading debug symbols to Sentry..."
flutter pub run sentry_dart_plugin --include-sources

echo "Done."
