import '../utils/api_parsers.dart';

class Servis {
  final int? idServis;
  final int idKendaraan;
  final int idMekanik;
  final DateTime tanggal;
  final String? keluhan;
  final String status;

  Servis({this.idServis, required this.idKendaraan, required this.idMekanik, required this.tanggal, this.keluhan, required this.status});

  Map<String, dynamic> toMap() => {
    if (idServis != null) 'id_servis': idServis,
    'id_kendaraan': idKendaraan,
    'id_mekanik': idMekanik,
    'tanggal': tanggal.toIso8601String().substring(0, 10),
    if (keluhan != null) 'keluhan': keluhan,
    'status': status,
  };

  factory Servis.fromMap(Map<String, dynamic> map) => Servis(
    idServis: parseInt(map['id_servis']),
    idKendaraan: parseIntN(map['id_kendaraan']),
    idMekanik: parseIntN(map['id_mekanik']),
    tanggal: parseDate(map['tanggal']),
    keluhan: parseString(map['keluhan']),
    status: parseString(map['status']) ?? 'menunggu',
  );

  factory Servis.fromJson(Map<String, dynamic> json) => Servis.fromMap(json);

  Servis copyWith({int? idServis, int? idKendaraan, int? idMekanik, DateTime? tanggal, String? keluhan, String? status}) => Servis(
    idServis: idServis ?? this.idServis,
    idKendaraan: idKendaraan ?? this.idKendaraan,
    idMekanik: idMekanik ?? this.idMekanik,
    tanggal: tanggal ?? this.tanggal,
    keluhan: keluhan ?? this.keluhan,
    status: status ?? this.status,
  );
}
