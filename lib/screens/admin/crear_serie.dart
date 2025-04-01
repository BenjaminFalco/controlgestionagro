import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class CrearSerie extends StatefulWidget {
  const CrearSerie({super.key});

  @override
  State<CrearSerie> createState() => _CrearSerieState();
}

class _CrearSerieState extends State<CrearSerie> {
  final TextEditingController nombreSerieController = TextEditingController();
  final TextEditingController cantidadParcelasController = TextEditingController();
  final TextEditingController cantidadBloquesController = TextEditingController();

  String mensaje = '';
  String? ciudadSeleccionada;
  List<QueryDocumentSnapshot> ciudades = [];

  @override
  void initState() {
    super.initState();
    cargarCiudades();
  }

  Future<void> cargarCiudades() async {
    final snapshot = await FirebaseFirestore.instance.collection('ciudades').get();
    setState(() {
      ciudades = snapshot.docs;
    });
  }

  Future<void> crearSerie() async {
    final nombreSerie = nombreSerieController.text.trim();
    final cantidadParcelas = int.tryParse(cantidadParcelasController.text.trim());
    final cantidadBloques = int.tryParse(cantidadBloquesController.text.trim());

    if (nombreSerie.isEmpty ||
        cantidadParcelas == null ||
        cantidadBloques == null ||
        ciudadSeleccionada == null) {
      setState(() {
        mensaje = '⚠️ Completa todos los campos.';
      });
      return;
    }

    try {
      final ciudadRef =
          FirebaseFirestore.instance.collection('ciudades').doc(ciudadSeleccionada);

      final serieRef = await ciudadRef.collection('series').add({
        "nombre": nombreSerie,
        "matriz_largo": cantidadParcelas,
        "matriz_alto": cantidadBloques,
        "fecha_creacion": FieldValue.serverTimestamp(),
      });

      for (int i = 0; i < cantidadBloques; i++) {
        String bloque = String.fromCharCode(65 + i); // A, B, C, D...
        final bloqueRef = serieRef.collection('bloques').doc(bloque);
        await bloqueRef.set({"nombre": bloque});

        for (int j = 1; j <= cantidadParcelas; j++) {
          await bloqueRef.collection('parcelas').add({
            "numero": j,
            "tratamiento": true,
            "trabajador_id": null,
            "total_raices": null,
            "evaluacion": null,
            "frecuencia_relativa": null,
          });
        }
      }

      setState(() {
        mensaje =
            "✅ Serie '$nombreSerie' creada con $cantidadBloques bloques y $cantidadParcelas parcelas por bloque.";
        nombreSerieController.clear();
        cantidadParcelasController.clear();
        cantidadBloquesController.clear();
      });
    } catch (e) {
      setState(() {
        mensaje = "❌ Error: ${e.toString()}";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF005A56),
        centerTitle: true,
        elevation: 0,
        title: const Text(
          "Crear Serie",
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownButtonFormField<String>(
                  value: ciudadSeleccionada,
                  onChanged: (value) => setState(() => ciudadSeleccionada = value),
                  items: ciudades.map((doc) {
                    return DropdownMenuItem<String>(
                      value: doc.id,
                      child: Text(doc['nombre']),
                    );
                  }).toList(),
                  decoration: InputDecoration(
                    labelText: "Seleccionar ciudad",
                    labelStyle: const TextStyle(color: Colors.black),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.black),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Color(0xFF005A56), width: 2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  dropdownColor: Colors.white,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: nombreSerieController,
                  label: "Nombre de la serie",
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: cantidadBloquesController,
                  label: "Cantidad de bloques en la serie",
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: cantidadParcelasController,
                  label: "Cantidad de parcelas por bloque",
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: crearSerie,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00B140),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(fontSize: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text("Crear Serie"),
                ),
                const SizedBox(height: 16),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 18, color: Colors.black),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.black87),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        border: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.black),
          borderRadius: BorderRadius.circular(8),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.black),
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Color(0xFF005A56), width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}
