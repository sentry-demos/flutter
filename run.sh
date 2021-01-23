#!/bin/bash
set -e

# Setup env variables
export SENTRY_ORG=testorg-az
export SENTRY_PROJECT=flutter
export VERSION=android@1.0.0+3
export DIR=./obfuscated_symbols
export SENTRY_RELEASE=`sentry-cli releases propose-version`
#SENTRY_RELEASE will be used during SDK initialization (for release health) in dart.main & here for associating commits & debug info

# build fat apk & obfuscate, split debug into specified directory,
flutter build apk --dart-define=SENTRY_RELEASE=$SENTRY_RELEASE --obfuscate --split-debug-info=$DIR

# directory 'obfuscated/symbols' contain the Dart debug info files but to include platform ones, use current dir.
sentry-cli upload-dif -o $SENTRY_ORG -p $SENTRY_PROJECT --include-sources --wait .

# create new sentry release
sentry-cli releases -o $SENTRY_ORG new -p $SENTRY_PROJECT $VERSION

# associate commits
sentry-cli releases -o $SENTRY_ORG -p $SENTRY_PROJECT set-commits --auto $VERSION

#install apk on running emulator
flutter install