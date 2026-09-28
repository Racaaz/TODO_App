import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Semua warna diambil dari desain Figma.
///
/// primary, background, primarySoft, dan primaryTint SENGAJA dibuat bisa
/// diubah (bukan const) supaya pengguna bisa mengganti warna aksen dan
/// latar aplikasi lewat layar Profil. Panggil AppColors.applyFrom(...)
/// sekali di awal, dan setiap kali pengaturan warna berubah.
class AppColors {
  AppColors._();

  static Color primary = const Color(0xFF4F6BED);
  static Color primarySoft = const Color(0xFFEEF2FF);
  static Color primaryTint = const Color(0xFFE0E7FF);

  static Color background = const Color(0xFFF7F8FA);

  /// Warna teks untuk tulisan yang duduk LANGSUNG di atas warna latar
  /// (judul halaman, label antar-kartu, dsb) — otomatis menyesuaikan jadi
  /// terang kalau latar gelap dipilih. Teks DI DALAM kartu putih tetap
  /// memakai textPrimary/textSecondary/textMuted biasa (selalu gelap),
  /// karena kartu putih selalu kontras terlepas dari warna latar.
  static Color pageText = const Color(0xFF1B1F2A);
  static Color pageTextMuted = const Color(0xFF6B7280);

  /// Warna pilihan untuk "Warna Aksen" di layar Profil.
  static const List<int> accentChoices = [
    0xFF4F6BED, 0xFF0EA5E9, 0xFF14B8A6, 0xFF22C55E,
    0xFFF59E0B, 0xFFEF4444, 0xFFEC4899, 0xFF8B5CF6,
    0xFF6366F1, 0xFF475569,
  ];

  /// Warna pilihan untuk "Warna Latar" di layar Profil.
  static const List<int> backgroundChoices = [
    0xFFF7F8FA, 0xFFFFF7ED, 0xFFF0FDF4, 0xFFEFF6FF,
    0xFFFDF2F8, 0xFFF5F3FF, 0xFFFEF9C3, 0xFFF1F5F9,
    0xFF1F2937, 0xFF111827,
  ];

  static void applyFrom(int primaryValue, int backgroundValue) {
    primary = Color(primaryValue);
    background = Color(backgroundValue);
    primarySoft = Color.alphaBlend(primary.withValues(alpha: 0.12), Colors.white);
    primaryTint = Color.alphaBlend(primary.withValues(alpha: 0.22), Colors.white);

    final dark = background.computeLuminance() < 0.4;
    pageText = dark ? const Color(0xFFF3F4F6) : const Color(0xFF1B1F2A);
    pageTextMuted = dark ? const Color(0xFFB8BEC9) : const Color(0xFF6B7280);
  }

  /// Sebagian latar gelap butuh teks putih supaya tetap terbaca.
  static bool get isBackgroundDark => background.computeLuminance() < 0.4;

  static const textPrimary = Color(0xFF1B1F2A);
  static const textSecondary = Color(0xFF6B7280);
  static const textLabel = Color(0xFF374151);
  static const textMuted = Color(0xFF9CA3AF);

  static const border = Color(0xFFE5E7EB);
  static const borderLight = Color(0xFFEEF0F3);
  static const checkboxBorder = Color(0xFFC7CCD6);

  static const danger = Color(0xFFEF4444);
  static const dangerSoft = Color(0xFFFEE2E2);
  static const success = Color(0xFF15803D);
  static const successSoft = Color(0xFFDCFCE7);
  static const warning = Color(0xFFB45309);
  static const warningSoft = Color(0xFFFEF3C7);
}

class AppDecorations {
  AppDecorations._();

  /// Kartu putih dengan border tipis dan bayangan halus (seperti Task Card di Figma).
  static BoxDecoration card({double radius = 16}) {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: AppColors.borderLight),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }
}

ThemeData buildAppTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary).copyWith(
      primary: AppColors.primary,
      surface: Colors.white,
    ),
    scaffoldBackgroundColor: AppColors.background,
  );

  return base.copyWith(
    textTheme: GoogleFonts.interTextTheme(base.textTheme).apply(
      bodyColor: AppColors.textPrimary,
      displayColor: AppColors.textPrimary,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size(0, 54),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        backgroundColor: Colors.white,
        minimumSize: const Size(0, 54),
        side: BorderSide(color: AppColors.primary, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.all(Colors.white),
      trackColor: WidgetStateProperty.resolveWith((states) {
        return states.contains(WidgetState.selected)
            ? AppColors.primary
            : AppColors.checkboxBorder;
      }),
      trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      indicatorColor: Colors.transparent,
      elevation: 0,
      height: 72,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return GoogleFonts.inter(
          fontSize: 11,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          color: selected ? AppColors.primary : AppColors.textMuted,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return IconThemeData(
          size: 24,
          color: selected ? AppColors.primary : AppColors.textMuted,
        );
      }),
    ),
  );
}
