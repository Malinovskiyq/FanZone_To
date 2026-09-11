import 'package:flutter/foundation.dart';

class AppConfig {
  static const String clubName = 'ХК Сибирь';
  static const String clubCity = 'Новосибирск';
  static const String clubShortName = 'Сибирь';

  // Base URL logic:
  // Android emulator uses 10.0.2.2 to access host PC localhost.
  // Windows desktop / Web / iOS simulator uses localhost.
  static String get defaultBaseHost {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return '10.0.2.2:3000';
    }
    return 'localhost:3000';
  }

  static String customHost = '';

  static String get apiBaseUrl {
    final host = customHost.isNotEmpty ? customHost : defaultBaseHost;
    return 'http://$host/api/v1';
  }

  static String get uploadsBaseUrl {
    final host = customHost.isNotEmpty ? customHost : defaultBaseHost;
    return 'http://$host';
  }
}
