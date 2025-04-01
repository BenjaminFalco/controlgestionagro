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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF005A56),
        centerTitle: true,
        title: const Text(
          "Panel del Administrador",
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          children: [
            Expanded(
              child: GridView.count(
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
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFD700), // amarillo dorado
                foregroundColor: const Color(0xFF005A56),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.logout),
              label: const Text("Volver al login"),
            ),
          ],
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
          backgroundColor: const Color(0xFF00B140),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 6,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 60),
            const SizedBox(height: 14),
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
}
