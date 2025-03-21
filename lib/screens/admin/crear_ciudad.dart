import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class CrearCiudad extends StatefulWidget {
  const CrearCiudad({super.key});

  @override
  State<CrearCiudad> createState() => _CrearCiudadState();
}

class _CrearCiudadState extends State<CrearCiudad> {
  final TextEditingController ciudadController = TextEditingController();
  String mensaje = '';

  Future<void> guardarCiudad() async {
    final nombreCiudad = ciudadController.text.trim();

    if (nombreCiudad.isEmpty) {
      setState(() {
        mensaje = "⚠️ Debes ingresar un nombre de ciudad.";
      });
      return;
    }

    try {
      // Crear documento en colección 'ciudades'
      await FirebaseFirestore.instance.collection('ciudades').add({
        "nombre": nombreCiudad,
        "fecha_creacion": FieldValue.serverTimestamp(),
      });

      setState(() {
        mensaje = "✅ Ciudad '$nombreCiudad' creada exitosamente.";
        ciudadController.clear();
      });
    } catch (e) {
      setState(() {
        mensaje = "❌ Error al crear ciudad: ${e.toString()}";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Crear Ciudad")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: ciudadController,
              decoration: const InputDecoration(
                labelText: "Nombre de la ciudad",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: guardarCiudad,
              child: const Text("Guardar Ciudad"),
            ),
            const SizedBox(height: 16),
            Text(mensaje),
          ],
        ),
      ),
    );
  }
}
