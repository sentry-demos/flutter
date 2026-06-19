// Native (dart:io) platform strings. Used on mobile/desktop builds.
import 'dart:io' as io;

String get nativeDartVersion => io.Platform.version;
String get nativeOsName => io.Platform.operatingSystem;
String get nativeOsVersion => io.Platform.operatingSystemVersion;
