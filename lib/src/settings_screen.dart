import 'package:flutter/material.dart';

import 'about_screen.dart';
import 'app_settings.dart';
import 'assessment_repository.dart';
import 'backup_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    required this.settings,
    required this.repository,
  });
  final AppSettings settings;
  final AssessmentRepository repository;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final _clinic = TextEditingController(text: widget.settings.clinicName);
  late final _dietitian = TextEditingController(
    text: widget.settings.dietitianName,
  );
  late final _credentials = TextEditingController(
    text: widget.settings.credentials,
  );

  @override
  void dispose() {
    _clinic.dispose();
    _dietitian.dispose();
    _credentials.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Settings')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Appearance', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 10),
        Card(
          child: RadioGroup<ThemeMode>(
            groupValue: widget.settings.themeMode,
            onChanged: (value) {
              if (value != null) widget.settings.setThemeMode(value);
              setState(() {});
            },
            child: const Column(
              children: [
                RadioListTile(
                  value: ThemeMode.system,
                  title: Text('Use system theme'),
                ),
                RadioListTile(
                  value: ThemeMode.light,
                  title: Text('Light theme'),
                ),
                RadioListTile(value: ThemeMode.dark, title: Text('Dark theme')),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text('Report profile', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 10),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _clinic,
                  decoration: const InputDecoration(labelText: 'Clinic name'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _dietitian,
                  decoration: const InputDecoration(
                    labelText: 'Dietitian name',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _credentials,
                  decoration: const InputDecoration(
                    labelText: 'Credentials / registration',
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () async {
                    await widget.settings.saveProfile(
                      clinic: _clinic.text,
                      dietitian: _dietitian.text,
                      qualification: _credentials.text,
                    );
                    if (mounted) {
                      ScaffoldMessenger.of(this.context).showSnackBar(
                        const SnackBar(content: Text('Report profile saved.')),
                      );
                    }
                  },
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Save report profile'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text('Privacy lock', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 10),
        Card(
          child: ListTile(
            leading: Icon(
              widget.settings.pinEnabled
                  ? Icons.lock_outline
                  : Icons.lock_open_outlined,
            ),
            title: Text(
              widget.settings.pinEnabled
                  ? 'App PIN is enabled'
                  : 'Set an app PIN',
            ),
            subtitle: const Text(
              'The app locks when it returns from the background.',
            ),
            trailing: TextButton(
              onPressed: widget.settings.pinEnabled ? _disablePin : _setPin,
              child: Text(widget.settings.pinEnabled ? 'Disable' : 'Set PIN'),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text('Data protection', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 10),
        Card(
          child: ListTile(
            leading: const Icon(Icons.enhanced_encryption_outlined),
            title: const Text('Encrypted backup and restore'),
            subtitle: const Text('Protect complete backups with a password.'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push<void>(
              context,
              MaterialPageRoute(
                builder: (_) => BackupScreen(repository: widget.repository),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text('About', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 10),
        Card(
          child: ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('About Dt Haritha'),
            subtitle: const Text(
              'Profile, qualifications, experience, and app ownership',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push<void>(
              context,
              MaterialPageRoute(builder: (_) => const AboutScreen()),
            ),
          ),
        ),
      ],
    ),
  );

  Future<void> _setPin() async {
    final pin = await _askPin('Create a 4–8 digit PIN');
    if (pin == null || !RegExp(r'^\d{4,8}$').hasMatch(pin)) {
      if (mounted && pin != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Use 4 to 8 digits.')));
      }
      return;
    }
    await widget.settings.setPin(pin);
    if (mounted) setState(() {});
  }

  Future<void> _disablePin() async {
    final pin = await _askPin('Enter current PIN');
    if (pin == null) return;
    if (!widget.settings.verifyPin(pin)) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Incorrect PIN.')));
      }
      return;
    }
    await widget.settings.clearPin();
    if (mounted) setState(() {});
  }

  Future<String?> _askPin(String title) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          obscureText: true,
          keyboardType: TextInputType.number,
          maxLength: 8,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
    controller.dispose();
    return result;
  }
}
