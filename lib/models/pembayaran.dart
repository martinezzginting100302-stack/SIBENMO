import '../utils/api_parsers.dart';

class Pembayaran {
  final int? idPembayaran;
  final int idServis;
  final DateTime tanggal;
  final double totalBayar;
  final String metodePembayaran;

  Pembayaran({this.idPembayaran, required this.idServis, required this.tanggal, required this.totalBayar, required this.metodePembayaran});

  Map<String, dynamic> toMap() => {
    if (idPembayaran != null) 'id_pembayaran': idPembayaran,
    'id_servis': idServis,
    'tanggal': tanggal.toIso8601String().substring(0, 10),
    'total_bayar': totalBayar,
    'metode_pembayaran': metodePembayaran,
  };

  factory Pembayaran.fromMap(Map<String, dynamic> map) => Pembayaran(
    idPembayaran: parseInt(map['id_pembayaran']),
    idServis: parseIntN(map['id_servis']),
    tanggal: parseDate(map['tanggal']),
    totalBayar: parseDoubleN(map['total_bayar']),
    metodePembayaran: parseString(map['metode_pembayaran']) ?? 'tunai',
  );

  factory Pembayaran.fromJson(Map<String, dynamic> json) => Pembayaran.fromMap(json);
}
