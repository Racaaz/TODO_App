/// Preset pilihan cepat untuk menit-sebelum-deadline (dipakai di dialog
/// tambah pengingat). 0 = tepat saat deadline.
const List<int> reminderPresets = [0, 5, 15, 30, 60, 180, 1440, 10080];

/// Contoh: 0 -> "Tepat waktu", 90 -> "1 jam 30 menit sebelum",
/// 1440 -> "1 hari sebelum".
String formatOffsetLabel(int minutes) {
  if (minutes <= 0) return 'Tepat waktu';

  final days = minutes ~/ 1440;
  final hours = (minutes % 1440) ~/ 60;
  final mins = minutes % 60;

  final parts = <String>[];
  if (days > 0) parts.add('$days hari');
  if (hours > 0) parts.add('$hours jam');
  if (mins > 0) parts.add('$mins menit');

  return '${parts.take(2).join(' ')} sebelum';
}

/// Label singkat untuk chip (lebih ringkas dari formatOffsetLabel).
String formatOffsetChip(int minutes) {
  if (minutes <= 0) return 'Tepat waktu';
  if (minutes % 1440 == 0) return '${minutes ~/ 1440} hari';
  if (minutes % 60 == 0) return '${minutes ~/ 60} jam';
  return '$minutes menit';
}
