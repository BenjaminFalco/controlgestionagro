import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class CrearSerie extends StatefulWidget {
  const CrearSerie({super.key});

  @override
  State<CrearSerie> createState() => _CrearSerieState();
}

class _CrearSerieState extends State<CrearSerie> {
  final TextEditingController nombreSerieController = TextEditingController();
  final TextEditingController cantidadParcelasController =
      TextEditingController();
  String mensaje = '';
  String? ciudadSeleccionada;
  List<QueryDocumentSnapshot> ciudades = [];

  @override
  void initState() {
    super.initState();
    cargarCiudades();
  }

  Future<void> cargarCiudades() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('ciudades').get();
    setState(() {
      ciudades = snapshot.docs;
    });
  }

  Future<void> crearSerie() async {
    final nombreSerie = nombreSerieController.text.trim();
    final cantidadParcelas = int.tryParse(
      cantidadParcelasController.text.trim(),
    );

    if (nombreSerie.isEmpty ||
        cantidadParcelas == null ||
        ciudadSeleccionada == null) {
      setState(() {
        mensaje = '⚠️ Completa todos los campos.';
      });
      return;
    }

    try {
      final ciudadRef = FirebaseFirestore.instance
          .collection('ciudades')
          .doc(ciudadSeleccionada);

      // 🔹 Crear serie dentro de la ciudad
      final serieRef = await ciudadRef.collection('series').add({
        "nombre": nombreSerie,
        "matriz_largo": cantidadParcelas,
        "matriz_alto": 4,
        "fecha_creacion": FieldValue.serverTimestamp(),
      });

      // 🔹 Crear bloques A–D
      for (var bloque in ['A', 'B', 'C', 'D']) {
        final bloqueRef = serieRef.collection('bloques').doc(bloque);
        await bloqueRef.set({"nombre": bloque});

        // 🔹 Crear parcelas dentro del bloque
        for (int i = 1; i <= cantidadParcelas; i++) {
          await bloqueRef.collection('parcelas').add({
            "numero": i,
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
            "✅ Serie '$nombreSerie' creada con $cantidadParcelas parcelas por bloque.";
        nombreSerieController.clear();
        cantidadParcelasController.clear();
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
      appBar: AppBar(title: const Text("Crear Serie")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              value: ciudadSeleccionada,
              onChanged: (value) => setState(() => ciudadSeleccionada = value),
              items:
                  ciudades.map((doc) {
                    return DropdownMenuItem<String>(
                      value: doc.id,
                      child: Text(doc['nombre']),
                    );
                  }).toList(),
              decoration: const InputDecoration(
                labelText: "Seleccionar ciudad",
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: nombreSerieController,
              decoration: const InputDecoration(
                labelText: "Nombre de la serie",
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: cantidadParcelasController,
              decoration: const InputDecoration(
                labelText: "Cantidad de parcelas por bloque",
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: crearSerie,
              child: const Text("Crear Serie"),
            ),
            const SizedBox(height: 10),
            Text(mensaje),
          ],
        ),
      ),
    );
  }
}
