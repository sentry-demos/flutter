SENTRY_ORG=testorg-az
SENTRY_PROJECT=flutter
VERSION=`sentry-cli releases propose-version`
PREFIX=./obfuscated_symbols

all:
	build_apk create_sentry_release associate_commits upload_symbols install_on_running_emulator

build_apk:
	flutter build apk --obfuscate --split-debug-info=./obfuscated_symbols

upload_symbols:
	sentry-cli upload-dif -o $(SENTRY_ORG) -p $(SENTRY_PROJECT) --wait $(PREFIX)

create_sentry_release:
	sentry-cli releases -o $(SENTRY_ORG) new -p $(SENTRY_PROJECT) $(VERSION)

associate_commits:
	sentry-cli releases -o $(SENTRY_ORG) -p $(SENTRY_PROJECT) set-commits --auto $(VERSION)

install_on_running_emulator:
	flutter install