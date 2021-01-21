#!/bin/bash
set -e

export SENTRY_ORG=testorg-az
export SENTRY_PROJECT=flutter
export VERSION=`sentry-cli releases propose-version`
export PREFIX=./obfuscated_symbols
export ANDROID_SYMBOLS=./build/app/intermediates/cmake/debug/obj/x86_64

flutter build apk --obfuscate --split-debug-info=./obfuscated_symbols
sentry-cli upload-dif -o $SENTRY_ORG -p $SENTRY_PROJECT --wait $PREFIX
sentry-cli upload-dif -o $SENTRY_ORG -p $SENTRY_PROJECT --wait .
sentry-cli releases -o $SENTRY_ORG new -p $SENTRY_PROJECT $VERSION
sentry-cli releases -o $SENTRY_ORG -p $SENTRY_PROJECT set-commits --auto $VERSION
flutter install