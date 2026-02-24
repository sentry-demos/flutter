#!/bin/bash
# This build script should not be included in the app bundle
# It's only used during development

echo "Building Flutter app..."
flutter build apk --release
echo "Build complete!"
