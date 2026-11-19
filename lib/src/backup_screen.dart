import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import 'assessment_repository.dart';
import 'encrypted_backup_service.dart';

class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key, required this.repository});
  final AssessmentRepository repository;

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Backup and restore')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: ListTile(
            contentPadding: const EdgeInsets.all(18),
            leading: const Icon(Icons.enhanced_encryption_outlined, size: 34),
            title: const Text('Create encrypted backup'),
            subtitle: const Text(
              'Includes patients, assessments, drafts, and clinical presets.',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: _busy ? null : _create,
          ),
        ),
        Card(
          child: ListTile(
            contentPadding: const EdgeInsets.all(18),
            leading: const Icon(Icons.settings_backup_restore, size: 34),
            title: const Text('Restore encrypted backup'),
            subtitle: const Text(
              'Replaces the clinical records currently stored on this device.',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: _busy ? null : _restore,
          ),
        ),
        if (_busy)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          ),
        const Padding(
          padding: EdgeInsets.all(12),
          child: Text(
            'Keep the backup password in a safe place. It cannot be recovered by the app.',
          ),
        ),
      ],
    ),
  );

  Future<void> _create() async {
    final password = await _password('Create backup password');
    if (password == null) return;
    if (password.length < 8) {
      _show('Use at least 8 characters.');
      return;
    }
    setState(() => _busy = true);
    try {
      final file = await const EncryptedBackupService().create(
        widget.repository,
        password,
      );
      await SharePlus.instance.share(
        ShareParams(
          subject: 'Dt Haritha encrypted backup',
          files: [XFile(file.path, mimeType: 'application/octet-stream')],
        ),
      );
    } catch (_) {
      _show('The encrypted backup could not be created.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _restore() async {
    final selection = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['dthbackup'],
    );
    final path = selection?.files.single.path;
    if (path == null || !mounted) return;
    final password = await _password('Enter backup password');
    if (password == null || !mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Replace local records?'),
        content: const Text(
          'The current patients and assessments will be replaced by this backup.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Restore'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _busy = true);
    try {
      await const EncryptedBackupService().restore(
        widget.repository,
        File(path),
        password,
      );
      _show('Backup restored successfully.');
    } on FormatException catch (error) {
      _show(error.message);
    } catch (_) {
      _show('The backup could not be restored.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<String?> _password(String title) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          obscureText: true,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Password',
            helperText: 'At least 8 characters',
          ),
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

  void _show(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
