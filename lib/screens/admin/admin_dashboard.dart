import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../setup_screen.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Panel de Administrador"),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // 🔥 Ir a la pantalla de configuración para editar datos
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SetupScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: const Center(
        child: Text(
          "Bienvenido, Administrador.\nAquí podrás gestionar los ensayos y trabajadores.",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
