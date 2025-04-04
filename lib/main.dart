import 'package:controlgestionagro/screens/setup_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'firebase_options.dart';
import 'screens/loading_screen.dart';
import 'screens/login_screen.dart';
import 'package:controlgestionagro/screens/worker/inicio_tratamiento.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🔹 Inicializa Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // 🔹 Inicializa Hive para almacenamiento offline
  await Hive.initFlutter();
  await Hive.openBox('offline_data');

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

    // 🔄 Escucha cambios de conexión para futuras sincronizaciones
    _connectivity.onConnectivityChanged.listen((result) {
      if (result != ConnectivityResult.none) {
        print("📶 Conexión disponible. Puedes sincronizar.");
        // TODO: sincronizar datos Hive -> Firestore si hay cambios pendientes
      } else {
        print("⚠️ Sin conexión. Modo offline activado.");
      }
    });
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

// 🔥 Verifica si el usuario está autenticado
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingScreen(); // Pantalla de carga
        } else if (snapshot.hasData) {
          return const SetupScreen(); // Usuario autenticado -> Menú principal
        } else {
          return const LoginScreen(); // Usuario no autenticado -> Login
        }
      },
    );
  }
}
