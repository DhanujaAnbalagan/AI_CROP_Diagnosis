import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path_pkg;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/reminder_model.dart';

/// Persistent storage for farmer reminders using SQLite (mobile) or SharedPreferences (web).
class ReminderService {
  static final ReminderService _instance = ReminderService._internal();
  factory ReminderService() => _instance;
  ReminderService._internal();

  Database? _db;
  static const String _tableName = 'reminders';
  static const String _prefsKey = 'web_reminders_list';

  Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final full = path_pkg.join(dbPath, 'agri_reminders.db');
    return openDatabase(
      full,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_tableName (
            id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            cropName TEXT NOT NULL,
            scheduledDate TEXT NOT NULL,
            scheduledTime TEXT NOT NULL,
            reminderType TEXT NOT NULL,
            isCompleted INTEGER DEFAULT 0
          )
        ''');
      },
    );
  }

  Future<List<ReminderModel>> _getWebReminders() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString(_prefsKey);
    if (data == null || data.isEmpty) return [];
    
    final List<dynamic> jsonList = jsonDecode(data);
    return jsonList.map((j) => ReminderModel.fromMap(j)).toList();
  }

  Future<void> _saveWebReminders(List<ReminderModel> reminders) async {
    final prefs = await SharedPreferences.getInstance();
    final String data = jsonEncode(reminders.map((r) => r.toMap()).toList());
    await prefs.setString(_prefsKey, data);
  }

  /// Insert or update a reminder.
  Future<void> upsert(ReminderModel reminder) async {
    if (kIsWeb) {
      final reminders = await _getWebReminders();
      final index = reminders.indexWhere((r) => r.id == reminder.id);
      if (index >= 0) {
        reminders[index] = reminder;
      } else {
        reminders.add(reminder);
      }
      await _saveWebReminders(reminders);
      return;
    }

    final db = await database;
    await db.insert(
      _tableName,
      reminder.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get all reminders for a specific date.
  Future<List<ReminderModel>> getForDate(DateTime date) async {
    final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    
    if (kIsWeb) {
      final reminders = await _getWebReminders();
      final filtered = reminders.where((r) => r.scheduledDate.toIso8601String().startsWith(dateStr)).toList();
      filtered.sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));
      return filtered;
    }

    final db = await database;
    final rows = await db.query(
      _tableName,
      where: "scheduledDate LIKE ?",
      whereArgs: ['$dateStr%'],
      orderBy: 'scheduledTime ASC',
    );
    return rows.map(ReminderModel.fromMap).toList();
  }

  /// Get all reminders (for calendar event markers).
  Future<List<ReminderModel>> getAll() async {
    if (kIsWeb) {
      final reminders = await _getWebReminders();
      reminders.sort((a, b) => a.scheduledDate.compareTo(b.scheduledDate));
      return reminders;
    }

    final db = await database;
    final rows = await db.query(_tableName, orderBy: 'scheduledDate ASC');
    return rows.map(ReminderModel.fromMap).toList();
  }

  /// Delete a reminder by id.
  Future<void> delete(String id) async {
    if (kIsWeb) {
      final reminders = await _getWebReminders();
      reminders.removeWhere((r) => r.id == id);
      await _saveWebReminders(reminders);
      return;
    }

    final db = await database;
    await db.delete(_tableName, where: 'id = ?', whereArgs: [id]);
  }

  /// Mark a reminder as completed.
  Future<void> markCompleted(String id) async {
    if (kIsWeb) {
      final reminders = await _getWebReminders();
      final index = reminders.indexWhere((r) => r.id == id);
      if (index >= 0) {
        reminders[index] = reminders[index].copyWith(isCompleted: true);
        await _saveWebReminders(reminders);
      }
      return;
    }

    final db = await database;
    await db.update(
      _tableName,
      {'isCompleted': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}

/// Singleton instance to use across the app.
final reminderService = ReminderService();
