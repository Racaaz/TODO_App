import 'package:flutter/material.dart';

import '../models/task.dart';

/// Warna untuk tiap prioritas (titik di kartu dan pilihan di form).
extension TaskPriorityStyle on TaskPriority {
  Color get color => switch (this) {
        TaskPriority.rendah => const Color(0xFF22C55E),
        TaskPriority.sedang => const Color(0xFFF59E0B),
        TaskPriority.tinggi => const Color(0xFFEF4444),
      };

  Color get background => switch (this) {
        TaskPriority.rendah => const Color(0xFFDCFCE7),
        TaskPriority.sedang => const Color(0xFFFEF3C7),
        TaskPriority.tinggi => const Color(0xFFFEE2E2),
      };

  Color get foreground => switch (this) {
        TaskPriority.rendah => const Color(0xFF15803D),
        TaskPriority.sedang => const Color(0xFFB45309),
        TaskPriority.tinggi => const Color(0xFFB91C1C),
      };
}
