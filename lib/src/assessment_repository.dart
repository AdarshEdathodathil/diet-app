import 'dart:convert';

import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

import 'patient.dart';
import 'saved_assessment.dart';

class DashboardStats {
  const DashboardStats({
    required this.patients,
    required this.assessments,
    required this.drafts,
  });
  final int patients;
  final int assessments;
  final int drafts;
}

class AssessmentPreset {
  const AssessmentPreset({this.id, required this.name, required this.values});
  final int? id;
  final String name;
  final Map<String, dynamic> values;
}

class AssessmentRepository {
  Database? _database;

  Future<Database> get _db async {
    if (_database != null) return _database!;
    final root = await getDatabasesPath();
    _database = await openDatabase(
      path.join(root, 'clinical_dietitian.db'),
      version: 3,
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: (db, version) async => _createSchema(db),
      onUpgrade: _upgrade,
    );
    return _database!;
  }

  Future<void> _createSchema(Database db) async {
    await db.execute('''
      CREATE TABLE patients (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        name TEXT NOT NULL DEFAULT '',
        op_number TEXT NOT NULL DEFAULT '',
        phone TEXT NOT NULL DEFAULT '',
        age INTEGER,
        gender TEXT NOT NULL DEFAULT '',
        notes TEXT NOT NULL DEFAULT '',
        archived INTEGER NOT NULL DEFAULT 0
      )
    ''');
    await db.execute(
      'CREATE UNIQUE INDEX patients_op_number ON patients(op_number) WHERE op_number != \'\'',
    );
    await db.execute('''
      CREATE TABLE assessments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        patient_id INTEGER REFERENCES patients(id) ON DELETE SET NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        age INTEGER NOT NULL,
        gender TEXT NOT NULL,
        diagnoses TEXT NOT NULL,
        bmi REAL,
        calories REAL,
        approved INTEGER NOT NULL,
        archived INTEGER NOT NULL DEFAULT 0,
        deleted_at TEXT,
        payload TEXT NOT NULL
      )
    ''');
    await db.execute(
      'CREATE INDEX assessments_updated_at ON assessments(updated_at DESC)',
    );
    await db.execute(
      'CREATE INDEX assessments_patient_id ON assessments(patient_id)',
    );
    await db.execute('''
      CREATE TABLE drafts (
        draft_key TEXT PRIMARY KEY,
        updated_at TEXT NOT NULL,
        payload TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE presets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        values_json TEXT NOT NULL
      )
    ''');
  }

