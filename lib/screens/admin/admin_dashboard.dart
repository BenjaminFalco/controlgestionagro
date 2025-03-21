import 'package:flutter/material.dart';
import 'crear_ciudad.dart';
import 'crear_serie.dart';
import 'crear_parcelas.dart';
import 'grafico_frecuencia.dart'; // Asegúrate de importar la pantalla del gráfico

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Administrador - Gestión de Datos")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CrearCiudad()),
                );
              },
              icon: const Icon(Icons.location_city),
              label: const Text("Crear Ciudad"),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CrearSerie()),
                );
              },
              icon: const Icon(Icons.map),
              label: const Text("Crear Serie en Ciudad"),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CrearParcelas()),
                );
              },
              icon: const Icon(Icons.grid_on),
              label: const Text("Crear Parcelas en Serie"),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const GraficoFrecuencia()),
                );
              },
              icon: const Icon(Icons.bar_chart),
              label: const Text("Ver gráfico de frecuencia"),
            ),
          ],
        ),
      ),
    );
  }
}
