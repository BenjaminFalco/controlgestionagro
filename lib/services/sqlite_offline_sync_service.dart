import 'package:sqflite/sqflite.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:controlgestionagro/models/users_local.dart';

class SQLiteOfflineSyncService {
  final Database db;

  SQLiteOfflineSyncService(this.db);

  /// 🔄 Descarga colección (Firestore ➜ SQLite)
  Future<void> fetchAndCacheCollection({
    required String firestorePath,
    required String tableName,
    required String Function(DocumentSnapshot doc) docIdFn,
    required Map<String, dynamic> Function(DocumentSnapshot doc) mapFn,
  }) async {
    final connected = await _hasConnection();
    if (!connected) return;

    try {
      final snapshot =
          await FirebaseFirestore.instance.collection(firestorePath).get();
      final batch = db.batch();

      for (var doc in snapshot.docs) {
        final data = mapFn(doc);
        data['isSynced'] = 1; // Marcamos como sincronizado
        data['timestamp'] = DateTime.now().toIso8601String();

        batch.insert(
          tableName,
          data,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      await batch.commit(noResult: true);
      print("✅ Colección '$firestorePath' cacheada en '$tableName'");
    } catch (e) {
      print("❌ Error cacheando '$firestorePath': $e");
    }
  }

  Future<UsuarioLocal?> getUsuarioLocal() async {
    final result = await db.query('usuarios_locales', limit: 1);
    if (result.isNotEmpty) {
      return UsuarioLocal.fromMap(result.first);
    }
    return null;
  }

  /// 📥 Guardar local y marcar como pendiente (isSynced = 0)
  Future<void> guardarPendiente({
    required String tableName,
    required Map<String, dynamic> data,
  }) async {
    final enriched = {
      ...data,
      'isSynced': 0,
      'timestamp': DateTime.now().toIso8601String(),
    };

    try {
      await db.insert(
        tableName,
        enriched,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      print("💾 Guardado pendiente en '$tableName'");
    } catch (e) {
      print("❌ Error guardando en '$tableName': $e");
    }
  }

  /// 🔁 Subir todo lo pendiente (SQLite ➜ Firestore)
  Future<void> sincronizarPendientes({
    required String tableName,
    required String idFieldName,
    required String Function(Map<String, dynamic>)
    parentPathBuilder, // Nueva función
  }) async {
    final connected = await _hasConnection();
    if (!connected) return;

    try {
      final rows = await db.query(tableName, where: 'isSynced = 0');
      final firestore = FirebaseFirestore.instance;

      for (final row in rows) {
        final docId = row[idFieldName];
        if (docId == null || (docId is String && docId.isEmpty)) continue;

        try {
          final parentPath = parentPathBuilder(row);
          await firestore.collection(parentPath).doc(docId.toString()).set(row);

          await db.update(
            tableName,
            {'isSynced': 1},
            where: '$idFieldName = ?',
            whereArgs: [docId],
          );

          print("✅ Sincronizado: $parentPath/$docId");
        } catch (e) {
          print("❌ Error sincronizando $docId: $e");
        }
      }
    } catch (e) {
      print("❌ Error general al sincronizar '$tableName': $e");
    }
  }

  /// 🌐 Verifica conexión
  Future<bool> _hasConnection() async {
    final connectivity = await Connectivity().checkConnectivity();
    return connectivity != ConnectivityResult.none;
  }
}
