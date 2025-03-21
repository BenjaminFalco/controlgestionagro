import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'formulario_tratamiento.dart'; // Vista donde se ingresan datos por parcela

class InicioTratamiento extends StatefulWidget {
  const InicioTratamiento({super.key});

  @override
  State<InicioTratamiento> createState() => _InicioTratamientoState();
}

class _InicioTratamientoState extends State<InicioTratamiento> {
  String? ciudadSeleccionada;
  String? serieSeleccionada;
  String? bloqueSeleccionado;
  int? parcelaInicial;

  List<QueryDocumentSnapshot> ciudades = [];
  List<QueryDocumentSnapshot> series = [];
  List<int> parcelas = [];

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

  Future<void> cargarParcelas() async {
    if (ciudadSeleccionada == null ||
        serieSeleccionada == null ||
        bloqueSeleccionado == null)
      return;

    final snapshot =
        await FirebaseFirestore.instance
            .collection('ciudades')
            .doc(ciudadSeleccionada)
            .collection('series')
            .doc(serieSeleccionada)
            .collection('bloques')
            .doc(bloqueSeleccionado)
            .collection('parcelas')
            .orderBy('numero')
            .get();

    setState(() {
      parcelas = snapshot.docs.map((doc) => doc['numero'] as int).toList();
    });
  }

  void iniciarTratamiento() {
    if (ciudadSeleccionada != null &&
        serieSeleccionada != null &&
        bloqueSeleccionado != null &&
        parcelaInicial != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (_) => FormularioTratamiento(
                ciudadId: ciudadSeleccionada!,
                serieId: serieSeleccionada!,
                bloqueId: bloqueSeleccionado!,
                parcelaDesde: parcelaInicial!,
              ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Inicio de tratamiento")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            DropdownButtonFormField<String>(
              value: ciudadSeleccionada,
              decoration: const InputDecoration(labelText: "Ciudad"),
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
                  bloqueSeleccionado = null;
                  parcelaInicial = null;
                  series = [];
                  parcelas = [];
                });
                cargarSeries();
              },
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: serieSeleccionada,
              decoration: const InputDecoration(labelText: "Serie"),
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
                  bloqueSeleccionado = null;
                  parcelaInicial = null;
                  parcelas = [];
                });
              },
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: bloqueSeleccionado,
              decoration: const InputDecoration(labelText: "Bloque"),
              items:
                  ['A', 'B', 'C', 'D'].map((bloque) {
                    return DropdownMenuItem(
                      value: bloque,
                      child: Text("Bloque $bloque"),
                    );
                  }).toList(),
              onChanged: (value) {
                setState(() {
                  bloqueSeleccionado = value;
                  parcelaInicial = null;
                  parcelas = [];
                });
                cargarParcelas();
              },
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<int>(
              value: parcelaInicial,
              decoration: const InputDecoration(labelText: "Parcela de inicio"),
              items:
                  parcelas.map((numero) {
                    return DropdownMenuItem(
                      value: numero,
                      child: Text("Parcela $numero"),
                    );
                  }).toList(),
              onChanged: (value) {
                setState(() {
                  parcelaInicial = value;
                });
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: iniciarTratamiento,
              icon: const Icon(Icons.play_arrow),
              label: const Text("Empezar tratamiento"),
            ),
          ],
        ),
      ),
    );
  }
}
