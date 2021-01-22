#!/bin/bash
set -e

# Setup env variables
export SENTRY_ORG=testorg-az
export SENTRY_PROJECT=flutter
export VERSION=`sentry-cli releases propose-version`
export PREFIX=./obfuscated_symbols


# build fat apk & obfuscate, split debug into specified directory
flutter build apk --obfuscate --split-debug-info=./obfuscated_symbols

# upload debug symbols
sentry-cli upload-dif -o $SENTRY_ORG -p $SENTRY_PROJECT --wait $PREFIX
sentry-cli upload-dif -o $SENTRY_ORG -p $SENTRY_PROJECT --wait .

# create new sentry release
sentry-cli releases -o $SENTRY_ORG new -p $SENTRY_PROJECT $VERSION

# associate commits
sentry-cli releases -o $SENTRY_ORG -p $SENTRY_PROJECT set-commits --auto $VERSION

#install apk on running emulator
flutter install