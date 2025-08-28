// lib/core/data/repositories/cache_repository_impl.dart

import 'package:screenpledge/core/domain/entities/daily_result.dart';
import 'package:screenpledge/core/domain/entities/goal.dart';
import 'package:screenpledge/core/domain/entities/profile.dart';
import 'package:screenpledge/core/domain/repositories/cache_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// The concrete implementation of the [ICacheRepository] contract.
///
/// This class handles the actual logic of saving and retrieving data from the
/// device's local storage, using a combination of SharedPreferences for simple
/// key-value data and SQLite for structured, queryable data.
class CacheRepositoryImpl implements ICacheRepository {
  // --- Constants for SharedPreferences keys ---
  static const String _profileKey = 'cached_profile';
  static const String _activeGoalKey = 'cached_active_goal';
  static const String _pendingGoalKey = 'cached_pending_goal';

  // --- SQLite Database Helper ---
  static Database? _database;

  /// A getter for the SQLite database instance.
  /// If the database is not yet initialized, it will be opened/created.
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  /// Initializes the SQLite database.
  /// Creates the 'daily_results' table if it doesn't exist.
  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'screenpledge_cache.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE daily_results (
            date TEXT PRIMARY KEY,
            outcome TEXT,
            timeSpent INTEGER,
            timeLimit INTEGER
          )
        ''');
      },
    );
  }

  // --- Profile Implementation ---

  @override
  Future<void> saveProfile(Profile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_profileKey, profile.toJson());
  }

  @override
  Future<Profile?> getProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_profileKey);
    if (jsonString != null) {
      return Profile.fromJson(jsonString);
    }
    return null;
  }

  @override
  Future<void> clearProfile() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_profileKey);
  }

  // --- Goal Implementation ---

  @override
  Future<void> saveActiveGoal(Goal goal) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_activeGoalKey, goal.toJson());
  }

  @override
  Future<Goal?> getActiveGoal() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_activeGoalKey);
    if (jsonString != null) {
      return Goal.fromJson(jsonString);
    }
    return null;
  }

  @override
  Future<void> savePendingGoal(Goal goal) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pendingGoalKey, goal.toJson());
  }

  @override
  Future<Goal?> getPendingGoal() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_pendingGoalKey);
    if (jsonString != null) {
      return Goal.fromJson(jsonString);
    }
    return null;
  }

  @override
  Future<void> clearGoals() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_activeGoalKey);
    await prefs.remove(_pendingGoalKey);
  }

  // --- Daily Results Implementation (SQLite) ---

  @override
  Future<void> saveDailyResults(List<DailyResult> results) async {
    final db = await database;
    // Use a batch to perform multiple operations atomically for efficiency.
    final batch = db.batch();
    // Clear the old data first to ensure the cache is always fresh.
    batch.delete('daily_results');
    // Insert each new result.
    for (final result in results) {
      batch.insert(
        'daily_results',
        // Convert the DailyResult object to a map for the database.
        {
          'date': result.date.toIso8601String(),
          'outcome': result.outcome.name,
          'timeSpent': result.timeSpent.inSeconds,
          'timeLimit': result.timeLimit.inSeconds,
        },
        // If a result for the same date already exists, replace it.
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  @override
  Future<List<DailyResult>> getDailyResults({int limit = 7}) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'daily_results',
      orderBy: 'date DESC', // Get the most recent results first.
      limit: limit,
    );
    // Convert the list of maps from the database into a list of DailyResult objects.
    return List.generate(maps.length, (i) {
      return DailyResult(
        date: DateTime.parse(maps[i]['date']),
        outcome: DailyOutcome.values.byName(maps[i]['outcome']),
        timeSpent: Duration(seconds: maps[i]['timeSpent']),
        timeLimit: Duration(seconds: maps[i]['timeLimit']),
      );
    });
  }

  @override
  Future<void> clearDailyResults() async {
    final db = await database;
    await db.delete('daily_results');
  }
}