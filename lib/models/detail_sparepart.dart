import '../utils/api_parsers.dart';

class DetailSparepart {
  final int? idDetailSparepart;
  final int idServis;
  final int idSparepart;
  final int jumlah;
  final double harga;

  DetailSparepart({this.idDetailSparepart, required this.idServis, required this.idSparepart, required this.jumlah, required this.harga});

  Map<String, dynamic> toMap() => {
    if (idDetailSparepart != null) 'id_detail_sparepart': idDetailSparepart,
    'id_servis': idServis,
    'id_sparepart': idSparepart,
    'jumlah': jumlah,
    'harga': harga,
  };

  factory DetailSparepart.fromMap(Map<String, dynamic> map) => DetailSparepart(
    idDetailSparepart: parseInt(map['id_detail_sparepart']),
    idServis: parseIntN(map['id_servis']),
    idSparepart: parseIntN(map['id_sparepart']),
    jumlah: parseIntN(map['jumlah']),
    harga: parseDoubleN(map['harga']),
  );

  factory DetailSparepart.fromJson(Map<String, dynamic> json) => DetailSparepart.fromMap(json);
}
