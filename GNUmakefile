SENTRY_ORG=testorg-az
SENTRY_PROJECT=flutter
VERSION=`sentry-cli releases propose-version`
PREFIX=./obfuscated_symbols

all:.PHONY
	build_apk create_sentry_release associate_commits upload_symbols install_on_running_emulator

build_apk:.PHONY
	flutter build apk --obfuscate --split-debug-info=./obfuscated_symbols


upload_symbols:.PHONY
	sentry-cli upload-dif -o $(SENTRY_ORG) -p $(SENTRY_PROJECT) --wait $(PREFIX)


create_sentry_release:.PHONY
	sentry-cli releases -o $(SENTRY_ORG) new -p $(SENTRY_PROJECT) $(VERSION)

associate_commits:.PHONY
	sentry-cli releases -o $(SENTRY_ORG) -p $(SENTRY_PROJECT) set-commits --auto $(VERSION)


install_on_running_emulator:.PHONY
	flutter install

.PHONY: all build_apk upload_symbols create_sentry_release associate_commits install_on_running_emulator