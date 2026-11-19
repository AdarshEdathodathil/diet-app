import 'dart:io';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import 'assessment_repository.dart';
import 'csv_export_service.dart';

class ExportScreen extends StatefulWidget {
  const ExportScreen({super.key, required this.repository});
  final AssessmentRepository repository;

  @override
  State<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends State<ExportScreen> {
  bool _includeIdentity = true;
  bool _exporting = false;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Export patient data')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.table_view_outlined,
                  size: 36,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 14),
                Text(
                  'Complete CSV export',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Creates one Excel-compatible file containing every patient and assessment. '
                  'Every clinical factor and note is included.',
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _includeIdentity,
                  title: const Text('Include identifying information'),
                  subtitle: const Text(
                    'Patient name, OP number and phone number',
                  ),
                  onChanged: (value) =>
                      setState(() => _includeIdentity = value),
                ),
                if (_includeIdentity)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: .1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.privacy_tip_outlined, color: Colors.orange),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'The CSV file is not encrypted. Share and store it only in an approved secure location.',
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: _exporting ? null : _export,
                  icon: _exporting
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.ios_share_outlined),
                  label: const Text('Generate and share CSV'),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );

  Future<void> _export() async {
    setState(() => _exporting = true);
    late final List<CsvExportDocument> documents;
    try {
      documents = await const CsvExportService().generateAll(
        widget.repository,
        includeIdentity: _includeIdentity,
      );
    } catch (error, stackTrace) {
      debugPrint('CSV generation failed: $error\n$stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not read the patient data for CSV export.'),
          ),
        );
        setState(() => _exporting = false);
      }
      return;
    }

    Directory? exportDirectory;
    late final List<File> files;
    try {
      exportDirectory = await Directory.systemTemp.createTemp(
        'dt_haritha_csv_',
      );
      files = [];
      for (final document in documents) {
        final file = File('${exportDirectory.path}/${document.name}');
        await file.writeAsBytes(document.bytes, flush: true);
        files.add(file);
      }
    } catch (error, stackTrace) {
      debugPrint('CSV file preparation failed: $error\n$stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('The CSV file could not be prepared for sharing.'),
          ),
        );
        setState(() => _exporting = false);
      }
      await _removeExportDirectory(exportDirectory);
      return;
    }

    try {
      await SharePlus.instance.share(
        ShareParams(
          subject: 'Dt Haritha patient data export',
          text: 'Patient and assessment CSV export',
          files: files
              .map((file) => XFile(file.path, mimeType: 'text/csv'))
              .toList(),
        ),
      );
    } catch (error, stackTrace) {
      debugPrint('CSV sharing failed: $error\n$stackTrace');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'The CSV file was created, but the share window could not be opened.',
          ),
        ),
      );
    } finally {
      await _removeExportDirectory(exportDirectory);
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _removeExportDirectory(Directory? directory) async {
    if (directory == null) return;
    try {
      if (await directory.exists()) await directory.delete(recursive: true);
    } catch (error, stackTrace) {
      debugPrint('CSV temporary-file cleanup failed: $error\n$stackTrace');
    }
  }
}
