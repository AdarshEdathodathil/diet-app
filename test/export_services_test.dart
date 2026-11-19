import 'dart:convert';

import 'package:clinical_dietitian_calculator/src/csv_export_service.dart';
import 'package:clinical_dietitian_calculator/src/encrypted_backup_service.dart';
import 'package:clinical_dietitian_calculator/src/assessment_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeExportRepository extends AssessmentRepository {
  @override
  Future<List<Map<String, Object?>>> exportAssessments() async => [
    {
      'id': null,
      'patient_id': null,
      'exported_patient_id': 9,
      'patient_name': 'Patient only',
      'op_number': 'OP-9',
      'phone': '',
      'patient_notes': 'No assessment yet',
      'patient_age': 40,
      'patient_gender': 'Female',
      'patient_created_at': '2026-11-19T10:00:00',
      'patient_updated_at': '2026-11-19T10:00:00',
      'patient_archived': 0,
      'payload': null,
      'diagnoses': null,
    },
  ];
}

void main() {
  test('patient CSV is Excel-compatible and quotes text safely', () {
    final bytes = const CsvExportService().buildPatientCsv([
      {
        'id': 7,
        'name': 'Jane, "JJ"',
        'op_number': 'OP-7',
        'phone': '123',
        'age': 35,
        'gender': 'Female',
        'notes': 'First line\nSecond line',
        'assessment_count': 2,
        'last_assessment_at': '2026-11-19T10:00:00',
        'created_at': '2026-01-01T10:00:00',
        'updated_at': '2026-11-19T10:00:00',
        'archived': 0,
      },
    ]);
    expect(bytes.take(3), [0xEF, 0xBB, 0xBF]);
    final csv = utf8.decode(bytes.skip(3).toList());
    expect(csv, contains('"Jane, ""JJ"""'));
    expect(csv, contains('"First line\nSecond line"'));
  });

  test('anonymized patient CSV excludes direct identifiers', () {
    final csv = utf8.decode(
      const CsvExportService()
          .buildPatientCsv(const [], includeIdentity: false)
          .skip(3)
          .toList(),
    );
    expect(csv, isNot(contains('op_number')));
    expect(csv, isNot(contains('phone')));
    expect(csv, isNot(contains('name')));
  });

  test(
    'complete export creates one CSV and retains patients without assessments',
    () async {
      final documents = await const CsvExportService().generateAll(
        _FakeExportRepository(),
      );
      expect(documents, hasLength(1));
      expect(documents.single.name, contains('complete_patient_data'));
      final csv = utf8.decode(documents.single.bytes.skip(3).toList());
      expect(csv, contains('Patient only'));
      expect(csv, contains('No assessment yet'));
      expect(csv, isNot(contains(',null,')));
    },
  );

  test('encrypted backup round-trips and rejects a wrong password', () async {
    const service = EncryptedBackupService();
    final data = {
      'schema_version': 1,
      'patients': [
        {'id': 1, 'name': 'Private patient'},
      ],
      'assessments': <Object?>[],
    };
    final encrypted = await service.encrypt(data, 'correct-password');
    expect(encrypted, isNot(contains('Private patient')));
    expect(await service.decrypt(encrypted, 'correct-password'), data);
    expect(
      () => service.decrypt(encrypted, 'wrong-password'),
      throwsA(isA<FormatException>()),
    );
  });
}
