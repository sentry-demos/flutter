#!/bin/bash
set -e

# Setup env variables
export SENTRY_ORG=testorg-az
export SENTRY_PROJECT=flutter
export VERSION=android@1.0.0+3
export PREFIX=./obfuscated_symbols


# build fat apk & obfuscate, split debug into specified directory
flutter build apk --obfuscate --split-debug-info=./obfuscated_symbols

# directory 'obfuscated/symbols' contain the Dart debug info files but to include platform ones, use current dir.
sentry-cli upload-dif -o $SENTRY_ORG -p $SENTRY_PROJECT --include-sources --wait ./obfuscated_symbols
sentry-cli upload-dif -o $SENTRY_ORG -p $SENTRY_PROJECT --include-sources --wait .

# create new sentry release
sentry-cli releases -o $SENTRY_ORG new -p $SENTRY_PROJECT $VERSION

# associate commits
sentry-cli releases -o $SENTRY_ORG -p $SENTRY_PROJECT set-commits --auto $VERSION

#install apk on running emulator
flutter install