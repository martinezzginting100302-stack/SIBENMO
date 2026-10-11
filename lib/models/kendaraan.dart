import '../utils/api_parsers.dart';

class Kendaraan {
  final int? idKendaraan;
  final int idPelanggan;
  final String noPolisi;
  final String merk;
  final String? tipe;
  final int? tahun;

  Kendaraan({this.idKendaraan, required this.idPelanggan, required this.noPolisi, required this.merk, this.tipe, this.tahun});

  Map<String, dynamic> toMap() => {
    if (idKendaraan != null) 'id_kendaraan': idKendaraan,
    'id_pelanggan': idPelanggan,
    'no_polisi': noPolisi,
    'merk': merk,
    if (tipe != null) 'tipe': tipe,
    if (tahun != null) 'tahun': tahun,
  };

  factory Kendaraan.fromMap(Map<String, dynamic> map) => Kendaraan(
    idKendaraan: parseInt(map['id_kendaraan']),
    idPelanggan: parseIntN(map['id_pelanggan']),
    noPolisi: parseString(map['no_polisi']) ?? '',
    merk: parseString(map['merk']) ?? '',
    tipe: parseString(map['tipe']),
    tahun: parseInt(map['tahun']),
  );

  factory Kendaraan.fromJson(Map<String, dynamic> json) => Kendaraan.fromMap(json);

  Kendaraan copyWith({int? idKendaraan, int? idPelanggan, String? noPolisi, String? merk, String? tipe, int? tahun}) => Kendaraan(
    idKendaraan: idKendaraan ?? this.idKendaraan,
    idPelanggan: idPelanggan ?? this.idPelanggan,
    noPolisi: noPolisi ?? this.noPolisi,
    merk: merk ?? this.merk,
    tipe: tipe ?? this.tipe,
    tahun: tahun ?? this.tahun,
  );
}
