import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

/// Dio client terpusat untuk komunikasi HTTP(S) JSON ke Laravel.
/// Menyuntikkan token Sanctum otomatis + format respons standar:
/// { "success": true, "message": "...", "data": {...} }
class ApiService {
  ApiService._();
  static final ApiService instance = ApiService._();

  static const _tokenKey = 'sibenmo_token';
  static const _userKey = 'sibenmo_user';

  final FlutterSecureStorage _secure = const FlutterSecureStorage();
  late final Dio dio;

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: ApiConfig.connectTimeout,
        receiveTimeout: ApiConfig.receiveTimeout,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json'
        },
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await getToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await getToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          } else {
            options.headers.remove('Authorization');
          }
          debugPrint('SIBENMO API -> ${options.method} ${options.path} '
              '(token: ${token == null || token.isEmpty ? 'TIDAK ADA' : 'ada'})');
          handler.next(options);
        },
      ),
    );

    _initialized = true;
  }

  // ---------- Token & sesi (Secure Storage + SharedPreferences cache) ----------
  Future<void> saveSession(String token, Map<String, dynamic> user) async {
    try {
      await _secure.write(key: _tokenKey, value: token);
    } catch (e) {
      // Secure storage bisa gagal (keystore emulator/device tertentu).
      // Token tetap disimpan di SharedPreferences agar API tetap terjangkau.
      debugPrint('SIBENMO secure storage write gagal (fallback prefs): $e');
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_userKey, user.toString());
    await prefs.setString('username', user['username']?.toString() ?? '');
    await prefs.setString('role', user['role']?.toString() ?? '');
    await prefs.setInt('id_ref', (user['id_ref'] as num?)?.toInt() ?? 0);
  }

  Future<String?> getToken() async {
    try {
      final t = await _secure.read(key: _tokenKey);
      if (t != null && t.isNotEmpty) return t;
    } catch (e) {
      debugPrint('SIBENMO secure storage read gagal (fallback prefs): $e');
    }
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<void> clearSession() async {
    try {
      await _secure.delete(key: _tokenKey);
    } catch (_) {
      // abaikan
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
  }

  // ---------- Auth ----------
  Future<Map<String, dynamic>> login(String username, String password) async {
    await init();
    final res = await dio
        .post('/login', data: {'username': username, 'password': password});
    final body = res.data as Map<String, dynamic>;
    if (body['success'] == true && body['data']?['token'] != null) {
      await saveSession(body['data']['token'] as String,
          Map<String, dynamic>.from(body['data'] as Map));
    }
    return body;
  }

  Future<Map<String, dynamic>> register({
    required String nama,
    required String noHp,
    String? alamat,
    required String username,
    required String password,
    required String passwordConfirmation,
  }) async {
    await init();
    final res = await dio.post('/register', data: {
      'nama': nama,
      'no_hp': noHp,
      'alamat': alamat,
      'username': username,
      'password': password,
      'password_confirmation': passwordConfirmation,
    });
    final body = res.data as Map<String, dynamic>;
    if (body['success'] == true && body['data']?['token'] != null) {
      await saveSession(body['data']['token'] as String,
          Map<String, dynamic>.from(body['data']['user'] as Map));
    }
    return body;
  }

  Future<void> logout() async {
    await init();
    try {
      await dio.post('/logout');
    } catch (_) {
      // abaikan, tetap hapus sesi lokal
    }
    await clearSession();
  }

  Future<Map<String, dynamic>?> profil() async {
    await init();
    final res = await dio.get('/profil');
    return res.data as Map<String, dynamic>;
  }

  // ---------- Generic CRUD (dipakai semua layar Manage/Laporan) ----------
  Future<List<dynamic>> getList(String path,
      [Map<String, dynamic>? query]) async {
    await init();
    final res = await dio.get(path, queryParameters: query);
    final body = res.data as Map<String, dynamic>;
    return (body['data'] as List?) ?? [];
  }

  Future<Map<String, dynamic>> getDetail(String path) async {
    await init();
    final res = await dio.get(path);
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> post(
      String path, Map<String, dynamic> data) async {
    await init();
    final res = await dio.post(path, data: data);
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> put(
      String path, Map<String, dynamic> data) async {
    await init();
    final res = await dio.put(path, data: data);
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> delete(String path) async {
    await init();
    final res = await dio.delete(path);
    return res.data as Map<String, dynamic>;
  }

  /// Pesan error ramah untuk Snackbar Flutter dari DioException.
  static String friendlyError(Object e) {
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map && data['message'] is String) {
        return data['message'] as String;
      }
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        return 'Koneksi ke server Laravel timeout. Pastikan php artisan serve berjalan.';
      }
      if (e.type == DioExceptionType.connectionError) {
        return 'Tidak dapat terhubung ke API (${ApiConfig.baseUrl}). Cek IP/baseUrl & server Laravel.';
      }
    }
    return e.toString();
  }
}
