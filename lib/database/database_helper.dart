import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/pelanggan.dart';
import '../models/kendaraan.dart';
import '../models/mekanik.dart';
import '../models/jasa_servis.dart';
import '../models/sparepart.dart';
import '../models/servis.dart';
import '../models/detail_servis.dart';
import '../models/detail_sparepart.dart';
import '../models/pembayaran.dart';

class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final String path = join(await getDatabasesPath(), 'sibenmo.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL,
        role TEXT NOT NULL,
        id_ref INTEGER,
        created_at TEXT DEFAULT (datetime('now','localtime'))
      )
    ''');

    await db.execute('''
      CREATE TABLE pelanggan (
        id_pelanggan INTEGER PRIMARY KEY AUTOINCREMENT,
        nama TEXT NOT NULL,
        no_hp TEXT NOT NULL,
        alamat TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE kendaraan (
        id_kendaraan INTEGER PRIMARY KEY AUTOINCREMENT,
        id_pelanggan INTEGER NOT NULL,
        no_polisi TEXT NOT NULL,
        merk TEXT NOT NULL,
        tipe TEXT,
        tahun INTEGER,
        FOREIGN KEY (id_pelanggan) REFERENCES pelanggan(id_pelanggan) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE mekanik (
        id_mekanik INTEGER PRIMARY KEY AUTOINCREMENT,
        nama TEXT NOT NULL,
        no_hp TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE jasa_servis (
        id_jasa INTEGER PRIMARY KEY AUTOINCREMENT,
        nama_jasa TEXT NOT NULL,
        harga REAL NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE sparepart (
        id_sparepart INTEGER PRIMARY KEY AUTOINCREMENT,
        nama_sparepart TEXT NOT NULL,
        harga REAL NOT NULL,
        stok INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE servis (
        id_servis INTEGER PRIMARY KEY AUTOINCREMENT,
        id_kendaraan INTEGER NOT NULL,
        id_mekanik INTEGER NOT NULL,
        tanggal TEXT NOT NULL,
        keluhan TEXT,
        status TEXT NOT NULL DEFAULT 'menunggu',
        FOREIGN KEY (id_kendaraan) REFERENCES kendaraan(id_kendaraan) ON DELETE CASCADE,
        FOREIGN KEY (id_mekanik) REFERENCES mekanik(id_mekanik) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE detail_servis (
        id_detail_servis INTEGER PRIMARY KEY AUTOINCREMENT,
        id_servis INTEGER NOT NULL,
        id_jasa INTEGER NOT NULL,
        harga REAL NOT NULL,
        FOREIGN KEY (id_servis) REFERENCES servis(id_servis) ON DELETE CASCADE,
        FOREIGN KEY (id_jasa) REFERENCES jasa_servis(id_jasa) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE detail_sparepart (
        id_detail_sparepart INTEGER PRIMARY KEY AUTOINCREMENT,
        id_servis INTEGER NOT NULL,
        id_sparepart INTEGER NOT NULL,
        jumlah INTEGER NOT NULL,
        harga REAL NOT NULL,
        FOREIGN KEY (id_servis) REFERENCES servis(id_servis) ON DELETE CASCADE,
        FOREIGN KEY (id_sparepart) REFERENCES sparepart(id_sparepart) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE pembayaran (
        id_pembayaran INTEGER PRIMARY KEY AUTOINCREMENT,
        id_servis INTEGER NOT NULL,
        tanggal TEXT NOT NULL,
        total_bayar REAL NOT NULL,
        metode_pembayaran TEXT NOT NULL,
        FOREIGN KEY (id_servis) REFERENCES servis(id_servis) ON DELETE CASCADE
      )
    ''');

    await db.insert('users', {
      'username': 'admin',
      'password': 'admin123',
      'role': 'admin',
    });
  }

  // ===================== GENERIC METHODS =====================

  Future<List<Map<String, dynamic>>> query(String table, {String? where, List<dynamic>? whereArgs, String? orderBy}) async {
    final Database db = await database;
    return await db.query(table, where: where, whereArgs: whereArgs, orderBy: orderBy);
  }

  Future<List<Map<String, dynamic>>> rawQuery(String sql, [List<dynamic>? args]) async {
    final Database db = await database;
    return await db.rawQuery(sql, args);
  }

  Future<int> insert(String table, Map<String, dynamic> data) async {
    final Database db = await database;
    return await db.insert(table, data);
  }

  Future<int> update(String table, Map<String, dynamic> data, String idColumn, int id) async {
    final Database db = await database;
    return await db.update(table, data, where: '$idColumn = ?', whereArgs: [id]);
  }

  Future<int> delete(String table, String idColumn, int id) async {
    final Database db = await database;
    return await db.delete(table, where: '$idColumn = ?', whereArgs: [id]);
  }

  // ===================== USERS =====================

  Future<Map<String, dynamic>?> authenticate(String username, String password) async {
    final Database db = await database;
    final List<Map<String, dynamic>> results = await db.query(
      'users',
      where: 'username = ? AND password = ?',
      whereArgs: [username, password],
    );
    if (results.isEmpty) return null;
    return results.first;
  }

  Future<int> registerUser(String username, String password, String role, int? idRef) async {
    final Database db = await database;
    return await db.insert('users', {
      'username': username,
      'password': password,
      'role': role,
      'id_ref': idRef,
    });
  }

  // ===================== PELANGGAN =====================

  Future<int> insertPelanggan(Pelanggan pelanggan) async {
    final Database db = await database;
    return await db.insert('pelanggan', pelanggan.toMap());
  }

  Future<List<Pelanggan>> getAllPelanggan() async {
    final Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query('pelanggan', orderBy: 'nama ASC');
    return maps.map((map) => Pelanggan.fromMap(map)).toList();
  }

  Future<Pelanggan?> getPelangganById(int id) async {
    final Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'pelanggan',
      where: 'id_pelanggan = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return Pelanggan.fromMap(maps.first);
  }

  Future<int> updatePelanggan(Pelanggan pelanggan) async {
    final Database db = await database;
    return await db.update(
      'pelanggan',
      pelanggan.toMap(),
      where: 'id_pelanggan = ?',
      whereArgs: [pelanggan.idPelanggan],
    );
  }

  Future<int> deletePelanggan(int id) async {
    final Database db = await database;
    return await db.delete(
      'pelanggan',
      where: 'id_pelanggan = ?',
      whereArgs: [id],
    );
  }

  // ===================== KENDARAAN =====================

  Future<int> insertKendaraan(Kendaraan kendaraan) async {
    final Database db = await database;
    return await db.insert('kendaraan', kendaraan.toMap());
  }

  Future<List<Kendaraan>> getAllKendaraan() async {
    final Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query('kendaraan', orderBy: 'no_polisi ASC');
    return maps.map((map) => Kendaraan.fromMap(map)).toList();
  }

  Future<Kendaraan?> getKendaraanById(int id) async {
    final Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'kendaraan',
      where: 'id_kendaraan = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return Kendaraan.fromMap(maps.first);
  }

  Future<int> updateKendaraan(Kendaraan kendaraan) async {
    final Database db = await database;
    return await db.update(
      'kendaraan',
      kendaraan.toMap(),
      where: 'id_kendaraan = ?',
      whereArgs: [kendaraan.idKendaraan],
    );
  }

  Future<int> deleteKendaraan(int id) async {
    final Database db = await database;
    return await db.delete(
      'kendaraan',
      where: 'id_kendaraan = ?',
      whereArgs: [id],
    );
  }

  Future<List<Kendaraan>> getKendaraanByPelanggan(int idPelanggan) async {
    final Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'kendaraan',
      where: 'id_pelanggan = ?',
      whereArgs: [idPelanggan],
      orderBy: 'no_polisi ASC',
    );
    return maps.map((map) => Kendaraan.fromMap(map)).toList();
  }

  // ===================== MEKANIK =====================

  Future<int> insertMekanik(Mekanik mekanik) async {
    final Database db = await database;
    return await db.insert('mekanik', mekanik.toMap());
  }

  Future<List<Mekanik>> getAllMekanik() async {
    final Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query('mekanik', orderBy: 'nama ASC');
    return maps.map((map) => Mekanik.fromMap(map)).toList();
  }

  Future<Mekanik?> getMekanikById(int id) async {
    final Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'mekanik',
      where: 'id_mekanik = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return Mekanik.fromMap(maps.first);
  }

  Future<int> updateMekanik(Mekanik mekanik) async {
    final Database db = await database;
    return await db.update(
      'mekanik',
      mekanik.toMap(),
      where: 'id_mekanik = ?',
      whereArgs: [mekanik.idMekanik],
    );
  }

  Future<int> deleteMekanik(int id) async {
    final Database db = await database;
    return await db.delete(
      'mekanik',
      where: 'id_mekanik = ?',
      whereArgs: [id],
    );
  }

  // ===================== JASA SERVIS =====================

  Future<int> insertJasaServis(JasaServis jasa) async {
    final Database db = await database;
    return await db.insert('jasa_servis', jasa.toMap());
  }

  Future<List<JasaServis>> getAllJasaServis() async {
    final Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query('jasa_servis', orderBy: 'nama_jasa ASC');
    return maps.map((map) => JasaServis.fromMap(map)).toList();
  }

  Future<JasaServis?> getJasaServisById(int id) async {
    final Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'jasa_servis',
      where: 'id_jasa = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return JasaServis.fromMap(maps.first);
  }

  Future<int> updateJasaServis(JasaServis jasa) async {
    final Database db = await database;
    return await db.update(
      'jasa_servis',
      jasa.toMap(),
      where: 'id_jasa = ?',
      whereArgs: [jasa.idJasa],
    );
  }

  Future<int> deleteJasaServis(int id) async {
    final Database db = await database;
    return await db.delete(
      'jasa_servis',
      where: 'id_jasa = ?',
      whereArgs: [id],
    );
  }

  // ===================== SPAREPART =====================

  Future<int> insertSparepart(Sparepart sparepart) async {
    final Database db = await database;
    return await db.insert('sparepart', sparepart.toMap());
  }

  Future<List<Sparepart>> getAllSparepart() async {
    final Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query('sparepart', orderBy: 'nama_sparepart ASC');
    return maps.map((map) => Sparepart.fromMap(map)).toList();
  }

  Future<Sparepart?> getSparepartById(int id) async {
    final Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'sparepart',
      where: 'id_sparepart = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return Sparepart.fromMap(maps.first);
  }

  Future<int> updateSparepart(Sparepart sparepart) async {
    final Database db = await database;
    return await db.update(
      'sparepart',
      sparepart.toMap(),
      where: 'id_sparepart = ?',
      whereArgs: [sparepart.idSparepart],
    );
  }

  Future<int> deleteSparepart(int id) async {
    final Database db = await database;
    return await db.delete(
      'sparepart',
      where: 'id_sparepart = ?',
      whereArgs: [id],
    );
  }

  Future<void> updateStokSparepart(int idSparepart, int delta) async {
    final Database db = await database;
    await db.rawUpdate(
      'UPDATE sparepart SET stok = stok + ? WHERE id_sparepart = ?',
      [delta, idSparepart],
    );
  }

  // ===================== SERVIS =====================

  Future<int> insertServis(Servis servis) async {
    final Database db = await database;
    return await db.insert('servis', servis.toMap());
  }

  Future<List<Servis>> getAllServis() async {
    final Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query('servis', orderBy: 'tanggal DESC');
    return maps.map((map) => Servis.fromMap(map)).toList();
  }

  Future<Servis?> getServisById(int id) async {
    final Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'servis',
      where: 'id_servis = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return Servis.fromMap(maps.first);
  }

  Future<int> updateServis(Servis servis) async {
    final Database db = await database;
    return await db.update(
      'servis',
      servis.toMap(),
      where: 'id_servis = ?',
      whereArgs: [servis.idServis],
    );
  }

  Future<int> deleteServis(int id) async {
    final Database db = await database;
    return await db.delete(
      'servis',
      where: 'id_servis = ?',
      whereArgs: [id],
    );
  }

  Future<List<Servis>> getServisByPelanggan(int idPelanggan) async {
    final Database db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT s.* FROM servis s
      JOIN kendaraan k ON s.id_kendaraan = k.id_kendaraan
      WHERE k.id_pelanggan = ?
      ORDER BY s.tanggal DESC
    ''', [idPelanggan]);
    return maps.map((map) => Servis.fromMap(map)).toList();
  }

  Future<List<Servis>> getServisByMekanik(int idMekanik) async {
    final Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'servis',
      where: 'id_mekanik = ?',
      whereArgs: [idMekanik],
      orderBy: 'tanggal DESC',
    );
    return maps.map((map) => Servis.fromMap(map)).toList();
  }

  // ===================== DETAIL SERVIS =====================

  Future<int> insertDetailServis(DetailServis detail) async {
    final Database db = await database;
    return await db.insert('detail_servis', detail.toMap());
  }

  Future<List<DetailServis>> getAllDetailServis() async {
    final Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query('detail_servis');
    return maps.map((map) => DetailServis.fromMap(map)).toList();
  }

  Future<DetailServis?> getDetailServisById(int id) async {
    final Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'detail_servis',
      where: 'id_detail_servis = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return DetailServis.fromMap(maps.first);
  }

  Future<int> updateDetailServis(DetailServis detail) async {
    final Database db = await database;
    return await db.update(
      'detail_servis',
      detail.toMap(),
      where: 'id_detail_servis = ?',
      whereArgs: [detail.idDetailServis],
    );
  }

  Future<int> deleteDetailServis(int id) async {
    final Database db = await database;
    return await db.delete(
      'detail_servis',
      where: 'id_detail_servis = ?',
      whereArgs: [id],
    );
  }

  Future<List<Map<String, dynamic>>> getDetailServisByServis(int idServis) async {
    final Database db = await database;
    return await db.rawQuery('''
      SELECT ds.*, js.nama_jasa
      FROM detail_servis ds
      JOIN jasa_servis js ON ds.id_jasa = js.id_jasa
      WHERE ds.id_servis = ?
    ''', [idServis]);
  }

  // ===================== DETAIL SPAREPART =====================

  Future<int> insertDetailSparepart(DetailSparepart detail) async {
    final Database db = await database;
    return await db.insert('detail_sparepart', detail.toMap());
  }

  Future<List<DetailSparepart>> getAllDetailSparepart() async {
    final Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query('detail_sparepart');
    return maps.map((map) => DetailSparepart.fromMap(map)).toList();
  }

  Future<DetailSparepart?> getDetailSparepartById(int id) async {
    final Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'detail_sparepart',
      where: 'id_detail_sparepart = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return DetailSparepart.fromMap(maps.first);
  }

  Future<int> updateDetailSparepart(DetailSparepart detail) async {
    final Database db = await database;
    return await db.update(
      'detail_sparepart',
      detail.toMap(),
      where: 'id_detail_sparepart = ?',
      whereArgs: [detail.idDetailSparepart],
    );
  }

  Future<int> deleteDetailSparepart(int id) async {
    final Database db = await database;
    return await db.delete(
      'detail_sparepart',
      where: 'id_detail_sparepart = ?',
      whereArgs: [id],
    );
  }

  Future<List<Map<String, dynamic>>> getDetailSparepartByServis(int idServis) async {
    final Database db = await database;
    return await db.rawQuery('''
      SELECT dsp.*, sp.nama_sparepart
      FROM detail_sparepart dsp
      JOIN sparepart sp ON dsp.id_sparepart = sp.id_sparepart
      WHERE dsp.id_servis = ?
    ''', [idServis]);
  }

  // ===================== PEMBAYARAN =====================

  Future<int> insertPembayaran(Pembayaran pembayaran) async {
    final Database db = await database;
    return await db.insert('pembayaran', pembayaran.toMap());
  }

  Future<List<Pembayaran>> getAllPembayaran() async {
    final Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query('pembayaran', orderBy: 'tanggal DESC');
    return maps.map((map) => Pembayaran.fromMap(map)).toList();
  }

  Future<Pembayaran?> getPembayaranById(int id) async {
    final Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'pembayaran',
      where: 'id_pembayaran = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return Pembayaran.fromMap(maps.first);
  }

  Future<Pembayaran?> getPembayaranByServis(int idServis) async {
    final Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'pembayaran',
      where: 'id_servis = ?',
      whereArgs: [idServis],
    );
    if (maps.isEmpty) return null;
    return Pembayaran.fromMap(maps.first);
  }

  Future<int> updatePembayaran(Pembayaran pembayaran) async {
    final Database db = await database;
    return await db.update(
      'pembayaran',
      pembayaran.toMap(),
      where: 'id_pembayaran = ?',
      whereArgs: [pembayaran.idPembayaran],
    );
  }

  Future<int> deletePembayaran(int id) async {
    final Database db = await database;
    return await db.delete(
      'pembayaran',
      where: 'id_pembayaran = ?',
      whereArgs: [id],
    );
  }

  // ===================== SPECIAL QUERIES =====================

  Future<Map<String, dynamic>?> getServisWithDetails(int idServis) async {
    final Database db = await database;
    final List<Map<String, dynamic>> results = await db.rawQuery('''
      SELECT 
        s.*,
        k.no_polisi, k.merk, k.tipe, k.tahun,
        p.nama AS nama_pelanggan, p.no_hp, p.alamat,
        m.nama AS nama_mekanik
      FROM servis s
      JOIN kendaraan k ON s.id_kendaraan = k.id_kendaraan
      JOIN pelanggan p ON k.id_pelanggan = p.id_pelanggan
      JOIN mekanik m ON s.id_mekanik = m.id_mekanik
      WHERE s.id_servis = ?
    ''', [idServis]);
    if (results.isEmpty) return null;
    return results.first;
  }

  Future<double> getTotalBiayaServis(int idServis) async {
    final Database db = await database;
    final result = await db.rawQuery('''
      SELECT
        COALESCE((SELECT SUM(harga) FROM detail_servis WHERE id_servis = ?), 0) AS total_jasa,
        COALESCE((SELECT SUM(harga * jumlah) FROM detail_sparepart WHERE id_servis = ?), 0) AS total_sparepart
    ''', [idServis, idServis]);
    if (result.isEmpty) return 0;
    final double totalJasa = (result.first['total_jasa'] as num).toDouble();
    final double totalSparepart = (result.first['total_sparepart'] as num).toDouble();
    return totalJasa + totalSparepart;
  }

  Future<List<Map<String, dynamic>>> getLaporanServis(DateTime start, DateTime end) async {
    final Database db = await database;
    final String startDate = start.toIso8601String().substring(0, 10);
    final String endDate = end.toIso8601String().substring(0, 10);
    return await db.rawQuery('''
      SELECT 
        s.id_servis,
        s.tanggal,
        s.status,
        k.no_polisi,
        k.merk,
        p.nama AS nama_pelanggan,
        m.nama AS nama_mekanik,
        COALESCE((SELECT SUM(harga) FROM detail_servis WHERE id_servis = s.id_servis), 0) AS total_jasa,
        COALESCE((SELECT SUM(harga * jumlah) FROM detail_sparepart WHERE id_servis = s.id_servis), 0) AS total_sparepart,
        (COALESCE((SELECT SUM(harga) FROM detail_servis WHERE id_servis = s.id_servis), 0) 
         + COALESCE((SELECT SUM(harga * jumlah) FROM detail_sparepart WHERE id_servis = s.id_servis), 0)) AS total_biaya
      FROM servis s
      JOIN kendaraan k ON s.id_kendaraan = k.id_kendaraan
      JOIN pelanggan p ON k.id_pelanggan = p.id_pelanggan
      JOIN mekanik m ON s.id_mekanik = m.id_mekanik
      WHERE s.tanggal BETWEEN ? AND ?
      ORDER BY s.tanggal DESC
    ''', [startDate, endDate]);
  }
}
