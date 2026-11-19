import 'dart:convert';

class SavedAssessment {
  const SavedAssessment({
    this.id,
    this.patientId,
    required this.createdAt,
    required this.updatedAt,
    required this.age,
    required this.gender,
    required this.diagnoses,
    required this.bmi,
    required this.calories,
    required this.approved,
    required this.payload,
  });

  final int? id;
  final int? patientId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int age;
  final String gender;
  final List<String> diagnoses;
  final double? bmi;
  final double? calories;
  final bool approved;
  final Map<String, dynamic> payload;

  Map<String, Object?> toDatabaseMap() => {
    'patient_id': patientId,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
    'age': age,
    'gender': gender,
    'diagnoses': jsonEncode(diagnoses),
    'bmi': bmi,
    'calories': calories,
    'approved': approved ? 1 : 0,
    'payload': jsonEncode(payload),
  };

  factory SavedAssessment.fromDatabaseMap(Map<String, Object?> map) {
    return SavedAssessment(
      id: map['id'] as int,
      patientId: map['patient_id'] as int?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      age: map['age'] as int,
      gender: map['gender'] as String,
      diagnoses: (jsonDecode(map['diagnoses'] as String) as List)
          .cast<String>(),
      bmi: (map['bmi'] as num?)?.toDouble(),
      calories: (map['calories'] as num?)?.toDouble(),
      approved: map['approved'] == 1,
      payload: (jsonDecode(map['payload'] as String) as Map)
          .cast<String, dynamic>(),
    );
  }
}
