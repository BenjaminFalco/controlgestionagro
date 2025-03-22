import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'screens/admin/admin_dashboard.dart';
import 'screens/worker/worker_dashboard.dart';
import 'screens/setup_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gestión Agro',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
      ),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        } else if (snapshot.hasData) {
          return FutureBuilder<DocumentSnapshot>(
            future:
                FirebaseFirestore.instance
                    .collection('usuarios')
                    .doc(snapshot.data!.uid)
                    .get(),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              if (!userSnapshot.hasData ||
                  !userSnapshot.data!.exists ||
                  userSnapshot.data!.get('nombre') == null ||
                  userSnapshot.data!.get('rol') == null) {
                // 🔥 Si el usuario no tiene datos completos, mostrar formulario de configuración
                return const SetupScreen();
              } else {
                // 🔥 Redirigir según el rol del usuario
                String rol = userSnapshot.data!.get('rol');
                if (rol == "admin") {
                  return const AdminDashboard();
                } else {
                  return const WorkerDashboard();
                }
              }
            },
          );
        } else {
          return const Scaffold(
            body: Center(child: Text("Error de autenticación")),
          );
        }
      },
    );
  }
}
