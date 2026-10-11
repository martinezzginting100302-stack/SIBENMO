import '../utils/api_parsers.dart';

class Pelanggan {
  final int? idPelanggan;
  final String nama;
  final String noHp;
  final String? alamat;

  Pelanggan({this.idPelanggan, required this.nama, required this.noHp, this.alamat});

  Map<String, dynamic> toMap() => {
    if (idPelanggan != null) 'id_pelanggan': idPelanggan,
    'nama': nama,
    'no_hp': noHp,
    if (alamat != null) 'alamat': alamat,
  };

  factory Pelanggan.fromMap(Map<String, dynamic> map) => Pelanggan(
    idPelanggan: parseInt(map['id_pelanggan']),
    nama: parseString(map['nama']) ?? '',
    noHp: parseString(map['no_hp']) ?? '',
    alamat: parseString(map['alamat']),
  );

  factory Pelanggan.fromJson(Map<String, dynamic> json) => Pelanggan.fromMap(json);

  Pelanggan copyWith({int? idPelanggan, String? nama, String? noHp, String? alamat}) => Pelanggan(
    idPelanggan: idPelanggan ?? this.idPelanggan,
    nama: nama ?? this.nama,
    noHp: noHp ?? this.noHp,
    alamat: alamat ?? this.alamat,
  );
}
