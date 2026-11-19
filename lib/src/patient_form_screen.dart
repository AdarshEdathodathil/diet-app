import 'package:flutter/material.dart';

import 'assessment_repository.dart';
import 'patient.dart';

class PatientFormScreen extends StatefulWidget {
  const PatientFormScreen({super.key, required this.repository, this.patient});
  final AssessmentRepository repository;
  final Patient? patient;

  @override
  State<PatientFormScreen> createState() => _PatientFormScreenState();
}

class _PatientFormScreenState extends State<PatientFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.patient?.name ?? '');
  late final _op = TextEditingController(text: widget.patient?.opNumber ?? '');
  late final _phone = TextEditingController(text: widget.patient?.phone ?? '');
  late final _age = TextEditingController(
    text: widget.patient?.age?.toString() ?? '',
  );
  late final _notes = TextEditingController(text: widget.patient?.notes ?? '');
  late String _gender = widget.patient?.gender ?? '';
  bool _saving = false;

  @override
  void dispose() {
    for (final controller in [_name, _op, _phone, _age, _notes]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.patient == null ? 'New patient' : 'Edit patient'),
    ),
    body: Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Patient profile',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 6),
          const Text(
            'Use a name or OP number so repeat consultations can be linked safely.',
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _name,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Patient name (optional)',
            ),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _op,
            decoration: const InputDecoration(
              labelText: 'Hospital / OP number',
            ),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Phone number (optional)',
            ),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _age,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Age',
              suffixText: 'years',
            ),
            validator: (value) {
              final age = int.tryParse(value?.trim() ?? '');
              if (age == null || age < 1 || age > 120) {
                return 'Enter an age from 1 to 120.';
              }
              return null;
            },
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            initialValue: _gender.isEmpty ? null : _gender,
            decoration: const InputDecoration(labelText: 'Gender'),
            items: const [
              DropdownMenuItem(value: 'Male', child: Text('Male')),
              DropdownMenuItem(value: 'Female', child: Text('Female')),
            ],
            validator: (value) => value == null ? 'Select a gender.' : null,
            onChanged: (value) => _gender = value ?? '',
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _notes,
            minLines: 3,
            maxLines: 6,
            decoration: const InputDecoration(
              labelText: 'Patient notes (optional)',
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_outlined),
            label: const Text('Save patient'),
          ),
        ],
      ),
    ),
  );

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final now = DateTime.now();
    final patient = Patient(
      id: widget.patient?.id,
      createdAt: widget.patient?.createdAt ?? now,
      updatedAt: now,
      name: _name.text,
      opNumber: _op.text,
      phone: _phone.text,
      age: int.parse(_age.text.trim()),
      gender: _gender,
      notes: _notes.text,
      archived: widget.patient?.archived ?? false,
    );
    try {
      final id = await widget.repository.savePatient(patient);
      if (!mounted) return;
      Navigator.pop(context, patient.copyWith(id: id));
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not save the patient. Check that the OP number is unique.',
          ),
        ),
      );
    }
  }
}
