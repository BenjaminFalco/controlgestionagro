import 'package:controlgestionagro/screens/setup_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'screens/loading_screen.dart';
import 'screens/login_screen.dart';
import 'package:controlgestionagro/screens/worker/inicio_tratamiento.dart';
import 'package:controlgestionagro/models/users_local.dart';
import 'screens/admin/admin_dashboard.dart';
import 'screens/worker/inicio_tratamiento.dart';
import 'package:controlgestionagro/services/sqlite_offline_sync_service.dart';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'services/global_services.dart';

import 'package:controlgestionagro/services/db_setup.dart';

/// 🔄 Escucha el estado de conexión para fines de depuración o sincronización
/// 🔄 Escucha el estado de conexión para fines de depuración o sincronización

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🔹 Inicializa Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );
  Future<UsuarioLocal?> getUsuarioLocal() async {
    final db = GlobalServices.syncService.db;
    try {
      final result = await db.query('usuarios_locales', limit: 1);
      if (result.isNotEmpty) {
        return UsuarioLocal.fromMap(result.first);
      }
    } catch (e) {
      print('❌ Error obteniendo usuario local: $e');
    }
    return null;
  }

  Future<void> sincronizarPendientesSeries() async {
    final connected = await Connectivity().checkConnectivity();
    if (connected == ConnectivityResult.none) return;

    final db = GlobalServices.syncService.db;
    final usuario = await getUsuarioLocal();
    final uid = usuario?.uid ?? 'default';

    final pendientes = await db.query(
      'series',
      where: 'isSynced = 0 AND uid = ?',
      whereArgs: [uid],
    );

    for (final row in pendientes) {
      final ciudadId = row['ciudadId']?.toString() ?? '';
      final serieId = row['serieId']?.toString() ?? '';
      final superficie = row['superficie']?.toString() ?? '10';

      try {
        await FirebaseFirestore.instance
            .collection('ciudades')
            .doc(ciudadId)
            .collection('series')
            .doc(serieId)
            .update({'superficie': superficie});

        await db.update(
          'series',
          {'isSynced': 1},
          where: 'serieId = ? AND ciudadId = ? AND uid = ?',
          whereArgs: [serieId, ciudadId, uid],
        );

        print("✅ Sincronizada serie $serieId");
      } catch (e) {
        print("❌ Error al sincronizar $serieId: $e");
      }
    }
  }

  // 🔹 Inicializa SQLite con estructura completa
  final dbPath = await getDatabasesPath();
  final db = await openDatabase(
    join(dbPath, 'agro.db'),
    version: 1,
    onCreate: (db, version) async {
      await crearTablas(db);
    },
  );

  // 🔹 Inicializa servicio global con esa base
  await GlobalServices.init(db);

  final currentUser = FirebaseAuth.instance.currentUser;

  bool _conexionMonitorIniciado = false;

  void monitorConexion() {
    if (_conexionMonitorIniciado) return;
    _conexionMonitorIniciado = true;

    Connectivity().onConnectivityChanged.listen((result) async {
      if (result != ConnectivityResult.none) {
        final syncService = SQLiteOfflineSyncService(
          GlobalServices.syncService.db,
        );

        // ✅ Corregido: se llama desde GlobalServices
        final usuario = await GlobalServices.syncService.getUsuarioLocal();
        final uid = usuario?.uid ?? 'default';
        final ciudadId = usuario?.ciudad ?? '';

        if (ciudadId.isEmpty) {
          print('⚠️ No se pudo sincronizar: ciudadId no disponible.');
          return;
        }

        await syncService.sincronizarPendientes(
          tableName: 'series',
          idFieldName: 'serieId',
          parentPathBuilder: (row) => 'ciudades/${row['ciudadId']}/series',
        );

        await syncService.sincronizarPendientes(
          tableName: 'bloques',
          idFieldName: 'bloqueId',
          parentPathBuilder:
              (row) =>
                  'ciudades/${row['ciudadId']}/series/${row['serieId']}/bloques',
        );

        await syncService.sincronizarPendientes(
          tableName: 'parcelas',
          idFieldName: 'parcelaId',
          parentPathBuilder:
              (row) =>
                  'ciudades/${row['ciudadId']}/series/${row['serieId']}/bloques/${row['bloqueId']}/parcelas',
        );

        await syncService.sincronizarPendientes(
          tableName: 'tratamientos_actual',
          idFieldName: 'parcelaId',
          parentPathBuilder:
              (row) =>
                  'ciudades/${row['ciudadId']}/series/${row['serieId']}/bloques/${row['bloqueId']}/parcelas/${row['parcelaId']}/tratamientos_actual',
        );
      }
    });
  }

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final Connectivity _connectivity = Connectivity();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Firebase',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        scaffoldBackgroundColor: const Color.fromARGB(255, 10, 9, 49),
        inputDecorationTheme: const InputDecorationTheme(
          filled: true,
          fillColor: Colors.black12,
          border: OutlineInputBorder(),
          labelStyle: TextStyle(color: Colors.white70),
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const AuthWrapper(),
        '/inicio_tratamiento': (context) => const InicioTratamientoScreen(),
      },
    );
  }
}

// 🔐 Verifica si el usuario está autenticado
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: _determinarPantallaInicial(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingScreen();
        }

        if (snapshot.hasError) {
          return const LoginScreen(); // fallback en error
        }

        return snapshot.data ?? const LoginScreen(); // fallback
      },
    );
  }

  Future<Widget> _determinarPantallaInicial() async {
    final user = FirebaseAuth.instance.currentUser;

    try {
      final db = GlobalServices.syncService.db;
      final local = await db.query('usuarios_locales', limit: 1);
      final usuario =
          local.isNotEmpty ? UsuarioLocal.fromMap(local.first) : null;

      // 🔁 Si es anónimo y tiene rol operador → va directo a inicio_tratamiento
      if (user != null && user.isAnonymous && usuario?.rol == 'operador') {
        return const InicioTratamientoScreen();
      }

      // 🟢 Usuario con cuenta pero aún no completó setup → ir a Setup
      if (user != null &&
          (usuario == null || usuario.rol.isEmpty || usuario.nombre.isEmpty)) {
        return const SetupScreen();
      }

      // ✅ Usuario completo → Admin o Trabajador
      if (user != null && usuario != null) {
        return usuario.rol == 'admin'
            ? const AdminDashboard()
            : const InicioTratamientoScreen();
      }
    } catch (e) {
      print("❌ Error en _determinarPantallaInicial: $e");
    }

    // ❌ Ningún caso aplica → ir a LoginScreen
    return const LoginScreen();
  }
}
