import 'dart:convert';

import 'package:csv/csv.dart';

import 'assessment_repository.dart';

class CsvExportDocument {
  const CsvExportDocument({required this.name, required this.bytes});

  final String name;
  final List<int> bytes;
}

class CsvExportService {
  const CsvExportService();

  Future<List<CsvExportDocument>> generateAll(
    AssessmentRepository repository, {
    bool includeIdentity = true,
  }) async {
    final assessments = await repository.exportAssessments();
    final stamp = _stamp(DateTime.now());
    return [
      CsvExportDocument(
        name: 'dt_haritha_complete_patient_data_$stamp.csv',
        bytes: buildAssessmentCsv(
          assessments,
          includeIdentity: includeIdentity,
        ),
      ),
    ];
  }

  List<int> buildPatientCsv(
    List<Map<String, Object?>> records, {
    bool includeIdentity = true,
  }) => _encode(_patientRows(records, includeIdentity: includeIdentity));

  List<int> buildAssessmentCsv(
    List<Map<String, Object?>> records, {
    bool includeIdentity = true,
  }) => _encode(_assessmentRows(records, includeIdentity: includeIdentity));

  List<List<dynamic>> _patientRows(
    List<Map<String, Object?>> records, {
    required bool includeIdentity,
  }) {
    final header = <dynamic>[
      'schema_version',
      'patient_id',
      if (includeIdentity) ...['name', 'op_number', 'phone'],
      'age',
      'gender',
      'patient_notes',
      'assessment_count',
      'last_assessment_at',
      'created_at',
      'updated_at',
      'archived',
    ];
    return [
      header,
      for (final row in records)
        [
          '1',
          row['id'],
          if (includeIdentity) ...[row['name'], row['op_number'], row['phone']],
          row['age'],
          row['gender'],
          row['notes'],
          row['assessment_count'],
          row['last_assessment_at'],
          row['created_at'],
          row['updated_at'],
          row['archived'],
        ],
    ];
  }

  List<List<dynamic>> _assessmentRows(
    List<Map<String, Object?>> records, {
    required bool includeIdentity,
  }) {
    const payloadFields = [
      'height',
      'weight',
      'targetBmi',
      'manualIbw',
      'calorieMethod',
      'calorieBasis',
      'calorieCustomWeight',
      'calorieFactor',
      'activityFactor',
      'proteinBasis',
      'proteinCustomWeight',
      'proteinFactor',
      'choPercent',
      'fibre',
      'waterBasis',
      'waterCustomWeight',
      'waterFactor',
      'manualWater',
      'calculatedIbwKg',
      'bmrKcal',
      'proteinGrams',
      'carbohydrateGrams',
      'fatGrams',
      'waterMl',
      'macroEnergyKcal',
      'macroDifferenceKcal',
      'warnings',
      'approvalTimestamp',
      'notes',
    ];
    return [
      [
        'schema_version',
        'assessment_id',
        'patient_id',
        if (includeIdentity) ...['patient_name', 'op_number', 'phone'],
        'patient_notes',
        'patient_created_at',
        'patient_updated_at',
        'patient_archived',
        'age',
        'gender',
        'diagnoses',
        'bmi',
        'calories_kcal_day',
        ...payloadFields,
        'approved',
        'created_at',
        'updated_at',
        'assessment_archived',
      ],
      for (final row in records)
        _assessmentRow(row, payloadFields, includeIdentity: includeIdentity),
    ];
  }

  List<dynamic> _assessmentRow(
    Map<String, Object?> row,
    List<String> payloadFields, {
    required bool includeIdentity,
  }) {
    final payloadSource = row['payload'];
    final payload = payloadSource is String
        ? (jsonDecode(payloadSource) as Map).cast<String, dynamic>()
        : <String, dynamic>{};
    final diagnosesSource = row['diagnoses'];
    final diagnoses = diagnosesSource is String
        ? (jsonDecode(diagnosesSource) as List).join('; ')
        : '';
    return [
      '1',
      row['id'],
      row['patient_id'] ?? row['exported_patient_id'],
      if (includeIdentity) ...[
        row['patient_name'],
        row['op_number'],
        row['phone'],
      ],
      row['patient_notes'],
      row['patient_created_at'],
      row['patient_updated_at'],
      row['patient_archived'],
      row['age'] ?? row['patient_age'],
      row['gender'] ?? row['patient_gender'],
      diagnoses,
      row['bmi'],
      row['calories'],
      for (final field in payloadFields)
        payload[field] is List
            ? (payload[field] as List).join('; ')
            : payload[field],
      row['approved'],
      row['created_at'],
      row['updated_at'],
      row['archived'],
    ];
  }

  List<int> _encode(List<List<dynamic>> rows) {
    final csv = const ListToCsvConverter(convertNullTo: '').convert(rows);
    return [0xEF, 0xBB, 0xBF, ...utf8.encode(csv)];
  }

  String _stamp(DateTime value) =>
      '${value.year}${_two(value.month)}${_two(value.day)}_${_two(value.hour)}${_two(value.minute)}';

  String _two(int value) => value.toString().padLeft(2, '0');
}
