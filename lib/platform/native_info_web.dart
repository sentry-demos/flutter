// Web fallback for native platform strings (no dart:io on web).
import 'package:web/web.dart' as web;

String get nativeDartVersion => 'dart-web';
String get nativeOsName => 'web';
String get nativeOsVersion => web.window.navigator.userAgent;
