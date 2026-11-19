import 'package:flutter/material.dart';

import 'assessment_repository.dart';
import 'assessment_screen.dart';
import 'app_settings.dart';
import 'patient.dart';
import 'patient_form_screen.dart';
import 'saved_assessment.dart';

class PatientDetailScreen extends StatefulWidget {
  const PatientDetailScreen({
    super.key,
    required this.repository,
    required this.patient,
    required this.settings,
  });
  final AssessmentRepository repository;
  final Patient patient;
  final AppSettings settings;

  @override
  State<PatientDetailScreen> createState() => _PatientDetailScreenState();
}

class _PatientDetailScreenState extends State<PatientDetailScreen> {
  late Patient _patient = widget.patient;
  late Future<List<SavedAssessment>> _history = _load();

  Future<List<SavedAssessment>> _load() =>
      widget.repository.assessmentsForPatient(_patient.id!);
  void _refresh() => setState(() => _history = _load());

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(_patient.displayName),
      actions: [
        IconButton(
          onPressed: _edit,
          tooltip: 'Edit patient',
          icon: const Icon(Icons.edit_outlined),
        ),
        PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'archive') _archive();
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'archive', child: Text('Archive patient')),
          ],
        ),
      ],
    ),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: _newAssessment,
      icon: const Icon(Icons.add),
      label: const Text('New assessment'),
    ),
    body: FutureBuilder<List<SavedAssessment>>(
      future: _history,
      builder: (context, snapshot) {
        final records = snapshot.data ?? const <SavedAssessment>[];
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          children: [
            _PatientSummary(patient: _patient),
            const SizedBox(height: 18),
            Text(
              'Assessment history',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 10),
            if (snapshot.connectionState != ConnectionState.done)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (records.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'No assessments yet. Start the first consultation.',
                  ),
                ),
              )
            else ...[
              _ProgressSummary(records: records),
              const SizedBox(height: 10),
              for (final record in records)
                Card(
                  child: ListTile(
                    leading: CircleAvatar(child: Text('#${record.id}')),
                    title: Text(
                      record.diagnoses.join(', '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      '${_date(record.updatedAt)}  •  BMI ${record.bmi?.toStringAsFixed(1) ?? '—'}  •  ${record.calories?.toStringAsFixed(0) ?? '—'} kcal',
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) => _recordAction(value, record),
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'open', child: Text('Open')),
                        PopupMenuItem(
                          value: 'duplicate',
                          child: Text('Duplicate'),
                        ),
                        PopupMenuItem(value: 'archive', child: Text('Archive')),
                        PopupMenuItem(value: 'delete', child: Text('Delete')),
                      ],
                    ),
                    onTap: () => _openAssessment(record),
                  ),
                ),
            ],
          ],
        );
      },
    ),
  );

  Future<void> _edit() async {
    final updated = await Navigator.push<Patient>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            PatientFormScreen(repository: widget.repository, patient: _patient),
      ),
    );
    if (updated != null) setState(() => _patient = updated);
  }

  Future<void> _newAssessment() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            AssessmentScreen(repository: widget.repository, patient: _patient),
      ),
    );
    _refresh();
  }

  Future<void> _openAssessment(
    SavedAssessment record, {
    bool duplicate = false,
  }) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => AssessmentScreen(
          repository: widget.repository,
          patient: _patient,
          settings: widget.settings,
          initialAssessment: record,
          duplicateInitialAssessment: duplicate,
        ),
      ),
    );
    _refresh();
  }

  Future<void> _recordAction(String action, SavedAssessment record) async {
    if (action == 'open') return _openAssessment(record);
    if (action == 'duplicate') return _openAssessment(record, duplicate: true);
    if (action == 'archive') {
      await widget.repository.archiveAssessment(record.id!);
      _refresh();
      return;
    }
    if (action == 'delete') {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Delete assessment?'),
          content: const Text(
            'The assessment will be moved to recoverable deleted records.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
      await widget.repository.delete(record.id!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Assessment deleted.'),
            action: SnackBarAction(
              label: 'Undo',
              onPressed: () async {
                await widget.repository.restore(record.id!);
                _refresh();
              },
            ),
          ),
        );
      }
    }
    _refresh();
  }

  Future<void> _archive() async {
    await widget.repository.archivePatient(_patient.id!);
    if (mounted) Navigator.pop(context, true);
  }
}

class _PatientSummary extends StatelessWidget {
  const _PatientSummary({required this.patient});
  final Patient patient;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            patient.displayName,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            [
              if (patient.opNumber.isNotEmpty) 'OP ${patient.opNumber}',
              if (patient.age != null) '${patient.age} years',
              patient.gender,
              if (patient.phone.isNotEmpty) patient.phone,
            ].where((value) => value.isNotEmpty).join('  •  '),
          ),
          if (patient.notes.isNotEmpty) ...[
            const Divider(height: 24),
            Text(patient.notes),
          ],
        ],
      ),
    ),
  );
}

class _ProgressSummary extends StatelessWidget {
  const _ProgressSummary({required this.records});
  final List<SavedAssessment> records;
  @override
  Widget build(BuildContext context) {
    final withBmi = records.where((record) => record.bmi != null).toList();
    final change = withBmi.length < 2
        ? null
        : withBmi.first.bmi! - withBmi.last.bmi!;
    return Card(
      color: Theme.of(
        context,
      ).colorScheme.primaryContainer.withValues(alpha: .45),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.show_chart),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                change == null
                    ? '${records.length} recorded consultation${records.length == 1 ? '' : 's'}'
                    : 'BMI change across recorded consultations: ${change >= 0 ? '+' : ''}${change.toStringAsFixed(1)}',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _date(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
