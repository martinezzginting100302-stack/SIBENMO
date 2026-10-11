import 'package:dio/dio.dart';

import '../database/database_helper.dart';
import '../models/detail_servis.dart';
import '../models/detail_sparepart.dart';
import '../models/jasa_servis.dart';
import '../models/kendaraan.dart';
import '../models/mekanik.dart';
import '../models/pelanggan.dart';
import '../models/pembayaran.dart';
import '../models/servis.dart';
import '../models/sparepart.dart';
import 'api_service.dart';

/// Lapisan data pusat SIBENMO — pengganti [DatabaseHelper] untuk seluruh layar.
///
/// Arsitektur sesuai diagram: **Flutter --HTTP(S) JSON--> Laravel API --SQL--> MySQL**.
/// Strategi: **API-first, SQLite-fallback (offline)**. Jika server Laravel tidak
/// terjangkau (koneksi error/timeout), otomatis memakai SQLite lokal agar aplikasi
/// tetap berjalan. Method dan signature disamakan dengan [DatabaseHelper] sehingga
/// migrasi layar bersifat mekanis (ganti import + instance).
///
/// Contoh migrasi layar:
/// ```dart
/// // sebelum:
/// import '../../database/database_helper.dart';
/// final DatabaseHelper _db = DatabaseHelper.instance;
/// // sesudah:
/// import '../../services/sibenmo_repository.dart';
/// final SibenmoRepository _db = SibenmoRepository.instance;
/// ```
///
/// Untuk query mentah (`db.rawQuery` / `db.query` langsung) gunakan method
/// tingkat-tinggi di bawah (mis. `getPelangganById`, `getServisByMekanik`).
class SibenmoRepository {
  SibenmoRepository._();
  static final SibenmoRepository instance = SibenmoRepository._();

  final ApiService _api = ApiService.instance;
  final DatabaseHelper _local = DatabaseHelper.instance;

  bool get _online => true;

  bool _isConnectionError(Object e) {
    if (e is DioException) {
      return e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout;
    }
    return false;
  }

  Future<T> _remoteOrLocal<T>(
    Future<T> Function() remote,
    Future<T> Function() local,
  ) async {
    try {
      return await remote();
    } catch (e) {
      if (_isConnectionError(e)) return await local();
      rethrow;
    }
  }

  // ===================== GENERIC (ganti _db.query/insert/update/delete) =====================

  static const Map<String, String> _listEndpoints = {
    'pelanggan': '/pelanggan',
    'kendaraan': '/kendaraan',
    'mekanik': '/mekanik',
    'jasa_servis': '/jasa',
    'sparepart': '/sparepart',
    'servis': '/servis',
    'pembayaran': '/pembayaran',
  };

  static const Map<String, String> _idColumns = {
    'pelanggan': 'id_pelanggan',
    'kendaraan': 'id_kendaraan',
    'mekanik': 'id_mekanik',
    'jasa_servis': 'id_jasa',
    'sparepart': 'id_sparepart',
    'servis': 'id_servis',
    'pembayaran': 'id_pembayaran',
  };

  Future<List<Map<String, dynamic>>> query(
    String table, {
    String? where,
    List<dynamic>? whereArgs,
    String? orderBy,
  }) async {
    final endpoint = _listEndpoints[table];
    // Filter kompleks / tabel detail -> SQLite lokal.
    if (endpoint == null || where != null) {
      return _local.query(table, where: where, whereArgs: whereArgs, orderBy: orderBy);
    }
    return _remoteOrLocal(
      () async {
        final list = await _api.getList(endpoint);
        return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      },
      () => _local.query(table, orderBy: orderBy),
    );
  }

  Future<List<Map<String, dynamic>>> rawQuery(String sql, [List<dynamic>? args]) {
    // Query mentah hanya didukung offline; layar harus memakai method tingkat-tinggi.
    return _local.rawQuery(sql, args);
  }

  Future<int> insert(String table, Map<String, dynamic> data) async {
    final endpoint = _listEndpoints[table];
    if (endpoint == null) return _local.insert(table, data);
    final payload = Map<String, dynamic>.from(data)..removeWhere((k, _) => k == _idColumns[table]);
    return _remoteOrLocal(
      () async {
        final body = await _api.post(endpoint, payload);
        final d = body['data'];
        if (d is Map) {
          final id = d[_idColumns[table]] ?? d['id'];
          if (id is int) return id;
          if (id is String) return int.tryParse(id) ?? 0;
        }
        return 0;
      },
      () => _local.insert(table, data),
    );
  }

