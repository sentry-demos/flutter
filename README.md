
# What is flutter

https://en.wikipedia.org/wiki/Flutter_(software)

## What does this demo do?

This demo builds off of the current tool store architype. The app currently compiles and has been tested for Android. This demo allows you to fetch from and post items to existing GCP endpoints. 

## Versions Summary:

| dependency      | version           
| ------------- |:-------------:| 
| flutter      | 1.22.x  |
| sentry-cli   | 1.61.0 |
| macOS | Catalina 10.15.7      |
| android Studio | 4.1.1     |



## Getting Started
1. Download Flutter. Be sure to add it to your PATH variable in your android studio terminal.
  * [Download Flutter for Mac](https://flutter.dev/docs/get-started/install/macos)
  * Test by running ```flutter``` in the android studio terminal.

2. Run ```flutter pub get``` to install dependencies. Dependencies can be found in pubspec.yaml

3. Setup your emulator. 
  * Double click shift or click magnifying glass in upper right hand corner of android studio. 
  * Start typing 'AVD'. Click AVD manager from returned search options. 
  * Click + create new device. This demo emulates successfully on a Pixel 3 API 30 with cpu architecture x86_64.  
  * Select the device from the list (eg Pixel). Click next. Select x86 images from options and download an x86_64 image. 
  * Select the device from device list on top menu bar of android studio. This should start the emulator.
 
[Which architectures are supported for emulation?](https://flutter.dev/docs/resources/faq#what-devices-and-os-versions-does-flutter-run-on)

4.  ```export SENTRY_AUTH_TOKEN=MY_AUTH_TOKEN``` in your terminal
5. Open the GNU makefile and update your SENTRY_PROJECT name.
6. Open main.dart and update the DSN key.
7. Run ```chmod +x run.sh``` in your terminal to make file executable. Then run ```./run.sh``` .This should create a release build of the flutter tool store and install the apk on your emulator. 
 - It will also create a Sentry release, associate commits, and upload debug symbols.

## TODOS

0. Implement user, tags, capture message. 
1. Configure demo for more streamlined local configuration. Currently all data is fetched from and posted to existing GCP endpoints (see checkout.dart & product_list.dart)
2. Refactor any code bloat. As this is a first step toward a flutter demo some redundancy and non idiomatic code can be expected.


