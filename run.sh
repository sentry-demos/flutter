#!/bin/bash
set -e

# Setup env variables
export SENTRY_ORG=testorg-az
export SENTRY_PROJECT=flutter_updates
export DIR=./obfuscated_symbols
export SENTRY_RELEASE=sentry_flutter_app@0.4.0+4
export SENTRY_ENVIRONMENT=prod

#SENTRY_RELEASE will be used during SDK initialization (for release health) in dart.main & here for associating commits & debug info

# build fat apk & obfuscate, split debug into specified directory,
flutter build apk  --dart-define=SENTRY_ENVIRONMENT=$SENTRY_ENVIRONMENT --dart-define=SENTRY_RELEASE=$SENTRY_RELEASE --obfuscate --split-debug-info=$DIR

# directory 'obfuscated/symbols' contain the Dart debug info files but to include platform ones, use current dir.
sentry-cli upload-dif -o $SENTRY_ORG -p $SENTRY_PROJECT --include-sources --wait . $DIR

# create new sentry release
sentry-cli releases -o $SENTRY_ORG new -p $SENTRY_PROJECT $SENTRY_RELEASE

# associate commits
sentry-cli releases -o $SENTRY_ORG -p $SENTRY_PROJECT set-commits --auto $SENTRY_RELEASE

#install apk on running emulator
flutter install