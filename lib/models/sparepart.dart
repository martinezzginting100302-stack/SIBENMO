import '../utils/api_parsers.dart';

class Sparepart {
  final int? idSparepart;
  final String namaSparepart;
  final double harga;
  final int stok;

  Sparepart({this.idSparepart, required this.namaSparepart, required this.harga, required this.stok});

  Map<String, dynamic> toMap() => {
    if (idSparepart != null) 'id_sparepart': idSparepart,
    'nama_sparepart': namaSparepart,
    'harga': harga,
    'stok': stok,
  };

  factory Sparepart.fromMap(Map<String, dynamic> map) => Sparepart(
    idSparepart: parseInt(map['id_sparepart']),
    namaSparepart: parseString(map['nama_sparepart']) ?? '',
    harga: parseDoubleN(map['harga']),
    stok: parseIntN(map['stok']),
  );

  factory Sparepart.fromJson(Map<String, dynamic> json) => Sparepart.fromMap(json);

  Sparepart copyWith({int? idSparepart, String? namaSparepart, double? harga, int? stok}) => Sparepart(
    idSparepart: idSparepart ?? this.idSparepart,
    namaSparepart: namaSparepart ?? this.namaSparepart,
    harga: harga ?? this.harga,
    stok: stok ?? this.stok,
  );
}
