import 'dart:async';

import 'package:flutter/material.dart';

import 'about_screen.dart';
import 'assessment_repository.dart';
import 'assessment_screen.dart';
import 'app_settings.dart';
import 'export_screen.dart';
import 'patient.dart';
import 'patient_detail_screen.dart';
import 'patient_form_screen.dart';
import 'saved_assessments_screen.dart';
import 'saved_assessment.dart';
import 'settings_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({
    super.key,
    required this.repository,
    required this.settings,
  });
  final AssessmentRepository repository;
  final AppSettings settings;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _search = TextEditingController();
  late Future<DashboardStats> _stats = widget.repository.dashboardStats();
  late Future<List<Patient>> _patients = widget.repository.searchPatients('');
  Timer? _searchTimer;

  @override
  void dispose() {
    _search.dispose();
    _searchTimer?.cancel();
    super.dispose();
  }

  void _refresh() => setState(() {
    _stats = widget.repository.dashboardStats();
    _patients = widget.repository.searchPatients(_search.text);
  });

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      toolbarHeight: 72,
      title: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Dt Haritha', style: TextStyle(fontWeight: FontWeight.w800)),
          Text(
            'Clinical dietitian workspace',
            style: TextStyle(fontSize: 12, color: Color(0xFFB9D8D2)),
          ),
        ],
      ),
      actions: [
        IconButton(
          tooltip: 'About Dt Haritha',
          onPressed: () => Navigator.push<void>(
            context,
            MaterialPageRoute(builder: (_) => const AboutScreen()),
          ),
          icon: const Icon(Icons.info_outline),
        ),
        IconButton(
          tooltip: 'Settings',
          onPressed: () => Navigator.push<void>(
            context,
            MaterialPageRoute(
              builder: (_) => SettingsScreen(
                settings: widget.settings,
                repository: widget.repository,
              ),
            ),
          ),
          icon: const Icon(Icons.settings_outlined),
        ),
        IconButton(
          tooltip: 'All assessments',
          onPressed: _openAssessments,
          icon: const Icon(Icons.folder_open_outlined),
        ),
        IconButton(
          tooltip: 'Export CSV',
          onPressed: () => Navigator.push<void>(
            context,
            MaterialPageRoute(
              builder: (_) => ExportScreen(repository: widget.repository),
            ),
          ),
          icon: const Icon(Icons.table_view_outlined),
        ),
      ],
    ),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: _newPatient,
      icon: const Icon(Icons.person_add_alt_1_outlined),
      label: const Text('New patient'),
    ),
    body: RefreshIndicator(
      onRefresh: () async => _refresh(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 100),
        children: [
          Text(
            'Good to see you',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 4),
          const Text(
            'Manage patients, continue consultations, or export your clinical records.',
          ),
          const SizedBox(height: 18),
          FutureBuilder<DashboardStats>(
            future: _stats,
            builder: (context, snapshot) {
              final stats = snapshot.data;
              return Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      icon: Icons.people_outline,
                      label: 'Patients',
                      value: '${stats?.patients ?? '—'}',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.assignment_outlined,
                      label: 'Assessments',
                      value: '${stats?.assessments ?? '—'}',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.edit_note_outlined,
                      label: 'Drafts',
                      value: '${stats?.drafts ?? '—'}',
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _search,
            onChanged: (_) {
              _searchTimer?.cancel();
              _searchTimer = Timer(const Duration(milliseconds: 300), () {
                if (mounted) {
                  setState(
                    () => _patients = widget.repository.searchPatients(
                      _search.text,
                    ),
                  );
                }
              });
            },
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Search name, OP number, or phone',
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Patients',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              TextButton.icon(
                onPressed: _newPatient,
                icon: const Icon(Icons.add),
                label: const Text('Add'),
              ),
            ],
          ),
          FutureBuilder<List<Patient>>(
            future: _patients,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final patients = snapshot.data ?? const <Patient>[];
              if (patients.isEmpty) {
                return const Card(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Icon(Icons.person_search_outlined, size: 42),
                        SizedBox(height: 10),
                        Text(
                          'No patients found. Add a patient to start an assessment.',
                        ),
                      ],
                    ),
                  ),
                );
              }
              return Column(
                children: [
                  for (final patient in patients)
                    Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Text(_initials(patient.displayName)),
                        ),
                        title: Text(
                          patient.displayName,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(
                          [
                            if (patient.opNumber.isNotEmpty)
                              'OP ${patient.opNumber}',
                            if (patient.age != null) '${patient.age} years',
                            patient.gender,
                          ].where((value) => value.isNotEmpty).join('  •  '),
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _openPatient(patient),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    ),
  );

  Future<void> _newPatient() async {
    final patient = await Navigator.push<Patient>(
      context,
      MaterialPageRoute(
        builder: (_) => PatientFormScreen(repository: widget.repository),
      ),
    );
    if (patient != null && mounted) await _openPatient(patient);
    _refresh();
  }

  Future<void> _openPatient(Patient patient) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => PatientDetailScreen(
          repository: widget.repository,
          patient: patient,
          settings: widget.settings,
        ),
      ),
    );
    _refresh();
  }

  Future<void> _openAssessments() async {
    final record = await Navigator.push<SavedAssessment>(
      context,
      MaterialPageRoute(
        builder: (_) => SavedAssessmentsScreen(repository: widget.repository),
      ),
    );
    if (record != null && record.patientId != null && mounted) {
      final patient = await widget.repository.patientById(record.patientId!);
      if (patient != null && mounted) {
        await Navigator.push<void>(
          context,
          MaterialPageRoute(
            builder: (_) => AssessmentScreen(
              repository: widget.repository,
              patient: patient,
              initialAssessment: record,
              settings: widget.settings,
            ),
          ),
        );
      }
    }
    _refresh();
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      child: Column(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 7),
          Text(value, style: Theme.of(context).textTheme.titleLarge),
          Text(
            label,
            maxLines: 1,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    ),
  );
}

String _initials(String value) {
  final words = value.trim().split(RegExp(r'\s+'));
  return words
      .take(2)
      .where((word) => word.isNotEmpty)
      .map((word) => word[0].toUpperCase())
      .join();
}
