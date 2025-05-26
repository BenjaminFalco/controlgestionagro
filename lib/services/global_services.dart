import 'package:sqflite/sqflite.dart';
import 'sqlite_offline_sync_service.dart';

class GlobalServices {
  static late SQLiteOfflineSyncService syncService;

  static Future<void> init(Database db) async {
    syncService = SQLiteOfflineSyncService(db);
  }
}