  Future<int> update(String table, Map<String, dynamic> data, String idColumn, int id) async {
    final endpoint = _listEndpoints[table];
    if (endpoint == null) return _local.update(table, data, idColumn, id);
    final payload = Map<String, dynamic>.from(data)..remove(idColumn);
    return _remoteOrLocal(
      () async {
        await _api.put('$endpoint/$id', payload);
        return 1;
      },
      () => _local.update(table, data, idColumn, id),
    );
  }

  Future<int> delete(String table, String idColumn, int id) async {
    final endpoint = _listEndpoints[table];
    if (endpoint == null) return _local.delete(table, idColumn, id);
    return _remoteOrLocal(
      () async {
        await _api.delete('$endpoint/$id');
        return 1;
      },
      () => _local.delete(table, idColumn, id),
    );
  }

  // ===================== USERS / AUTH =====================

  Future<Map<String, dynamic>?> authenticate(String username, String password) async {
    try {
      final body = await _api.login(username, password);
      final d = Map<String, dynamic>.from(body['data'] as Map);
      return {'username': d['username'], 'role': d['role'], 'id_ref': d['id_ref']};
    } catch (e) {
      if (_isConnectionError(e)) return _local.authenticate(username, password);
      // Kredensial salah (401) -> jangan fallback, teruskan pesan.
      if (e is DioException && e.response?.statusCode == 401) return null;
      return _local.authenticate(username, password);
    }
  }

  Future<int> registerUser(String username, String password, String role, int? idRef) {
    // Pendaftaran akun publik lewat POST /api/register (AuthProvider).
    // Method ini hanya untuk fallback offline / akun dibuat admin.
    return _local.registerUser(username, password, role, idRef);
  }

  // ===================== PELANGGAN =====================

  Future<int> insertPelanggan(Pelanggan p) => insert('pelanggan', p.toMap());

  Future<List<Pelanggan>> getAllPelanggan() async {
    final maps = await query('pelanggan', orderBy: 'nama ASC');
    return maps.map(Pelanggan.fromMap).toList();
  }

  Future<Pelanggan?> getPelangganById(int id) async {
    return _remoteOrLocal(
      () async {
        final body = await _api.getDetail('/pelanggan/$id');
        return Pelanggan.fromMap(Map<String, dynamic>.from(body['data'] as Map));
      },
      () => _local.getPelangganById(id),
    );
  }

  Future<int> updatePelanggan(Pelanggan p) => update('pelanggan', p.toMap(), 'id_pelanggan', p.idPelanggan!);

  Future<int> deletePelanggan(int id) => delete('pelanggan', 'id_pelanggan', id);

  // ===================== KENDARAAN =====================

  Future<int> insertKendaraan(Kendaraan k) => insert('kendaraan', k.toMap());

  Future<List<Kendaraan>> getAllKendaraan() async {
    final maps = await query('kendaraan', orderBy: 'no_polisi ASC');
    return maps.map(Kendaraan.fromMap).toList();
  }

  Future<Kendaraan?> getKendaraanById(int id) async {
    return _remoteOrLocal(
      () async {
        final body = await _api.getDetail('/kendaraan/$id');
        return Kendaraan.fromMap(Map<String, dynamic>.from(body['data'] as Map));
      },
      () => _local.getKendaraanById(id),
    );
  }

  Future<int> updateKendaraan(Kendaraan k) => update('kendaraan', k.toMap(), 'id_kendaraan', k.idKendaraan!);

  Future<int> deleteKendaraan(int id) => delete('kendaraan', 'id_kendaraan', id);

  Future<List<Kendaraan>> getKendaraanByPelanggan(int idPelanggan) async {
    return _remoteOrLocal(
      () async {
        final list = await _api.getList('/kendaraan', {'id_pelanggan': idPelanggan});
        return list.map((e) => Kendaraan.fromMap(Map<String, dynamic>.from(e as Map))).toList();
      },
      () => _local.getKendaraanByPelanggan(idPelanggan),
    );
  }

  // ===================== MEKANIK =====================

  Future<int> insertMekanik(Mekanik m) => insert('mekanik', m.toMap());

  Future<List<Mekanik>> getAllMekanik() async {
    final maps = await query('mekanik', orderBy: 'nama ASC');
    return maps.map(Mekanik.fromMap).toList();
  }

