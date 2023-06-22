
# What is flutter?

[Flutter Docs](https://flutter.dev/docs)
[Flutter Wiki](https://en.wikipedia.org/wiki/Flutter_(software))


## What does this demo do?

This demo builds off of the current tool store archetype. The app currently compiles and has been tested for Android. This demo allows you to fetch from and post items to existing GCP endpoints. 

## Versions Summary:

| dependency      | version           
| ------------- |:-------------:| 
| flutter      | >=3.0.0 <4.0.0 |
| sentry-flutter   | 1.61.0 |
| macOS | 13.2 (22D49)     |
| android Studio | Arctic Fox   7.7.0|





## Getting Started
1. Download Flutter & Android Studio. Be sure to add it to your PATH variable in your android studio terminal.
  * [Download Flutter for Mac](https://flutter.dev/docs/get-started/install/macos)
  * Test by running ```flutter``` in the android studio terminal.

2. Run ```flutter pub get``` to install dependencies. Dependencies can be found in pubspec.yaml

3. Setup your emulator. 
  * Double click ```shift``` or click magnifying glass in upper right hand corner of android studio. 
  * Start typing ```AVD```. Click ```AVD manager``` from returned search options. 
  * Click `````+ create new device`````. This demo emulates successfully on a ```Pixel 3 API 33 with cpu architecture x86_64```. Be sure to provision the device with enough system memory or running in dev mode or installing may fail.
  * Select the device from the list (eg Pixel) > Click ```next``` > Select x```86 images``` from options and download an x86_64 image. 
  * Select the device from device list on top menu bar of android studio. This should start the emulator.
  * Run in dev mode with ```flutter run```


 
[Which architectures are supported for emulation?](https://flutter.dev/docs/resources/faq#what-devices-and-os-versions-does-flutter-run-on)
Packaging for release:
4.  ```export SENTRY_AUTH_TOKEN=MY_AUTH_TOKEN``` in your terminal
5. Open ```run.sh``` and update your SENTRY_PROJECT name & version.
6. Open main.dart and update the DSN key.
7. Versioning: Currently versioning is hard coded in pubspec.yaml & run.sh. If you wish to create a new release in Sentry be sure to update in both places. To my knowledge using [--build-name=myVersion](https://flutter.dev/docs/deployment/android#updating-the-apps-version-number) in run.sh will not work.
8. CD into the project and run ```chmod +x run.sh``` in your terminal to make file executable. Then run ```./run.sh``` .This should create a release build of the flutter tool store and install the apk on your emulator. It will also create a Sentry release, associate commits, and upload debug symbols.

## TODOS

Generally we want to fast forward this demo into the present. Dependencies have been updated. This will include sdk related updates & business logic updates:

1. a. Change data sources. Currently the demo fetches data from a defunct source. We will need to update the data source (here) lib/product_list.dart ln.16.
   b. Change data models to match resource shape returned from data source e.g. (https://application-monitoring-flask-dot-sales-engineering-sf.appspot.com/products). Specifically, classes ResponseItem (product_list.dart ln 158), ProductArguments (sentry_flutter_app/product_details.dart ln 141), ItemData /models/cart_state_model.dart ln 68
   c. Update /assets with those returned from step (b) above. [Flutter assets](https://docs.flutter.dev/ui/assets-and-images).
   d. Update lib/checkout.dart ln.16 to reflect correct endpoint https://application-monitoring-flask-dot-sales-engineering-sf.appspot.com/checkout
   
   Sdk Additions:
2. a. Add [performance monitoring](https://docs.sentry.io/platforms/flutter/performance/instrumentation/automatic-instrumentation/?original_referrer=https%3A%2F%2Fwww.google.com%2F#routing-instrumentation) to app http requests.
   b. Add screenshots to app.
   c. Add http client instrumentation
   d. (stretch) file I/O or database instrumentation.
   
   

Misc. 
1. Configure demo for more streamlined local configuration? Currently all data is fetched from and posted to existing GCP endpoints (see checkout.dart & product_list.dart)
2. Refactor any code bloat. As this is a first step toward a flutter demo some redundancy and non idiomatic code can be expected.
3. Add ios & web builds eventually.

## Known Limitations (may need updating)

1. Flutter split-debug-info and obfuscate flag aren't supported on iOS yet, but only on Android, if this feature is enabled, Dart stack traces are not human readable
2. If you enable the split-debug-info feature, you must upload the Debug Symbols manually.
3. Uploadng Symbols: Android NDK, You must to do it manually. Do not use the uploadNativeSymbols flag from the Sentry Gradle Plugin, because it's not yet supported.
4. Some Android NDK versions greater than .20 may throw during build process due to missing ABIs. Detail [here](https://github.com/flutter/flutter/issues/76393#issuecomment-784014307)

[Known Limitations](https://github.com/getsentry/sentry-dart/tree/main/flutter#known-limitations)