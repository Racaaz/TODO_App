import '../models/task.dart';

/// Keterangan singkat sisa waktu yang ditampilkan di kartu tugas.
class DeadlineInfo {
  const DeadlineInfo(this.text, {required this.overdue});

  final String text;
  final bool overdue;
}

/// Hanya menampilkan info kalau tugas belum selesai dan sudah terlambat
/// atau deadline-nya kurang dari 3 jam lagi.
DeadlineInfo? deadlineInfo(Task task, DateTime now) {
  if (task.isDone) return null;
  final diff = task.dueDate.difference(now);
  if (diff.isNegative) {
    return DeadlineInfo('Terlambat ${_largestUnit(-diff)}', overdue: true);
  }
  if (diff <= const Duration(hours: 3)) {
    return DeadlineInfo('${_largestUnit(diff)} lagi', overdue: false);
  }
  return null;
}

String _largestUnit(Duration d) {
  if (d.inDays >= 1) return '${d.inDays} hari';
  if (d.inHours >= 1) return '${d.inHours} jam';
  final minutes = d.inMinutes < 1 ? 1 : d.inMinutes;
  return '$minutes menit';
}

/// Versi lengkap, contoh: "2 jam 15 menit lagi" atau "Terlambat 5 menit".
String formatRemaining(DateTime due, DateTime now) {
  final diff = due.difference(now);
  final isLate = diff.isNegative;
  final d = isLate ? -diff : diff;

  if (d.inMinutes < 1) {
    return isLate ? 'Baru saja lewat' : 'Kurang dari 1 menit lagi';
  }

  final parts = <String>[];
  if (d.inDays > 0) parts.add('${d.inDays} hari');
  if (d.inHours % 24 > 0) parts.add('${d.inHours % 24} jam');
  if (d.inMinutes % 60 > 0) parts.add('${d.inMinutes % 60} menit');

  final text = parts.take(2).join(' ');
  return isLate ? 'Terlambat $text' : '$text lagi';
}