  Future<Mekanik?> getMekanikById(int id) async {
    return _remoteOrLocal(
      () async {
        final body = await _api.getDetail('/mekanik/$id');
        return Mekanik.fromMap(Map<String, dynamic>.from(body['data'] as Map));
      },
      () => _local.getMekanikById(id),
    );
  }

  Future<int> updateMekanik(Mekanik m) => update('mekanik', m.toMap(), 'id_mekanik', m.idMekanik!);

  Future<int> deleteMekanik(int id) => delete('mekanik', 'id_mekanik', id);

  // ===================== JASA SERVIS =====================

  Future<int> insertJasaServis(JasaServis j) => insert('jasa_servis', j.toMap());

  Future<List<JasaServis>> getAllJasaServis() async {
    final maps = await query('jasa_servis', orderBy: 'nama_jasa ASC');
    return maps.map(JasaServis.fromMap).toList();
  }

  Future<JasaServis?> getJasaServisById(int id) => _local.getJasaServisById(id);

  Future<int> updateJasaServis(JasaServis j) => update('jasa_servis', j.toMap(), 'id_jasa', j.idJasa!);

  Future<int> deleteJasaServis(int id) => delete('jasa_servis', 'id_jasa', id);

  // ===================== SPAREPART =====================

  Future<int> insertSparepart(Sparepart s) => insert('sparepart', s.toMap());

  Future<List<Sparepart>> getAllSparepart() async {
    final maps = await query('sparepart', orderBy: 'nama_sparepart ASC');
    return maps.map(Sparepart.fromMap).toList();
  }

  Future<Sparepart?> getSparepartById(int id) => _local.getSparepartById(id);

  Future<int> updateSparepart(Sparepart s) => update('sparepart', s.toMap(), 'id_sparepart', s.idSparepart!);

  Future<int> deleteSparepart(int id) => delete('sparepart', 'id_sparepart', id);

  Future<void> updateStokSparepart(int idSparepart, int delta) async {
    try {
      final body = await _api.getDetail('/sparepart/$idSparepart');
      final current = Map<String, dynamic>.from(body['data'] as Map);
      final stok = (current['stok'] is num)
          ? (current['stok'] as num).toInt()
          : int.tryParse(current['stok'].toString()) ?? 0;
      await _api.put('/sparepart/$idSparepart', {'stok': stok + delta});
    } catch (e) {
      if (_isConnectionError(e)) {
        await _local.updateStokSparepart(idSparepart, delta);
        return;
      }
      rethrow;
    }
  }

  // ===================== SERVIS =====================

  Future<int> insertServis(Servis s) => insert('servis', s.toMap());

  Future<List<Servis>> getAllServis() async {
    final maps = await query('servis', orderBy: 'tanggal DESC');
    return maps.map(Servis.fromMap).toList();
  }

  Future<Servis?> getServisById(int id) async {
    return _remoteOrLocal(
      () async {
        final body = await _api.getDetail('/servis/$id');
        return Servis.fromMap(Map<String, dynamic>.from(body['data'] as Map));
      },
      () => _local.getServisById(id),
    );
  }

  Future<int> updateServis(Servis s) => update('servis', s.toMap(), 'id_servis', s.idServis!);

  Future<int> deleteServis(int id) => delete('servis', 'id_servis', id);

  Future<List<Servis>> getServisByPelanggan(int idPelanggan) async {
    return _remoteOrLocal(
      () async {
        final list = await _api.getList('/servis', {'id_pelanggan': idPelanggan});
        return list.map((e) => Servis.fromMap(Map<String, dynamic>.from(e as Map))).toList();
      },
      () => _local.getServisByPelanggan(idPelanggan),
    );
  }

  Future<List<Servis>> getServisByMekanik(int idMekanik) async {
    return _remoteOrLocal(
      () async {
        final list = await _api.getList('/servis', {'id_mekanik': idMekanik});
        return list.map((e) => Servis.fromMap(Map<String, dynamic>.from(e as Map))).toList();
      },
      () => _local.getServisByMekanik(idMekanik),
    );
  }

  // ===================== DETAIL SERVIS / SPAREPART =====================

  Future<int> insertDetailServis(DetailServis d) async {
    return _remoteOrLocal(
      () async {
        final body = await _api.post('/servis/${d.idServis}/jasa', {
          'id_jasa': d.idJasa,
          'harga': d.harga,
        });
        final data = body['data'];
        if (data is Map && data['id_detail_servis'] is int) {
          return data['id_detail_servis'] as int;
        }
        return 0;
      },
      () => _local.insertDetailServis(d),
    );
  }

