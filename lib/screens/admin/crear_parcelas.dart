import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'ver_matriz.dart';
import 'editar_parcela.dart';

class CrearParcelas extends StatefulWidget {
  const CrearParcelas({super.key});

  @override
  State<CrearParcelas> createState() => _CrearParcelasState();
}

class _CrearParcelasState extends State<CrearParcelas> {
  String? ciudadSeleccionada;
  String? serieSeleccionada;

  Map<String, List<DocumentSnapshot>> parcelasPorBloque = {};
  bool cargandoParcelas = false;
  List<QueryDocumentSnapshot> ciudades = [];
  List<QueryDocumentSnapshot> series = [];

  String mensaje = '';

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

  Future<void> cargarSeries() async {
    if (ciudadSeleccionada == null) return;
    final snapshot = await FirebaseFirestore.instance
        .collection('ciudades')
        .doc(ciudadSeleccionada)
        .collection('series')
        .get();
    setState(() {
      series = snapshot.docs;
    });
  }

  Future<void> cargarMatrizCompleta() async {
    if (ciudadSeleccionada == null || serieSeleccionada == null) return;

    setState(() {
      cargandoParcelas = true;
      parcelasPorBloque.clear();
    });

    final serieRef = FirebaseFirestore.instance
        .collection('ciudades')
        .doc(ciudadSeleccionada!)
        .collection('series')
        .doc(serieSeleccionada!);

    final serieDoc = await serieRef.get();
    final int cantidadBloques = serieDoc['matriz_alto'];

    for (int i = 0; i < cantidadBloques; i++) {
      String bloque = (cantidadBloques - i).toString();
      final snap = await serieRef
          .collection('bloques')
          .doc(bloque)
          .collection('parcelas')
          .orderBy('numero')
          .get();

      if (snap.docs.isNotEmpty) {
        parcelasPorBloque[bloque] = snap.docs;
      }
    }

    setState(() => cargandoParcelas = false);
  }

  Future<void> crearBloquesYParcelas() async {
    if (ciudadSeleccionada == null || serieSeleccionada == null) {
      setState(() => mensaje = "⚠️ Selecciona ciudad y serie.");
      return;
    }

    if (parcelasPorBloque.isNotEmpty) {
      setState(() => mensaje = "⚠️ Ya existen parcelas. No puedes volver a crear.");
      return;
    }

    try {
      final serieDoc = await FirebaseFirestore.instance
          .collection('ciudades')
          .doc(ciudadSeleccionada!)
          .collection('series')
          .doc(serieSeleccionada!)
          .get();

      final int cantidadParcelas = serieDoc['matriz_largo'];
      final int cantidadBloques = serieDoc['matriz_alto'];
      final serieRef = FirebaseFirestore.instance
          .collection('ciudades')
          .doc(ciudadSeleccionada!)
          .collection('series')
          .doc(serieSeleccionada!);

      for (int i = 0; i < cantidadBloques; i++) {
        String bloque = (i + 1).toString();
        final bloqueRef = serieRef.collection('bloques').doc(bloque);
        await bloqueRef.set({"nombre": bloque}, SetOptions(merge: true));

        for (int j = 1; j <= cantidadParcelas; j++) {
          final parcelaRef = bloqueRef.collection('parcelas').doc(j.toString());
          final parcelaSnap = await parcelaRef.get();

          if (!parcelaSnap.exists) {
            await parcelaRef.set({
              "numero": j,
              "tratamiento": true,
              "trabajador_id": null,
              "total_raices": null,
              "evaluacion": null,
              "frecuencia_relativa": null,
            });
          }
        }
      }

      setState(() => mensaje = "✅ Parcelas generadas correctamente.");
      await cargarMatrizCompleta();
    } catch (e) {
      setState(() => mensaje = "❌ Error al crear parcelas: ${e.toString()}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF005A56),
        title: const Text("Crear Parcelas en Serie", style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<String>(
              value: ciudadSeleccionada,
              decoration: _dropdownDecoration("Seleccionar ciudad"),
              items: ciudades.map((doc) {
                return DropdownMenuItem(value: doc.id, child: Text(doc['nombre']));
              }).toList(),
              onChanged: (value) {
                setState(() {
                  ciudadSeleccionada = value;
                  serieSeleccionada = null;
                  series = [];
                  parcelasPorBloque.clear();
                });
                cargarSeries();
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: serieSeleccionada,
              decoration: _dropdownDecoration("Seleccionar serie"),
              items: series.map((doc) {
                return DropdownMenuItem(value: doc.id, child: Text(doc['nombre']));
              }).toList(),
              onChanged: (value) {
                setState(() => serieSeleccionada = value);
                cargarMatrizCompleta();
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: crearBloquesYParcelas,
              icon: const Icon(Icons.add_box),
              label: const Text("Crear bloques y parcelas"),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00B140),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 10),
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
            const SizedBox(height: 20),
            if (parcelasPorBloque.isNotEmpty)
              ...parcelasPorBloque.entries.toList().reversed
  .map((entry) {
                    final bloque = entry.key;
                    final List<DocumentSnapshot> listaParcelas = entry.value;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Bloque $bloque", style: const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        SizedBox(
                          height: 100,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: listaParcelas.length,
                            itemBuilder: (context, index) {
                              final parcela = listaParcelas[index];
                              final numero = parcela['numero'];
                              final idDoc = parcela.id;

                              return Container(
                                width: 90,
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                decoration: BoxDecoration(
                                  color: Colors.deepPurple[50],
                                  border: Border.all(color: Colors.deepPurple),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text("Parcela $numero"),
                                    const SizedBox(height: 6),
                                    ElevatedButton(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => EditarParcela(
                                              ciudadId: ciudadSeleccionada!,
                                              serieId: serieSeleccionada!,
                                              bloqueId: bloque,
                                              parcelaId: idDoc,
                                            ),
                                          ),
                                        ).then((_) => cargarMatrizCompleta());
                                      },
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                      ),
                                      child: const Text("Editar", style: TextStyle(fontSize: 11)),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    );
                  })
                  .toList()
                  .reversed
            else if (serieSeleccionada != null && !cargandoParcelas)
              const Text("⚠️ Serie vacía. No hay parcelas registradas."),
          ],
        ),
      ),
    );
  }

  InputDecoration _dropdownDecoration(String label) {
    return InputDecoration(
      labelText: label,
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
    );
  }
}
