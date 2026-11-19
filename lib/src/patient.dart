class Patient {
  const Patient({
    this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.name,
    required this.opNumber,
    required this.phone,
    required this.age,
    required this.gender,
    required this.notes,
    this.archived = false,
  });

  final int? id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String name;
  final String opNumber;
  final String phone;
  final int? age;
  final String gender;
  final String notes;
  final bool archived;

  String get displayName {
    if (name.trim().isNotEmpty) return name.trim();
    if (opNumber.trim().isNotEmpty) return 'Patient ${opNumber.trim()}';
    return id == null ? 'New patient' : 'Patient #$id';
  }

  Map<String, Object?> toDatabaseMap() => {
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
    'name': name.trim(),
    'op_number': opNumber.trim(),
    'phone': phone.trim(),
    'age': age,
    'gender': gender,
    'notes': notes.trim(),
    'archived': archived ? 1 : 0,
  };

  Patient copyWith({
    int? id,
    DateTime? updatedAt,
    String? name,
    String? opNumber,
    String? phone,
    int? age,
    String? gender,
    String? notes,
    bool? archived,
  }) => Patient(
    id: id ?? this.id,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    name: name ?? this.name,
    opNumber: opNumber ?? this.opNumber,
    phone: phone ?? this.phone,
    age: age ?? this.age,
    gender: gender ?? this.gender,
    notes: notes ?? this.notes,
    archived: archived ?? this.archived,
  );

  factory Patient.fromDatabaseMap(Map<String, Object?> map) => Patient(
    id: map['id'] as int,
    createdAt: DateTime.parse(map['created_at'] as String),
    updatedAt: DateTime.parse(map['updated_at'] as String),
    name: map['name'] as String? ?? '',
    opNumber: map['op_number'] as String? ?? '',
    phone: map['phone'] as String? ?? '',
    age: map['age'] as int?,
    gender: map['gender'] as String? ?? '',
    notes: map['notes'] as String? ?? '',
    archived: map['archived'] == 1,
  );
}
