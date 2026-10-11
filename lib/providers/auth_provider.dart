import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../database/database_helper.dart';

/// State management login (Provider) sesuai ketentuan teknologi:
/// Flutter + Provider + HTTP(Dio) + SharedPreferences/SecureStorage.
///
/// Strategi: API-first, SQLite-fallback (offline).
/// Jika Laravel tidak terjangkau, otomatis fallback ke SQLite lokal agar aplikasi tetap jalan.
class AuthProvider extends ChangeNotifier {
  Map<String, dynamic>? user;
  bool isLoading = false;
  bool useOfflineMode = false;

  String? get role => user?['role']?.toString();
  int get idRef => (user?['id_ref'] as num?)?.toInt() ?? (user?['idRef'] as num?)?.toInt() ?? 0;

  Future<bool> login(String username, String password) async {
    isLoading = true;
    useOfflineMode = false;
    notifyListeners();
    try {
      final body = await ApiService.instance.login(username, password);
      if (body['success'] == true) {
        user = Map<String, dynamic>.from(body['data'] as Map);
        debugPrint('SIBENMO login: SUKSES via API (${user?['username']})');
        return true;
      }
      throw Exception(body['message']?.toString() ?? 'Login gagal');
    } catch (e) {
      // Fallback offline HANYA bila server tidak terjangkau (koneksi/timeout).
      // Error HTTP lain (401/422/500) harus diteruskan agar tidak terjadi
      // login "offline" yang tidak punya token -> data 401.
      debugPrint('SIBENMO login: gagal ($e)');
      if (!_isConnectionError(e)) rethrow;
      final local =
          await DatabaseHelper.instance.authenticate(username, password);
      if (local != null) {
        user = {
          'username': local['username'],
          'role': local['role'],
          'id_ref': local['id_ref'],
          'idRef': local['id_ref'],
        };
        useOfflineMode = true;
        debugPrint('SIBENMO login: fallback OFFLINE (SQLite lokal)');
        return true;
      }
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  bool _isConnectionError(Object e) {
    if (e is DioException) {
      return e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout;
    }
    return false;
  }

  Future<void> register({
    required String nama,
    required String noHp,
    String? alamat,
    required String username,
    required String password,
  }) async {
    isLoading = true;
    notifyListeners();
    try {
      final body = await ApiService.instance.register(
        nama: nama,
        noHp: noHp,
        alamat: alamat,
        username: username,
        password: password,
        passwordConfirmation: password,
      );
      if (body['success'] != true) {
        throw Exception(body['message']?.toString() ?? 'Registrasi gagal');
      }
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    try {
      await ApiService.instance.logout();
    } catch (e) {
      debugPrint('Logout API call failed (ignored): $e');
    }
    user = null;
    notifyListeners();
  }
}
