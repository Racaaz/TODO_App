import 'package:flutter/material.dart' show TimeOfDay;

const _dayNames = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];

const _monthNames = [
  'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
  'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
];

const _shortMonthNames = [
  'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
  'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
];

/// Label hari untuk kepala kalender (Senin lebih dulu).
const List<String> weekdayLabels = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];

String _two(int n) => n.toString().padLeft(2, '0');

/// Contoh: "Minggu, 20 September 2026"
String formatFullDate(DateTime d) =>
    '${_dayNames[d.weekday - 1]}, ${d.day} ${_monthNames[d.month - 1]} ${d.year}';

/// Contoh: "21 Sep 2026"
String formatShortDate(DateTime d) =>
    '${d.day} ${_shortMonthNames[d.month - 1]} ${d.year}';

/// Contoh: "September 2026"
String formatMonthYear(DateTime d) => '${_monthNames[d.month - 1]} ${d.year}';

/// Contoh: "09:05"
String formatTime(DateTime d) => '${_two(d.hour)}:${_two(d.minute)}';

/// Contoh: "09:05:33"
String formatTimeWithSeconds(DateTime d) =>
    '${_two(d.hour)}:${_two(d.minute)}:${_two(d.second)}';

String formatTimeOfDay(TimeOfDay t) => '${_two(t.hour)}:${_two(t.minute)}';

bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
