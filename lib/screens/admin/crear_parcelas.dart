import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'ver_matriz.dart';

class CrearParcelas extends StatefulWidget {
  const CrearParcelas({super.key});

  @override
  State<CrearParcelas> createState() => _CrearParcelasState();
}

class _CrearParcelasState extends State<CrearParcelas> {
  String? ciudadSeleccionada;
  String? serieSeleccionada;

  List<QueryDocumentSnapshot> ciudades = [];
  List<QueryDocumentSnapshot> series = [];

  String mensaje = '';

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

  Future<void> cargarSeries() async {
    if (ciudadSeleccionada == null) return;
    final snapshot =
        await FirebaseFirestore.instance
            .collection('ciudades')
            .doc(ciudadSeleccionada)
            .collection('series')
            .get();
    setState(() {
      series = snapshot.docs;
    });
  }

  Future<void> crearBloquesYParcelas() async {
    if (ciudadSeleccionada == null || serieSeleccionada == null) {
      setState(() {
        mensaje = "⚠️ Selecciona ciudad y serie.";
      });
      return;
    }

    try {
      final serieDoc =
          await FirebaseFirestore.instance
              .collection('ciudades')
              .doc(ciudadSeleccionada)
              .collection('series')
              .doc(serieSeleccionada)
              .get();

      final int cantidadParcelas = serieDoc['matriz_largo'];
      final serieRef = FirebaseFirestore.instance
          .collection('ciudades')
          .doc(ciudadSeleccionada)
          .collection('series')
          .doc(serieSeleccionada);

      for (var bloque in ['A', 'B', 'C', 'D']) {
        final bloqueRef = serieRef.collection('bloques').doc(bloque);
        await bloqueRef.set({"nombre": bloque}, SetOptions(merge: true));

        int creadas = 0;
        for (int i = 1; i <= cantidadParcelas; i++) {
          final parcelaRef = bloqueRef.collection('parcelas').doc(i.toString());
          final parcelaSnap = await parcelaRef.get();

          if (!parcelaSnap.exists) {
            await parcelaRef.set({
              "numero": i,
              "tratamiento": true,
              "trabajador_id": null,
              "total_raices": null,
              "evaluacion": null,
              "frecuencia_relativa": null,
            });
            creadas++;
          }
        }
        debugPrint("Bloque $bloque → Parcelas nuevas creadas: $creadas");
      }

      setState(() {
        mensaje = "✅ Parcelas generadas solo si no existían ya.";
      });
    } catch (e) {
      setState(() {
        mensaje = "❌ Error al crear parcelas: ${e.toString()}";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Crear Parcelas en Serie")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 🔹 Filtro: Ciudad
            DropdownButtonFormField<String>(
              value: ciudadSeleccionada,
              decoration: const InputDecoration(
                labelText: "Seleccionar ciudad",
              ),
              items:
                  ciudades.map((doc) {
                    return DropdownMenuItem(
                      value: doc.id,
                      child: Text(doc['nombre']),
                    );
                  }).toList(),
              onChanged: (value) {
                setState(() {
                  ciudadSeleccionada = value;
                  serieSeleccionada = null;
                  series = [];
                });
                cargarSeries();
              },
            ),
            const SizedBox(height: 10),

            // 🔹 Filtro: Serie
            DropdownButtonFormField<String>(
              value: serieSeleccionada,
              decoration: const InputDecoration(labelText: "Seleccionar serie"),
              items:
                  series.map((doc) {
                    return DropdownMenuItem(
                      value: doc.id,
                      child: Text(doc['nombre']),
                    );
                  }).toList(),
              onChanged: (value) {
                setState(() {
                  serieSeleccionada = value;
                });
              },
            ),

            const SizedBox(height: 20),

            // 🔹 Botón: Crear bloques y parcelas
            ElevatedButton.icon(
              onPressed: crearBloquesYParcelas,
              icon: const Icon(Icons.add_box),
              label: const Text("Crear bloques y parcelas"),
            ),

            const SizedBox(height: 20),
            Text(mensaje),

            // 🔹 Mostrar "Ver matriz" solo si ya se generaron las parcelas
            if (mensaje.contains("Parcelas generadas"))
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (_) => VerMatriz(
                            ciudadId: ciudadSeleccionada!,
                            serieId: serieSeleccionada!,
                          ),
                    ),
                  );
                },
                icon: const Icon(Icons.visibility),
                label: const Text("Ver matriz"),
              ),
          ],
        ),
      ),
    );
  }
}
