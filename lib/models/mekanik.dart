import '../utils/api_parsers.dart';

class Mekanik {
  final int? idMekanik;
  final String nama;
  final String? noHp;

  Mekanik({this.idMekanik, required this.nama, this.noHp});

  Map<String, dynamic> toMap() => {
    if (idMekanik != null) 'id_mekanik': idMekanik,
    'nama': nama,
    if (noHp != null) 'no_hp': noHp,
  };

  factory Mekanik.fromMap(Map<String, dynamic> map) => Mekanik(
    idMekanik: parseInt(map['id_mekanik']),
    nama: parseString(map['nama']) ?? '',
    noHp: parseString(map['no_hp']),
  );

  factory Mekanik.fromJson(Map<String, dynamic> json) => Mekanik.fromMap(json);

  Mekanik copyWith({int? idMekanik, String? nama, String? noHp}) => Mekanik(
    idMekanik: idMekanik ?? this.idMekanik,
    nama: nama ?? this.nama,
    noHp: noHp ?? this.noHp,
  );
}