  Future<void> _upgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE patients (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          name TEXT NOT NULL DEFAULT '',
          op_number TEXT NOT NULL DEFAULT '',
          phone TEXT NOT NULL DEFAULT '',
          age INTEGER,
          gender TEXT NOT NULL DEFAULT '',
          notes TEXT NOT NULL DEFAULT '',
          archived INTEGER NOT NULL DEFAULT 0
        )
      ''');
      await db.execute(
        'CREATE UNIQUE INDEX patients_op_number ON patients(op_number) WHERE op_number != \'\'',
      );
      await db.execute('ALTER TABLE assessments ADD COLUMN patient_id INTEGER');
      await db.execute(
        'ALTER TABLE assessments ADD COLUMN archived INTEGER NOT NULL DEFAULT 0',
      );
      await db.execute('ALTER TABLE assessments ADD COLUMN deleted_at TEXT');
      await db.execute(
        'CREATE INDEX assessments_patient_id ON assessments(patient_id)',
      );
      final legacy = await db.query('assessments');
      for (final row in legacy) {
        final patientId = await db.insert('patients', {
          'created_at': row['created_at'],
          'updated_at': row['updated_at'],
          'age': row['age'],
          'gender': row['gender'],
          'name': '',
          'op_number': '',
          'phone': '',
          'notes': 'Migrated from assessment #${row['id']}',
          'archived': 0,
        });
        await db.update(
          'assessments',
          {'patient_id': patientId},
          where: 'id = ?',
          whereArgs: [row['id']],
        );
      }
    }
    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE drafts (
          draft_key TEXT PRIMARY KEY,
          updated_at TEXT NOT NULL,
          payload TEXT NOT NULL
        )
      ''');
      await db.execute('''
        CREATE TABLE presets (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL UNIQUE,
          values_json TEXT NOT NULL
        )
      ''');
    }
  }

  Future<int> save(SavedAssessment assessment) async {
    final db = await _db;
    if (assessment.id == null) {
      return db.insert('assessments', assessment.toDatabaseMap());
    }
    await db.update(
      'assessments',
      assessment.toDatabaseMap(),
      where: 'id = ?',
      whereArgs: [assessment.id],
    );
    return assessment.id!;
  }

  Future<List<SavedAssessment>> search(
    String query, {
    bool includeArchived = false,
  }) async {
    final db = await _db;
    final normalized = query.trim();
    final archiveClause = includeArchived ? '' : 'AND a.archived = 0';
    final rows = await db.rawQuery(
      '''
      SELECT a.* FROM assessments a
      LEFT JOIN patients p ON p.id = a.patient_id
      WHERE a.deleted_at IS NULL $archiveClause
        AND (? = '' OR a.diagnoses LIKE ? OR a.gender LIKE ?
          OR CAST(a.age AS TEXT) LIKE ? OR CAST(a.id AS TEXT) LIKE ?
          OR p.name LIKE ? OR p.op_number LIKE ? OR p.phone LIKE ?)
      ORDER BY a.updated_at DESC
      ''',
      [normalized, ...List.filled(7, '%$normalized%')],
    );
    return rows.map(SavedAssessment.fromDatabaseMap).toList();
  }

  Future<List<SavedAssessment>> assessmentsForPatient(int patientId) async {
    final db = await _db;
    final rows = await db.query(
      'assessments',
      where: 'patient_id = ? AND deleted_at IS NULL',
      whereArgs: [patientId],
      orderBy: 'updated_at DESC',
    );
    return rows.map(SavedAssessment.fromDatabaseMap).toList();
  }

  Future<void> archiveAssessment(int id, {bool archived = true}) async {
    final db = await _db;
    await db.update(
      'assessments',
      {
        'archived': archived ? 1 : 0,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> delete(int id) async {
    final db = await _db;
    await db.update(
      'assessments',
      {'deleted_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> restore(int id) async {
    final db = await _db;
    await db.update(
      'assessments',
      {'deleted_at': null},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> savePatient(Patient patient) async {
    final db = await _db;
    if (patient.id == null) {
      return db.insert('patients', patient.toDatabaseMap());
    }
    await db.update(
      'patients',
      patient.toDatabaseMap(),
      where: 'id = ?',
      whereArgs: [patient.id],
    );
    return patient.id!;
  }

  Future<List<Patient>> searchPatients(
    String query, {
    bool includeArchived = false,
  }) async {
    final db = await _db;
    final q = query.trim();
    final rows = await db.query(
      'patients',
      where:
          '${includeArchived ? '1 = 1' : 'archived = 0'} AND (? = \'\' OR name LIKE ? OR op_number LIKE ? OR phone LIKE ?)',
      whereArgs: [q, ...List.filled(3, '%$q%')],
      orderBy: 'updated_at DESC',
    );
    return rows.map(Patient.fromDatabaseMap).toList();
  }

  Future<Patient?> patientById(int id) async {
    final db = await _db;
    final rows = await db.query('patients', where: 'id = ?', whereArgs: [id]);
    return rows.isEmpty ? null : Patient.fromDatabaseMap(rows.first);
  }

  Future<void> archivePatient(int id, {bool archived = true}) async {
    final db = await _db;
    await db.update(
      'patients',
      {
        'archived': archived ? 1 : 0,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<DashboardStats> dashboardStats() async {
    final db = await _db;
    final patientCount =
        Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM patients WHERE archived = 0'),
        ) ??
        0;
    final assessmentCount =
        Sqflite.firstIntValue(
          await db.rawQuery(
            'SELECT COUNT(*) FROM assessments WHERE archived = 0 AND deleted_at IS NULL',
          ),
        ) ??
        0;
    final draftCount =
        Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM drafts'),
        ) ??
        0;
    return DashboardStats(
      patients: patientCount,
      assessments: assessmentCount,
      drafts: draftCount,
    );
  }

  Future<void> saveDraft(String key, Map<String, dynamic> payload) async {
    final db = await _db;
    await db.insert('drafts', {
      'draft_key': key,
      'updated_at': DateTime.now().toIso8601String(),
      'payload': jsonEncode(payload),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Map<String, dynamic>?> loadDraft(String key) async {
    final db = await _db;
    final rows = await db.query(
      'drafts',
      where: 'draft_key = ?',
      whereArgs: [key],
    );
    if (rows.isEmpty) return null;
    return (jsonDecode(rows.first['payload'] as String) as Map)
        .cast<String, dynamic>();
  }

  Future<void> deleteDraft(String key) async {
    final db = await _db;
    await db.delete('drafts', where: 'draft_key = ?', whereArgs: [key]);
  }

  Future<List<AssessmentPreset>> presets() async {
    final db = await _db;
    final rows = await db.query('presets', orderBy: 'name COLLATE NOCASE');
    return rows
        .map(
          (row) => AssessmentPreset(
            id: row['id'] as int,
            name: row['name'] as String,
            values: (jsonDecode(row['values_json'] as String) as Map)
                .cast<String, dynamic>(),
          ),
        )
        .toList();
  }

  Future<int> savePreset(AssessmentPreset preset) async {
    final db = await _db;
    final values = {
      'name': preset.name.trim(),
      'values_json': jsonEncode(preset.values),
    };
    if (preset.id == null) return db.insert('presets', values);
    await db.update('presets', values, where: 'id = ?', whereArgs: [preset.id]);
    return preset.id!;
  }

  Future<void> deletePreset(int id) async {
    final db = await _db;
    await db.delete('presets', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, Object?>>> exportPatients() async {
    final db = await _db;
    return db.rawQuery('''
      SELECT p.*, COUNT(a.id) AS assessment_count,
        MAX(a.updated_at) AS last_assessment_at
      FROM patients p
      LEFT JOIN assessments a ON a.patient_id = p.id AND a.deleted_at IS NULL
      GROUP BY p.id ORDER BY p.id
    ''');
  }

  Future<List<Map<String, Object?>>> exportAssessments() async {
    final db = await _db;
    return db.rawQuery('''
      SELECT a.*, p.id AS exported_patient_id,
        p.name AS patient_name, p.op_number, p.phone,
        p.notes AS patient_notes, p.age AS patient_age,
        p.gender AS patient_gender, p.created_at AS patient_created_at,
        p.updated_at AS patient_updated_at, p.archived AS patient_archived
      FROM patients p
      LEFT JOIN assessments a
        ON a.patient_id = p.id AND a.deleted_at IS NULL
      ORDER BY p.id, a.id
    ''');
  }

  Future<Map<String, dynamic>> backupData() async {
    final db = await _db;
    return {
      'schema_version': 1,
      'exported_at': DateTime.now().toUtc().toIso8601String(),
      'patients': await db.query('patients'),
      'assessments': await db.query('assessments'),
      'drafts': await db.query('drafts'),
      'presets': await db.query('presets'),
    };
  }

  Future<void> restoreBackupData(Map<String, dynamic> backup) async {
    if (backup['schema_version'] != 1 ||
        backup['patients'] is! List ||
        backup['assessments'] is! List) {
      throw const FormatException('Unsupported or invalid backup.');
    }
    final db = await _db;
    await db.transaction((transaction) async {
      await transaction.delete('assessments');
      await transaction.delete('patients');
      await transaction.delete('drafts');
      await transaction.delete('presets');
      for (final raw in backup['patients'] as List) {
        await transaction.insert(
          'patients',
          (raw as Map).cast<String, Object?>(),
        );
      }
      for (final raw in backup['assessments'] as List) {
        await transaction.insert(
          'assessments',
          (raw as Map).cast<String, Object?>(),
        );
      }
      for (final raw in (backup['drafts'] as List? ?? const [])) {
        await transaction.insert(
          'drafts',
          (raw as Map).cast<String, Object?>(),
        );
      }
      for (final raw in (backup['presets'] as List? ?? const [])) {
        await transaction.insert(
          'presets',
          (raw as Map).cast<String, Object?>(),
        );
      }
    });
  }
}
