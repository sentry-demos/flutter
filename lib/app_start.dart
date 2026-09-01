// ignore_for_file: experimental_member_use

import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// Coordinates standalone app-start extension for this demo.
///
/// Call [begin] from `appRunner` *before* `runApp` so `extendAppStart`
/// lands before the first frame. Custom children are parented with
/// `SentryFlutter.getExtendedAppStartSpanV2()` because the demo uses stream
/// lifecycle — `getExtendedAppStartSpan()` is the static-lifecycle getter and
/// returns null here.
///
/// The extension stays open through feature-flag hydration, the first-frame
/// cache write, and the first catalog fetch, then `finishExtendedAppStart()`
/// releases it. If the catalog never arrives, we still finish before the SDK's
/// 30s deadline.
class AppStart {
  static const _featureFlagCount = 15;
  static const _catalogTimeout = Duration(seconds: 20);

  static final Completer<void> _catalogReady = Completer<void>();
  static Future<void>? _extension;

  /// Must run before the first frame. Safe to call only once.
  static void begin() {
    if (_extension != null) {
      return;
    }
    SentryFlutter.extendAppStart();
    _extension = _run();
    unawaited(_extension!);
  }

  static Future<void> _run() async {
    try {
      await span(
        'Hydrate feature flags',
        _hydrateFeatureFlags,
        op: 'app.init',
      );
      await _catalogReady.future.timeout(
        _catalogTimeout,
        onTimeout: () {},
      );
    } finally {
      await SentryFlutter.finishExtendedAppStart();
    }
  }

  /// Runs [work] as a child of the extended app-start span when one is open.
  ///
  /// In stream mode the extension is not the active span, so we must pass it
  /// as `parentSpan`. The callback then becomes the active span (zone), so
  /// auto-instrumentation such as `sentry_file` nests under it instead of
  /// `ui.load`. If the extension has already ended (or never started —
  /// e.g. web/desktop), [work] runs without opening a stray root span.
  static Future<T> span<T>(
    String name,
    Future<T> Function() work, {
    String op = 'app.init',
  }) async {
    final parent = _extendedParent();
    if (parent == null) {
      return work();
    }
    return Sentry.startSpan(name, (span) async {
      span.setAttribute('sentry.op', SentryAttribute.string(op));
      return work();
    }, parentSpan: parent);
  }

  /// Sync counterpart of [span] for first-frame-blocking startup work.
  static T spanSync<T>(
    String name,
    T Function() work, {
    String op = 'app.init',
  }) {
    final parent = _extendedParent();
    if (parent == null) {
      return work();
    }
    return Sentry.startSpanSync(name, (span) {
      span.setAttribute('sentry.op', SentryAttribute.string(op));
      return work();
    }, parentSpan: parent);
  }

  static SentrySpanV2? _extendedParent() =>
      SentryFlutter.getExtendedAppStartSpanV2();

  /// Signals that the first catalog fetch finished (success or failure).
  static void markCatalogReady() {
    if (!_catalogReady.isCompleted) {
      _catalogReady.complete();
    }
  }

  static Future<void> _hydrateFeatureFlags() async {
    final loaded = await Future.wait([
      for (var i = 1; i <= _featureFlagCount; i++)
        rootBundle.loadString('assets/config/feature_$i.json'),
    ]);
    var enabled = 0;
    for (final raw in loaded) {
      final decoded = jsonDecode(raw);
      if (decoded is Map && decoded['enabled'] == true) {
        enabled++;
      }
    }
    Sentry.configureScope((scope) {
      scope.setContexts('feature_flags', {
        'count': loaded.length,
        'enabled': enabled,
      });
    });
  }
}

