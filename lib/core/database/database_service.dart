import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseService {
  final bool inMemory;
  Database? _database;

  DatabaseService({this.inMemory = false});

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final String path;
    if (inMemory) {
      path = inMemoryDatabasePath;
    } else {
      final dbPath = await getDatabasesPath();
      path = join(dbPath, 'library_of_mysteries.db');
    }

    final db = await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
    await db.execute('PRAGMA foreign_keys = ON');
    return db;
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE documents (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        file_path TEXT NOT NULL,
        type TEXT NOT NULL,
        cover_path TEXT,
        progress REAL DEFAULT 0.0
      )
    ''');
  }
}
