import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

import 'saved_assessment.dart';

class AssessmentRepository {
  Database? _database;

  Future<Database> get _db async {
    if (_database != null) return _database!;
    final root = await getDatabasesPath();
    _database = await openDatabase(
      path.join(root, 'clinical_dietitian.db'),
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE assessments (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            age INTEGER NOT NULL,
            gender TEXT NOT NULL,
            diagnoses TEXT NOT NULL,
            bmi REAL,
            calories REAL,
            approved INTEGER NOT NULL,
            payload TEXT NOT NULL
          )
        ''');
        await db.execute(
          'CREATE INDEX assessments_updated_at ON assessments(updated_at DESC)',
        );
      },
    );
    return _database!;
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

  Future<List<SavedAssessment>> search(String query) async {
    final db = await _db;
    final normalized = query.trim();
    final rows = normalized.isEmpty
        ? await db.query('assessments', orderBy: 'updated_at DESC')
        : await db.query(
            'assessments',
            where:
                'diagnoses LIKE ? OR gender LIKE ? OR CAST(age AS TEXT) LIKE ? OR CAST(id AS TEXT) LIKE ?',
            whereArgs: List.filled(4, '%$normalized%'),
            orderBy: 'updated_at DESC',
          );
    return rows.map(SavedAssessment.fromDatabaseMap).toList();
  }

  Future<void> delete(int id) async {
    final db = await _db;
    await db.delete('assessments', where: 'id = ?', whereArgs: [id]);
  }
}
