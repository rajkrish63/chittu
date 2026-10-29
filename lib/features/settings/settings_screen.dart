import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/locale_controller.dart';
import '../../core/theme_controller.dart';
import '../../core/strings.dart';
import '../../data/database/database_helper.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _localeController = AppLocaleController.instance;
  final _themeController = AppThemeController.instance;

  Future<void> _exportBackup() async {
    try {
      final json = await DatabaseHelper.instance.exportJson();
      await Share.share(
        json,
        subject: 'Chit Notebook Backup - ${DateTime.now().toIso8601String().substring(0, 10)}',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.backupReady)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${S.error}: $e')),
        );
      }
    }
  }

  Future<void> _restoreBackup() async {
    final textController = TextEditingController();
    final jsonStr = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(S.importBackupDialogTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      S.restoreConfirmWarning,
                      style: TextStyle(fontSize: 12, color: Colors.red.shade900),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: textController,
              maxLines: 6,
              decoration: InputDecoration(
                hintText: S.importBackupHint,
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(S.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            onPressed: () {
              if (textController.text.trim().isNotEmpty) {
                Navigator.pop(ctx, textController.text.trim());
              }
            },
            child: Text(S.restoreAction),
          ),
        ],
      ),
    );

    if (jsonStr == null || jsonStr.trim().isEmpty) return;

    try {
      await DatabaseHelper.instance.importJson(jsonStr);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.green.shade800,
            content: Text(S.restoreSuccess),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red.shade800,
            content: Text('${S.invalidBackup}: $e'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([_localeController, _themeController]),
      builder: (context, _) {
        final currentLang = _localeController.languageCode;
        final currentThemeMode = _themeController.themeMode;

        return Scaffold(
          appBar: AppBar(
            title: Text(S.settings, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          body: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            children: [
              // Theme Mode Selection Card
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.palette_outlined,
                              color: Theme.of(context).colorScheme.primary),
                          const SizedBox(width: 8),
                          Text(
                            S.themeModeTitle,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        S.themeModeSubtitle,
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 12),
                      RadioGroup<ThemeMode>(
                        groupValue: currentThemeMode,
                        onChanged: (mode) {
                          if (mode != null) _themeController.setThemeMode(mode);
                        },
                        child: Column(
                          children: [
                            RadioListTile<ThemeMode>(
                              value: ThemeMode.system,
                              title: Text(S.themeSystem),
                              secondary: const Icon(Icons.brightness_auto_outlined),
                              contentPadding: EdgeInsets.zero,
                            ),
                            const Divider(height: 1),
                            RadioListTile<ThemeMode>(
                              value: ThemeMode.light,
                              title: Text(S.themeLight),
                              secondary: const Icon(Icons.light_mode_outlined),
                              contentPadding: EdgeInsets.zero,
                            ),
                            const Divider(height: 1),
                            RadioListTile<ThemeMode>(
                              value: ThemeMode.dark,
                              title: Text(S.themeDark),
                              secondary: const Icon(Icons.dark_mode_outlined),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Language Selection Card
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.language_rounded,
                              color: Theme.of(context).colorScheme.primary),
                          const SizedBox(width: 8),
                          Text(
                            S.language,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        S.languageSubtitle,
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 12),
                      RadioGroup<String>(
                        groupValue: currentLang,
                        onChanged: (val) {
                          if (val != null) _localeController.setLanguage(val);
                        },
                        child: const Column(
                          children: [
                            RadioListTile<String>(
                              value: 'en',
                              title: Text('English (India)'),
                              subtitle: Text('English interface with ₹ INR'),
                              secondary: Text('🇮🇳', style: TextStyle(fontSize: 22)),
                              contentPadding: EdgeInsets.zero,
                            ),
                            Divider(height: 1),
                            RadioListTile<String>(
                              value: 'ta',
                              title: Text('தமிழ் (Tamil)'),
                              subtitle: Text('தமிழில் பார்க்க'),
                              secondary: Text('🇮🇳', style: TextStyle(fontSize: 22)),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Data & Backup Card
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                      child: Row(
                        children: [
                          Icon(Icons.storage_rounded,
                              color: Theme.of(context).colorScheme.primary),
                          const SizedBox(width: 8),
                          Text(
                            S.backupAndData,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    ListTile(
                      leading: const CircleAvatar(
                        child: Icon(Icons.cloud_download_outlined),
                      ),
                      title: Text(S.exportBackup),
                      subtitle: Text(S.exportBackupSubtitle),
                      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                      onTap: _exportBackup,
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    ListTile(
                      leading: const CircleAvatar(
                        child: Icon(Icons.cloud_upload_outlined),
                      ),
                      title: Text(S.importBackup),
                      subtitle: Text(S.importBackupSubtitle),
                      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                      onTap: _restoreBackup,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // About Section Card
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline_rounded,
                              color: Theme.of(context).colorScheme.primary),
                          const SizedBox(width: 8),
                          Text(
                            S.aboutApp,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        S.appTitle,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        S.appVersion,
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        S.privacyNotice,
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
