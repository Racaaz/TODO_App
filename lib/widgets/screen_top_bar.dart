import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Tombol bulat 40x40 (dipakai untuk tombol kembali, hapus, dan aksi lain).
class CircleIconButton extends StatelessWidget {
  const CircleIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.background = Colors.white,
    this.iconColor = AppColors.textPrimary,
    this.bordered = true,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final Color background;
  final Color iconColor;
  final bool bordered;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      shape: CircleBorder(
        side: bordered
            ? const BorderSide(color: AppColors.border)
            : BorderSide.none,
      ),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, size: 20, color: iconColor),
        ),
      ),
    );
  }
}

/// Bar atas standar: tombol kembali (opsional), judul di tengah, aksi di kanan.
class ScreenTopBar extends StatelessWidget {
  const ScreenTopBar({
    super.key,
    required this.title,
    this.trailing,
    this.showBack = true,
  });

  final String title;
  final Widget? trailing;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
      child: Row(
        children: [
          if (showBack)
            CircleIconButton(
              icon: Icons.arrow_back_ios_new_rounded,
              onPressed: () => Navigator.of(context).pop(),
            )
          else
            const SizedBox(width: 40),
          Expanded(
            child: Center(
              child: Text(
                title,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.pageText),
              ),
            ),
          ),
          trailing ?? const SizedBox(width: 40),
        ],
      ),
    );
  }
}
