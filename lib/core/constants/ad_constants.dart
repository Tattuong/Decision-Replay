import 'package:flutter/foundation.dart';

/// Fill from https://admob.google.com/ → Apps → Add app → Ad units → Banner (Biểu ngữ).
/// Slot stays hidden until [isConfigured].
class AdConstants {
  AdConstants._();

  static const String androidAppId = '';
  static const String iosAppId = '';

  static const String androidBannerId = '';
  static const String iosBannerId = '';

  static const double bannerHeight = 50;

  static const String _samplePublisher = '3940256099942544';

  static bool get _ios => defaultTargetPlatform == TargetPlatform.iOS;

  static String get appId => _ios ? iosAppId : androidAppId;
  static String get bannerAdUnitId => _ios ? iosBannerId : androidBannerId;

  static bool get isConfigured {
    final app = appId.trim();
    final unit = bannerAdUnitId.trim();
    if (app.isEmpty || unit.isEmpty) return false;
    if (app.contains(_samplePublisher) || unit.contains(_samplePublisher)) return false;
    return app.startsWith('ca-app-pub-') &&
        unit.startsWith('ca-app-pub-') &&
        unit.contains('/');
  }
}