  Future<List<DetailServis>> getAllDetailServis() => _local.getAllDetailServis();
  Future<DetailServis?> getDetailServisById(int id) => _local.getDetailServisById(id);
  Future<int> updateDetailServis(DetailServis d) => _local.updateDetailServis(d);

  Future<int> deleteDetailServis(int id) {
    return _remoteOrLocal(
      () async {
        await _api.delete('/detail-servis/$id');
        return 1;
      },
      () => _local.deleteDetailServis(id),
    );
  }

  /// Map berisi: id_detail_servis, id_servis, id_jasa, harga, nama_jasa.
  Future<List<Map<String, dynamic>>> getDetailServisByServis(int idServis) async {
    try {
      final body = await _api.getDetail('/servis/$idServis');
      final data = Map<String, dynamic>.from(body['data'] as Map);
      final details = (data['detail_servis'] as List?) ?? [];
      return details.map((e) {
        final m = Map<String, dynamic>.from(e as Map);
        final jasa = m['jasa'];
        return {
          'id_detail_servis': m['id_detail_servis'],
          'id_servis': m['id_servis'] ?? idServis,
          'id_jasa': m['id_jasa'],
          'harga': m['harga'],
          'nama_jasa': jasa is Map ? jasa['nama_jasa'] : null,
        };
      }).toList();
    } catch (e) {
      if (_isConnectionError(e)) return _local.getDetailServisByServis(idServis);
      rethrow;
    }
  }

  Future<int> insertDetailSparepart(DetailSparepart d) async {
    return _remoteOrLocal(
      () async {
        final body = await _api.post('/servis/${d.idServis}/sparepart', {
          'id_sparepart': d.idSparepart,
          'jumlah': d.jumlah,
          'harga': d.harga,
        });
        final data = body['data'];
        if (data is Map && data['id_detail_sparepart'] is int) {
          return data['id_detail_sparepart'] as int;
        }
        return 0;
      },
      () => _local.insertDetailSparepart(d),
    );
  }

  Future<List<DetailSparepart>> getAllDetailSparepart() => _local.getAllDetailSparepart();
  Future<DetailSparepart?> getDetailSparepartById(int id) => _local.getDetailSparepartById(id);
  Future<int> updateDetailSparepart(DetailSparepart d) => _local.updateDetailSparepart(d);

  Future<int> deleteDetailSparepart(int id) {
    return _remoteOrLocal(
      () async {
        await _api.delete('/detail-sparepart/$id');
        return 1;
      },
      () => _local.deleteDetailSparepart(id),
    );
  }

  /// Map berisi: id_detail_sparepart, id_servis, id_sparepart, jumlah, harga, nama_sparepart.
  Future<List<Map<String, dynamic>>> getDetailSparepartByServis(int idServis) async {
    try {
      final body = await _api.getDetail('/servis/$idServis');
      final data = Map<String, dynamic>.from(body['data'] as Map);
      final details = (data['detail_sparepart'] as List?) ?? [];
      return details.map((e) {
        final m = Map<String, dynamic>.from(e as Map);
        final sp = m['sparepart'];
        return {
          'id_detail_sparepart': m['id_detail_sparepart'],
          'id_servis': m['id_servis'] ?? idServis,
          'id_sparepart': m['id_sparepart'],
          'jumlah': m['jumlah'],
          'harga': m['harga'],
          'nama_sparepart': sp is Map ? sp['nama_sparepart'] : null,
        };
      }).toList();
    } catch (e) {
      if (_isConnectionError(e)) return _local.getDetailSparepartByServis(idServis);
      rethrow;
    }
  }

  // ===================== PEMBAYARAN =====================

  Future<int> insertPembayaran(Pembayaran p) async {
    return _remoteOrLocal(
      () async {
        final body = await _api.post('/servis/${p.idServis}/bayar', {
          'total_bayar': p.totalBayar,
          'metode_pembayaran': p.metodePembayaran,
          'tanggal': p.tanggal.toIso8601String().substring(0, 10),
        });
        final data = body['data'];
        if (data is Map && data['id_pembayaran'] is int) {
          return data['id_pembayaran'] as int;
        }
        return 0;
      },
      () => _local.insertPembayaran(p),
    );
  }

