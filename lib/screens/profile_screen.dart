import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../services/category_store.dart';
import '../services/notification_service.dart';
import '../services/settings_store.dart';
import '../services/task_store.dart';
import '../services/file_provider_channel.dart';
import '../theme/app_theme.dart';
import '../utils/initials.dart';
import '../widgets/reminder_offsets_editor.dart';

/// Tab Profil: identitas ringkas pengguna, warna aplikasi, suara alarm
/// custom, pengingat default untuk tugas baru, dan izin notifikasi.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    required this.store,
    required this.categories,
    required this.settingsStore,
  });

  final TaskStore store;
  final CategoryStore categories;
  final SettingsStore settingsStore;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final TextEditingController _nameController;
  bool _pickingSound = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.settingsStore.settings.displayName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickCustomSound() async {
    setState(() => _pickingSound = true);
    try {
      // file_picker v11+ memakai method static, bukan lagi FilePicker.platform.
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['mp3', 'wav', 'ogg', 'm4a'],
      );
      if (file == null || file.path == null) return;

      await widget.settingsStore.setCustomSound(file.path!, file.name);
      await NotificationService.instance.applySettings(widget.settingsStore.settings);
      await widget.store.rescheduleAll();

      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text('Suara alarm diganti ke "${file.name}"')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text('Gagal memilih file: $e')));
      }
    } finally {
      if (mounted) setState(() => _pickingSound = false);
    }
  }

  Future<void> _clearCustomSound() async {
    await widget.settingsStore.clearCustomSound();
    await NotificationService.instance.applySettings(widget.settingsStore.settings);
    await widget.store.rescheduleAll();
    if (mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Suara alarm dikembalikan ke bawaan sistem')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.settingsStore.isLoaded) return const Center(child: CircularProgressIndicator());

    return ListenableBuilder(
      listenable: widget.settingsStore,
      builder: (context, _) {
        final settings = widget.settingsStore.settings;

        return ListView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          children: [
            Text('Profil', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.pageText)),
            const SizedBox(height: 20),
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: AppColors.primaryTint,
                    child: Text(
                      initialsFromName(settings.displayName),
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.primary),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: 220,
                    child: TextField(
                      controller: _nameController,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.pageText),
                      decoration: const InputDecoration(border: InputBorder.none, isDense: true),
                      onChanged: (value) => widget.settingsStore.setDisplayName(value),
                    ),
                  ),
                  Text('Data tersimpan di HP ini saja', style: TextStyle(fontSize: 13, color: AppColors.pageTextMuted)),
                ],
              ),
            ),

            const SizedBox(height: 28),
            const _SectionTitle('Tampilan'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: AppDecorations.card(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Warna Aksen', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  const Text(
                    'Dipakai untuk tombol, kartu progres, dan bagian terpilih',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 12),
                  _ColorSwatchRow(
                    choices: AppColors.accentChoices,
                    selected: settings.primaryColor,
                    onSelected: (value) => widget.settingsStore.setColors(primary: value),
                  ),
                  const SizedBox(height: 20),
                  const Divider(height: 1, color: AppColors.borderLight),
                  const SizedBox(height: 20),
                  const Text('Warna Latar', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  const Text(
                    'Warna latar belakang layar aplikasi',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 12),
                  _ColorSwatchRow(
                    choices: AppColors.backgroundChoices,
                    selected: settings.backgroundColor,
                    onSelected: (value) => widget.settingsStore.setColors(background: value),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),
            const _SectionTitle('Suara Alarm'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: AppDecorations.card(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(12)),
                        child: Icon(Icons.music_note_rounded, size: 20, color: AppColors.primary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Suara saat ini', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                            const SizedBox(height: 2),
                            Text(
                              settings.soundLabel ?? 'Bawaan sistem',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _pickingSound ? null : _pickCustomSound,
                          icon: _pickingSound
                              ? const SizedBox(
                                  width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.upload_file_rounded, size: 18),
                          label: const Text('Pilih File MP3'),
                        ),
                      ),
                      if (settings.soundPath != null) ...[
                        const SizedBox(width: 10),
                        IconButton.outlined(
                          onPressed: _clearCustomSound,
                          icon: const Icon(Icons.restart_alt_rounded, size: 18),
                          tooltip: 'Kembalikan ke bawaan',
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'File disalin ke penyimpanan aplikasi, jadi tetap berfungsi walau file aslinya dipindah atau dihapus.',
                    style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),
            const _SectionTitle('Pengingat Default'),
            const SizedBox(height: 4),
            Text(
              'Dipakai otomatis saat membuat tugas baru (tidak mengubah tugas yang sudah ada)',
              style: TextStyle(fontSize: 12, color: AppColors.pageTextMuted),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: AppDecorations.card(),
              child: ReminderOffsetsEditor(
                offsets: settings.defaultReminderOffsets,
                onChanged: widget.settingsStore.setDefaultReminderOffsets,
              ),
            ),

            const SizedBox(height: 28),
            const _SectionTitle('Pengaturan Lain'),
            const SizedBox(height: 12),
            Container(
              decoration: AppDecorations.card(),
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.alarm_rounded, color: AppColors.primary),
                    title: const Text('Izin alarm & notifikasi'),
                    subtitle: const Text('Wajib aktif agar pengingat deadline berbunyi'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () async {
                      await NotificationService.instance.init();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context)
                          ..hideCurrentSnackBar()
                          ..showSnackBar(const SnackBar(
                            content: Text('Izin alarm diminta ulang. Cek pengaturan HP kalau belum muncul.'),
                          ));
                      }
                    },
                  ),
                  const Divider(height: 1, color: AppColors.borderLight),
                  ListTile(
                    leading: Icon(Icons.battery_saver_rounded, color: AppColors.primary),
                    title: const Text('Nonaktifkan pembatasan baterai'),
                    subtitle: const Text('Supaya alarm tetap bunyi saat HP terkunci/tidur lama'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () async {
                      final opened = await FileProviderChannel.requestIgnoreBatteryOptimizations();
                      if (context.mounted && !opened) {
                        ScaffoldMessenger.of(context)
                          ..hideCurrentSnackBar()
                          ..showSnackBar(const SnackBar(
                            content: Text('Tidak bisa membuka pengaturan ini otomatis. Buka manual lewat Pengaturan > Baterai.'),
                          ));
                      }
                    },
                  ),
                  const Divider(height: 1, color: AppColors.borderLight),
                  const ListTile(
                    leading: Icon(Icons.info_outline_rounded, color: AppColors.textSecondary),
                    title: Text('Tentang aplikasi'),
                    subtitle: Text('To Do List · versi 1.0.0'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),
            const _SectionTitle('Zona Berbahaya'),
            const SizedBox(height: 12),
            Container(
              decoration: AppDecorations.card(),
              child: ListTile(
                leading: const Icon(Icons.delete_forever_rounded, color: AppColors.danger),
                title: const Text('Reset Semua Data', style: TextStyle(color: AppColors.danger)),
                subtitle: const Text('Menghapus semua tugas dan kategori custom (untuk pengujian)'),
                onTap: () => _confirmResetData(context),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _confirmResetData(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reset semua data?'),
        content: const Text(
          'Semua tugas dan kategori custom akan dihapus permanen. Warna dan suara alarm '
          'tidak ikut terhapus. Tindakan ini tidak bisa dibatalkan.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await widget.store.resetAll();
      await widget.categories.resetToDefaults();
      if (context.mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(const SnackBar(content: Text('Semua data tugas sudah dihapus')));
      }
    }
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.pageText));
  }
}

class _ColorSwatchRow extends StatelessWidget {
  const _ColorSwatchRow({required this.choices, required this.selected, required this.onSelected});

  final List<int> choices;
  final int selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        for (final value in choices)
          GestureDetector(
            onTap: () => onSelected(value),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Color(value),
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected == value ? AppColors.textPrimary : Colors.black12,
                  width: selected == value ? 2 : 1,
                ),
              ),
              child: selected == value
                  ? Icon(
                      Icons.check_rounded,
                      size: 18,
                      color: Color(value).computeLuminance() > 0.5 ? Colors.black87 : Colors.white,
                    )
                  : null,
            ),
          ),
      ],
    );
  }
}
