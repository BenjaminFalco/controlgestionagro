import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'crear_ciudad.dart';
import 'crear_serie.dart';
import 'crear_parcelas.dart';
import 'grafico_frecuencia.dart';
import '../login_screen.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final TextEditingController inputController = TextEditingController();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
  backgroundColor: Color(0xFF005A56),
  centerTitle: true,
  title: const Text(
    "Panel del Administrador",
    style: TextStyle(
      fontSize: 30,
      fontWeight: FontWeight.bold,
      color: Colors.white, 
    ),
  ),
),
      body: SafeArea(
  child: Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        children: [
          const Icon(Icons.admin_panel_settings, size: 80, color: Colors.white70),
          const SizedBox(height: 24),
          const Text(
            "¿Qué deseas hacer?",
            style: TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 20,
            crossAxisSpacing: 20,
            childAspectRatio: 1,
            children: [
              _buildSquareButton(context, "Crear Ciudad", Icons.location_city, () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const CrearCiudad()));
              }),
              _buildSquareButton(context, "Crear Serie", Icons.map, () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const CrearSerie()));
              }),
              _buildSquareButton(context, "Crear Parcelas", Icons.grid_on, () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const CrearParcelas()));
              }),
              _buildSquareButton(context, "Gráfico frecuencia", Icons.bar_chart, () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const GraficoFrecuencia()));
              }),
            ],
          ),

          const SizedBox(height: 20),

          // 🔒 Cerrar sesión
          TextButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
            child: const Text(
              "Cerrar sesión y volver al login",
              style: TextStyle(
                color: Colors.deepPurpleAccent,
                fontSize: 18,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    ),
  ),
),

    );
  }
Widget _buildSquareButton(BuildContext context, String label, IconData icon, VoidCallback onPressed) {
  return SizedBox(
    width: 150,
    height: 150,
    child: ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Color(0xFF00B140),        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 8,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 60),
          const SizedBox(height: 20),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    ),
  );
}

  Widget _buildActionButton(BuildContext context,
      {required String label, required IconData icon, required VoidCallback onPressed}) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 28),
      label: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Text(
          label,
          style: const TextStyle(fontSize: 20),
        ),
      ),
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 60),
        backgroundColor: Colors.deepPurpleAccent,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}
