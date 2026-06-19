/// Selects which Empower Plant backend the app's API calls target.
///
/// The standard journey uses the regular Flask backend. The "OTLP" journey
/// (started from the drawer) points the SAME screens at the OpenTelemetry-
/// instrumented backend instead, so the Flutter-initiated trace continues into
/// it via the propagated `sentry-trace`/`baggage` headers.
class BackendConfig {
  BackendConfig._();

  static const String standardBase = 'https://flask.empower-plant.com';
  static const String otlpBase = 'https://flask-otlp.empower-plant.com';

  /// The currently active backend base URL. Switched per-journey (with
  /// save/restore) by the screen that owns the journey — see [HomePage].
  static String base = standardBase;

  /// Endpoints, resolved against the currently active [base].
  static String get products => '$base/products';
  static String get checkout => '$base/checkout';
}
