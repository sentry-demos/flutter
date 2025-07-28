# empower_flutter

A demo Flutter application with full Sentry instrumentation and best practices for error monitoring, performance, and user feedback.

## Getting Started

### Prerequisites

- Flutter SDK >= 3.24.0 (Dart >= 3.5.0)
- Xcode (for iOS simulator)
- Android Studio (for Android emulator)
- Sentry account (for error monitoring)

### Setup

1. **Clone the repository:**
   ```sh
   git clone https://github.com/Prithvirajkumar/empower_flutter.git
   cd empower_flutter
   ```
2. **Install dependencies:**
   ```sh
   flutter pub get
   ```
3. **Configure Sentry credentials:**
   - Copy `.env.example` to `.env` and set your SENTRY_DSN, SENTRY_RELEASE, SENTRY_ENVIRONMENT.
   - Each engineer should set their identifier in `lib/se_config.dart`:
     ```dart
     const String se = 'YourName';
     ```

### Building and Running with `run.sh`

You can use the provided `run.sh` script to build the app and upload debug symbols/source context to Sentry automatically.

- **To build for iOS:**
  ```sh
  ./run.sh ios
  ```
- **To build for Android:**
  ```sh
  ./run.sh android
  ```
- The script will handle Flutter build, Sentry symbol upload, and source context upload.

### Running on iOS Simulator (manual)

1. Open the project in Xcode or run:
   ```sh
   flutter run -d ios
   ```
2. If you see build errors, ensure CocoaPods are installed and run:
   ```sh
   cd ios && pod install && cd ..
   flutter clean && flutter pub get
   flutter run -d ios
   ```

### Running on Android Emulator (manual)

1. Start an Android emulator from Android Studio or run:
   ```sh
   flutter run -d android
   ```

## Sentry Instrumentation & Features

- **Sentry SDK Integration:**

  - Uses `sentry_flutter` for Dart/Flutter error and performance monitoring.
  - Sentry is initialized in `lib/sentry_setup.dart` with best practices.
  - Credentials and environment are loaded from `.env` and Dart environment variables.

- **Error Tagging & Grouping:**

  - All Sentry events are tagged with an engineer identifier (`se` tag) from `lib/se_config.dart`.
  - Events are fingerprinted for per-engineer grouping.

- **User Feedback Popup:**

  - Custom feedback dialog appears for Dart exceptions and checkout errors.
  - Feedback is sent to Sentry and associated with the event.

- **Native Exception Filtering:**

  - Native exceptions (C++ segfaults, Kotlin exceptions, ANRs) are filtered and do not trigger the feedback popup.

- **Performance Monitoring:**

  - Tracing is enabled (`tracesSampleRate = 1.0`).
  - Profiling is enabled for iOS/macOS (`profilesSampleRate = 1.0`).

- **Release Health & Environment:**

  - Release and environment are set for Sentry events.

- **Screenshot & View Hierarchy Attachments:**

  - Errors include screenshots and view hierarchy for better debugging.

- **Breadcrumbs & Device Data:**

  - Automatic breadcrumbs and device data are captured.

- **Debug Symbol & Source Context Upload:**

  - Uses `sentry_dart_plugin` and `run.sh` for automated symbol/source uploads.

- **PII & Logging:**
  - `sendDefaultPii = true` and `enableLogs = true` for richer event context.

## Project Structure

- `lib/main.dart` — App entrypoint
- `lib/sentry_setup.dart` — Sentry initialization and configuration
- `lib/se_config.dart` — Engineer tag configuration
- `lib/navbar_destination.dart`, `lib/checkout.dart` — Demo error triggers and feedback

## Notes

- To test Sentry integration, use the navigation drawer or checkout flow to trigger errors and send feedback.
- For production, update Sentry DSN and environment variables as needed.
- Use `run.sh` for automated build and Sentry symbol/source uploads.

For more details, see [Sentry Flutter documentation](https://docs.sentry.io/platforms/flutter/).
