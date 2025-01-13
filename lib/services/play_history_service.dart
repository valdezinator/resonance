import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class PlayHistoryService {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await initDatabase();
    return _database!;
  }

  Future<Database> initDatabase() async {
    String path = join(await getDatabasesPath(), 'play_history.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (Database db, int version) async {
        await db.execute('''
          CREATE TABLE play_history (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            song_id TEXT NOT NULL,
            title TEXT NOT NULL,
            artist TEXT NOT NULL,
            image_url TEXT,
            audio_url TEXT,
            played_at INTEGER NOT NULL
          )
        ''');
      },
    );
  }

  Future<void> addToHistory(Map<String, dynamic> song) async {
    final db = await database;
    await db.insert(
      'play_history',
      {
        'song_id': song['id'],
        'title': song['title'],
        'artist': song['artist'],
        'image_url': song['image_url'],
        'audio_url': song['audio_url'],
        'played_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getRecentlyPlayed({int limit = 20}) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'play_history',
      orderBy: 'played_at DESC',
      limit: limit,
    );

    return maps.map((item) {
      return {
        'songs': {
          'id': item['song_id'],
          'title': item['title'],
          'artist': item['artist'],
          'image_url': item['image_url'],
          'audio_url': item['audio_url'],
          'played_at': DateTime.fromMillisecondsSinceEpoch(item['played_at']),
        }
      };
    }).toList();
  }

  Future<void> clearHistory() async {
    final db = await database;
    await db.delete('play_history');
  }
}
