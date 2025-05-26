import 'package:hive/hive.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class OfflineSyncService {
  /// 🔄 Descarga colección (Firestore ➜ Hive)
  static Future<List<Map<String, dynamic>>> fetchAndCacheCollection({
    required String firestorePath,
    required String hiveBoxName,
    required String hiveKey,
    required Map<String, dynamic> Function(DocumentSnapshot doc) mapFn,
  }) async {
    final connectivity = await Connectivity().checkConnectivity();
    final hayConexion = connectivity != ConnectivityResult.none;
    final box = Hive.box(hiveBoxName);

    if (hayConexion) {
      final snapshot =
          await FirebaseFirestore.instance.collection(firestorePath).get();
      final list = snapshot.docs.map((doc) => mapFn(doc)).toList();
      await box.put(hiveKey, list);
      return list;
    } else {
      final local = box.get(hiveKey) ?? [];
      return List<Map<String, dynamic>>.from(local);
    }
  }

  /// 🔄 Descarga subcolección ordenada
  static Future<List<Map<String, dynamic>>> fetchAndCacheSubcollection({
    required String firestorePath,
    required String hiveBoxName,
    required String hiveKey,
    required Map<String, dynamic> Function(DocumentSnapshot doc) mapFn,
    String orderByField = '',
  }) async {
    final connectivity = await Connectivity().checkConnectivity();
    final hayConexion = connectivity != ConnectivityResult.none;
    final box = Hive.box(hiveBoxName);

    if (hayConexion) {
      Query query = FirebaseFirestore.instance.collection(firestorePath);
      if (orderByField.isNotEmpty) query = query.orderBy(orderByField);

      final snapshot = await query.get();
      final list = snapshot.docs.map((doc) => mapFn(doc)).toList();
      await box.put(hiveKey, list);
      return list;
    } else {
      final local = box.get(hiveKey) ?? [];
      return List<Map<String, dynamic>>.from(local);
    }
  }

  /// 📥 Guardar local y marcar como pendiente
  static Future<void> guardarPendiente({
    required String boxName,
    required Map<String, dynamic> data,
  }) async {
    final box = Hive.box(boxName);
    final enriched = {
      ...data,
      'isSynced': false,
      'timestamp': DateTime.now().toIso8601String(),
    };
    await box.add(enriched);
  }

  /// 🔁 Subir todo lo pendiente en una box (Hive ➜ Firestore)
  static Future<void> sincronizarPendientes({
    required String boxName,
    required String firestoreCollection,
    String Function(Map<String, dynamic>)? docIdFromMap,
  }) async {
    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity == ConnectivityResult.none) return;

    final box = Hive.box(boxName);
    final firestore = FirebaseFirestore.instance;

    final List keys =
        box.keys.toList(); // importante: evitar modificación concurrente

    for (var key in keys) {
      final map = Map<String, dynamic>.from(box.get(key));
      if (map['isSynced'] == true) continue;

      try {
        final docRef = firestore.collection(firestoreCollection);
        final docId = docIdFromMap != null ? docIdFromMap(map) : null;

        if (docId != null && docId.isNotEmpty) {
          await docRef.doc(docId).set(map);
        } else {
          await docRef.add(map);
        }

        await box.delete(key);
        print("✅ Sincronizado: $key");
      } catch (e) {
        print("❌ Error sincronizando $key: $e");
      }
    }
  }
}
