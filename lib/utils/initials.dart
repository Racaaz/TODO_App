/// Contoh: "Raditya Cahya" -> "RC", "Budi" -> "B", "" -> "?".
String initialsFromName(String name) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) return '?';
  final parts = trimmed.split(RegExp(r'\s+'));
  final first = parts.first.isNotEmpty ? parts.first[0] : '';
  final last = parts.length > 1 && parts.last.isNotEmpty ? parts.last[0] : '';
  final result = (first + last).toUpperCase();
  return result.isEmpty ? '?' : result;
}
