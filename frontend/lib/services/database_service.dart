import 'dart:async';
import 'dart:convert';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/analysis_result.dart';

/// Service for managing local SQLite database for diagnosis history (US24).
class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;

  factory DatabaseService() => _instance;

  DatabaseService._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'cropaid_history.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE diagnosis_history (
        id TEXT PRIMARY KEY,
        date TEXT,
        imageUrl TEXT,
        crop TEXT,
        disease TEXT,
        confidence REAL,
        severity TEXT,
        fullResult TEXT
      )
    ''');
  }

  /// Saves an [AnalysisResult] to the history.
  Future<void> saveDiagnosis(AnalysisResult result) async {
    final db = await database;
    await db.insert(
      'diagnosis_history',
      {
        'id': result.id,
        'date': result.date.toIso8601String(),
        'imageUrl': result.imageUrl,
        'crop': result.crop,
        'disease': result.disease,
        'confidence': result.confidence,
        'severity': result.severity,
        'fullResult': jsonEncode(result.toJson()),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    // Limit to 20 most recent (US Requirement)
    final count = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM diagnosis_history'));
    if (count != null && count > 20) {
      // Find the oldest entries to delete
      await db.execute('''
        DELETE FROM diagnosis_history 
        WHERE id IN (
          SELECT id FROM diagnosis_history 
          ORDER BY date ASC 
          LIMIT ?
        )
      ''', [count - 20]);
    }
  }

  /// Retrieves all saved diagnoses, sorted by date (newest first).
  Future<List<AnalysisResult>> getAllDiagnoses() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'diagnosis_history',
      orderBy: 'date DESC',
    );

    return List.generate(maps.length, (i) {
      return AnalysisResult.fromJson(jsonDecode(maps[i]['fullResult']));
    });
  }

  /// Deletes a specific diagnosis from history.
  Future<void> deleteDiagnosis(String id) async {
    final db = await database;
    await db.delete(
      'diagnosis_history',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Clears all history.
  Future<void> clearAllHistory() async {
    final db = await database;
    await db.delete('diagnosis_history');
  }
}

final databaseService = DatabaseService();
