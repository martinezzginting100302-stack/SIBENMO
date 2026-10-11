/// Parser defensif untuk JSON Laravel (Eloquent) yang tipenya bisa berbeda
/// dari SQLite lama: decimal MySQL diserialisasi sebagai String ("25000.00"),
/// integer kadang String, tanggal bisa "YYYY-MM-DD" atau ISO8601 penuh.
int? parseInt(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v);
  return null;
}

int parseIntN(dynamic v, [int fallback = 0]) => parseInt(v) ?? fallback;

double? parseDouble(dynamic v) {
  if (v == null) return null;
  if (v is double) return v;
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v);
  return null;
}

double parseDoubleN(dynamic v, [double fallback = 0.0]) => parseDouble(v) ?? fallback;

String? parseString(dynamic v) {
  if (v == null) return null;
  if (v is String) return v;
  return v.toString();
}

DateTime parseDate(dynamic v) {
  if (v == null) return DateTime.now();
  if (v is DateTime) return v;
  final s = v.toString();
  try {
    return DateTime.parse(s);
  } catch (_) {
    return DateTime.now();
  }
}
