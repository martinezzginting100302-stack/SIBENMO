import 'package:flutter/foundation.dart';

/// Konfigurasi base URL Laravel API.
/// Sesuai diagram: Flutter (Mobile) -HTTP(S) JSON-> Laravel (API) -SQL-> MySQL.
///
/// Port mengikuti konvensi seluruh project (README_SIBENMO.md, .env, tampilan web):
/// `php artisan serve --host=0.0.0.0 --port=8001`
/// -> website (Blade) dan mobile memakai server + database MySQL yang sama.
///
/// Host otomatis mengikuti platform:
/// - Emulator Android: `10.0.2.2` (loopback menuju host komputer)
/// - Windows / desktop / Chrome: `127.0.0.1`
/// - HP fisik / device beda mesin (server bind `0.0.0.0`): override lewat
///   `flutter run --dart-define=API_BASE_URL=http://192.168.1.10:8001/api`
class ApiConfig {
  ApiConfig._();

  static const String port = '8001';

  static const String _baseUrlOverride =
      String.fromEnvironment('API_BASE_URL');

  static String get baseUrl => _baseUrlOverride.isNotEmpty
      ? _baseUrlOverride
      : 'http://$host:$port/api';

  /// Host default; hanya dipakai jika [baseUrl] tidak di-override via dart-define.
  static String get host {
    if (defaultTargetPlatform == TargetPlatform.android) return '10.0.2.2';
    return '127.0.0.1';
  }

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);
}
