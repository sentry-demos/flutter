plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("io.sentry.android.gradle")
}

android {
    namespace = "com.example.empower_flutter"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "28.2.13676358"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
        languageVersion = "1.6"
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.empower_flutter"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

// Sentry Android Gradle plugin — scoped to ProGuard/R8 mapping handling only.
// It embeds a per-build ProGuard UUID into the APK and uploads the matching
// mapping during the release Gradle build, so Sentry can de-obfuscate DEX for
// both crash reports and the size-analysis breakdown. Org/project/token are
// read from the environment (demo.sh exports them via `.env`); when they're
// absent (e.g. a plain local build) the upload is simply skipped.
sentry {
    System.getenv("SENTRY_ORG")?.let { org.set(it) }
    System.getenv("SENTRY_PROJECT")?.let { projectName.set(it) }
    System.getenv("SENTRY_AUTH_TOKEN")?.let { authToken.set(it) }

    // Embed the mapping UUID into the APK and upload the mapping keyed by it.
    includeProguardMapping.set(true)
    autoUploadProguardMapping.set(true)

    // This app uses the sentry_flutter SDK, so the AGP must NOT add its own
    // native SDK or instrument bytecode (avoids duplicate/conflicting setup).
    autoInstallation {
        enabled.set(false)
    }
    tracingInstrumentation {
        enabled.set(false)
    }
}
