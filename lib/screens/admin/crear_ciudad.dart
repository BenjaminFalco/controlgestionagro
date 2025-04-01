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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF005A56), // Azul petróleo IANSA
        centerTitle: true,
        elevation: 0,
        title: const Text(
          "Crear Ciudad",
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 350),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  "Nombre de la ciudad",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF004D4C),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: ciudadController,
                  style: const TextStyle(fontSize: 18, color: Colors.black),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                    hintText: "Ej: Chillán, San Carlos, Los Ángeles...",
                    hintStyle: const TextStyle(color: Colors.black45),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.black),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.black),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFF005A56), width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: guardarCiudad,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00B140), // Verde IANSA
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(fontSize: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text("Guardar Ciudad"),
                ),
                const SizedBox(height: 20),
                if (mensaje.isNotEmpty)
                  Text(
                    mensaje,
                    style: TextStyle(
                      fontSize: 16,
                      color: mensaje.startsWith("✅")
                          ? Colors.green
                          : mensaje.startsWith("⚠️")
                              ? Colors.orange
                              : Colors.red,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
