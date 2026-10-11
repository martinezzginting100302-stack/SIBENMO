import '../utils/api_parsers.dart';

class JasaServis {
  final int? idJasa;
  final String namaJasa;
  final double harga;

  JasaServis({this.idJasa, required this.namaJasa, required this.harga});

  Map<String, dynamic> toMap() => {
    if (idJasa != null) 'id_jasa': idJasa,
    'nama_jasa': namaJasa,
    'harga': harga,
  };

  factory JasaServis.fromMap(Map<String, dynamic> map) => JasaServis(
    idJasa: parseInt(map['id_jasa']),
    namaJasa: parseString(map['nama_jasa']) ?? '',
    harga: parseDoubleN(map['harga']),
  );

  factory JasaServis.fromJson(Map<String, dynamic> json) => JasaServis.fromMap(json);

  JasaServis copyWith({int? idJasa, String? namaJasa, double? harga}) => JasaServis(
    idJasa: idJasa ?? this.idJasa,
    namaJasa: namaJasa ?? this.namaJasa,
    harga: harga ?? this.harga,
  );
}