  Future<List<Pembayaran>> getAllPembayaran() async {
    return _remoteOrLocal(
      () async {
        final list = await _api.getList('/pembayaran');
        return list.map((e) => Pembayaran.fromMap(Map<String, dynamic>.from(e as Map))).toList();
      },
      () => _local.getAllPembayaran(),
    );
  }

  Future<Pembayaran?> getPembayaranById(int id) => _local.getPembayaranById(id);

  Future<Pembayaran?> getPembayaranByServis(int idServis) async {
    try {
      final list = await _api.getList('/pembayaran');
      for (final e in list) {
        final m = Map<String, dynamic>.from(e as Map);
        final sid = m['id_servis'];
        final sidInt = sid is int ? sid : int.tryParse(sid.toString());
        if (sidInt == idServis) return Pembayaran.fromMap(m);
      }
      return null;
    } catch (e) {
      if (_isConnectionError(e)) return _local.getPembayaranByServis(idServis);
      rethrow;
    }
  }

  Future<int> updatePembayaran(Pembayaran p) {
    return _remoteOrLocal(
      () async {
        await _api.put('/pembayaran/${p.idPembayaran}', p.toMap());
        return 1;
      },
      () => _local.updatePembayaran(p),
    );
  }

  Future<int> deletePembayaran(int id) {
    return _remoteOrLocal(
      () async {
        await _api.delete('/pembayaran/$id');
        return 1;
      },
      () => _local.deletePembayaran(id),
    );
  }

  // ===================== SPECIAL QUERIES =====================

  /// Bentuk flat sama seperti SQLite: kolom servis + no_polisi, merk, tipe,
  /// tahun, nama_pelanggan, no_hp, alamat, nama_mekanik.
  Future<Map<String, dynamic>?> getServisWithDetails(int idServis) async {
    try {
      final body = await _api.getDetail('/servis/$idServis');
      final d = Map<String, dynamic>.from(body['data'] as Map);
      final kendaraan = d['kendaraan'] is Map ? Map<String, dynamic>.from(d['kendaraan']) : <String, dynamic>{};
      final pelanggan = kendaraan['pelanggan'] is Map
          ? Map<String, dynamic>.from(kendaraan['pelanggan'])
          : <String, dynamic>{};
      final mekanik = d['mekanik'] is Map ? Map<String, dynamic>.from(d['mekanik']) : <String, dynamic>{};
      return {
        ...d,
        'no_polisi': kendaraan['no_polisi'],
        'merk': kendaraan['merk'],
        'tipe': kendaraan['tipe'],
        'tahun': kendaraan['tahun'],
        'nama_pelanggan': pelanggan['nama'],
        'no_hp': pelanggan['no_hp'],
        'alamat': pelanggan['alamat'],
        'nama_mekanik': mekanik['nama'],
      };
    } catch (e) {
      if (_isConnectionError(e)) return _local.getServisWithDetails(idServis);
      rethrow;
    }
  }

  Future<double> getTotalBiayaServis(int idServis) async {
    try {
      final body = await _api.getDetail('/servis/$idServis');
      final d = Map<String, dynamic>.from(body['data'] as Map);
      final total = d['total_biaya'];
      if (total is num) return total.toDouble();
      return double.tryParse(total.toString()) ?? 0;
    } catch (e) {
      if (_isConnectionError(e)) return _local.getTotalBiayaServis(idServis);
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getLaporanServis(DateTime start, DateTime end) async {
    String fmt(DateTime d) => d.toIso8601String().substring(0, 10);
    try {
      final list = await _api.getList('/laporan', {'start': fmt(start), 'end': fmt(end)});
      return list.map((e) {
        final m = Map<String, dynamic>.from(e as Map);
        return {
          'id_servis': m['id_servis'],
          'tanggal': (m['tanggal'] is Map ? m['tanggal']['date'] : m['tanggal'])?.toString() ?? '',
          'status': m['status'],
          'no_polisi': m['no_polisi'],
          'merk': m['merk'],
          'nama_pelanggan': m['nama_pelanggan'],
          'nama_mekanik': m['nama_mekanik'],
          'total_jasa': 0,
          'total_sparepart': 0,
          'total_biaya': m['total_biaya'] ?? 0,
        };
      }).toList();
    } catch (e) {
      if (_isConnectionError(e)) return _local.getLaporanServis(start, end);
      rethrow;
    }
  }

  /// Ringkasan global untuk efek samping kompatibilitas.
  bool get isOnlineCapable => _online;
}
