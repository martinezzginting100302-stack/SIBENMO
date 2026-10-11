import '../utils/api_parsers.dart';

class DetailServis {
  final int? idDetailServis;
  final int idServis;
  final int idJasa;
  final double harga;

  DetailServis({this.idDetailServis, required this.idServis, required this.idJasa, required this.harga});

  Map<String, dynamic> toMap() => {
    if (idDetailServis != null) 'id_detail_servis': idDetailServis,
    'id_servis': idServis,
    'id_jasa': idJasa,
    'harga': harga,
  };

  factory DetailServis.fromMap(Map<String, dynamic> map) => DetailServis(
    idDetailServis: parseInt(map['id_detail_servis']),
    idServis: parseIntN(map['id_servis']),
    idJasa: parseIntN(map['id_jasa']),
    harga: parseDoubleN(map['harga']),
  );

  factory DetailServis.fromJson(Map<String, dynamic> json) => DetailServis.fromMap(json);
}
