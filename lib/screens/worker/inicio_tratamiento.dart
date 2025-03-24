import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'formulario_tratamiento.dart';
import '../login_screen.dart';

class InicioTratamientoScreen extends StatefulWidget {
  const InicioTratamientoScreen({super.key});

  @override
  State<InicioTratamientoScreen> createState() =>
      _InicioTratamientoScreenState();
}

class _InicioTratamientoScreenState extends State<InicioTratamientoScreen> {
  String? ciudadSeleccionada;
  String? serieSeleccionada;
  String? bloqueSeleccionado;
  String? parcelaSeleccionada;

  List<QueryDocumentSnapshot> ciudades = [];
  List<QueryDocumentSnapshot> series = [];
  List<String> bloques = [];
  List<DocumentSnapshot> parcelas = [];

  String numeroFicha = '';
  String numeroTratamiento = '';
  final TextEditingController superficieController = TextEditingController(
    text: "10 mt^2",
  );

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

  Future<void> cargarBloques() async {
    if (ciudadSeleccionada == null || serieSeleccionada == null) return;

    final snapshot =
        await FirebaseFirestore.instance
            .collection('ciudades')
            .doc(ciudadSeleccionada)
            .collection('series')
            .doc(serieSeleccionada)
            .collection('bloques')
            .get();

    setState(() {
      bloques = snapshot.docs.map((doc) => doc.id).toList();
    });
  }

  Future<void> cargarParcelas() async {
    if (bloqueSeleccionado == null) return;

    final snapshot =
        await FirebaseFirestore.instance
            .collection('ciudades')
            .doc(ciudadSeleccionada!)
            .collection('series')
            .doc(serieSeleccionada!)
            .collection('bloques')
            .doc(bloqueSeleccionado!)
            .collection('parcelas')
            .orderBy('numero')
            .get();

    setState(() {
      parcelas = snapshot.docs;
    });
  }

  Future<void> actualizarInfoParcela(String id) async {
    final doc = parcelas.firstWhere((p) => p.id == id);
    setState(() {
      numeroFicha = doc['numero_ficha']?.toString() ?? '';
      numeroTratamiento = doc['numero_tratamiento']?.toString() ?? '';
    });
  }

  void iniciarTratamiento() {
    if (ciudadSeleccionada == null ||
        serieSeleccionada == null ||
        bloqueSeleccionado == null ||
        parcelaSeleccionada == null)
      return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => FormularioTratamiento(
              ciudadId: ciudadSeleccionada!,
              serieId: serieSeleccionada!,
              bloqueId: bloqueSeleccionado!,
              parcelaDesde: int.parse(
                parcelas
                    .firstWhere((p) => p.id == parcelaSeleccionada)['numero']
                    .toString(),
              ),
              numeroFicha: numeroFicha,
              numeroTratamiento: numeroTratamiento,
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Inicio Tratamiento"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: "Cerrar sesión",
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            DropdownButtonFormField<String>(
              value: ciudadSeleccionada,
              decoration: const InputDecoration(labelText: "Ciudad"),
              items:
                  ciudades
                      .map(
                        (doc) => DropdownMenuItem(
                          value: doc.id,
                          child: Text(doc['nombre']),
                        ),
                      )
                      .toList(),
              onChanged: (value) {
                setState(() {
                  ciudadSeleccionada = value;
                  serieSeleccionada = null;
                  bloqueSeleccionado = null;
                  parcelaSeleccionada = null;
                  series.clear();
                  bloques.clear();
                  parcelas.clear();
                });
                cargarSeries();
              },
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: serieSeleccionada,
              decoration: const InputDecoration(labelText: "Serie"),
              items:
                  series
                      .map(
                        (doc) => DropdownMenuItem(
                          value: doc.id,
                          child: Text(doc['nombre']),
                        ),
                      )
                      .toList(),
              onChanged: (value) {
                setState(() {
                  serieSeleccionada = value;
                  bloqueSeleccionado = null;
                  parcelaSeleccionada = null;
                  bloques.clear();
                  parcelas.clear();
                });
                cargarBloques();
              },
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: bloqueSeleccionado,
              decoration: const InputDecoration(labelText: "Bloque"),
              items:
                  bloques
                      .map(
                        (bloque) => DropdownMenuItem(
                          value: bloque,
                          child: Text("Bloque $bloque"),
                        ),
                      )
                      .toList(),
              onChanged: (value) {
                setState(() {
                  bloqueSeleccionado = value;
                  parcelaSeleccionada = null;
                  parcelas.clear();
                });
                cargarParcelas();
              },
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: parcelaSeleccionada,
              decoration: const InputDecoration(labelText: "Parcela de inicio"),
              items:
                  parcelas
                      .map(
                        (doc) => DropdownMenuItem(
                          value: doc.id,
                          child: Text("Parcela ${doc['numero']}"),
                        ),
                      )
                      .toList(),
              onChanged: (value) {
                setState(() {
                  parcelaSeleccionada = value;
                });
                if (value != null) actualizarInfoParcela(value);
              },
            ),
            const SizedBox(height: 20),
            if (numeroFicha.isNotEmpty && numeroTratamiento.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Número ficha: $numeroFicha"),
                  Text("Número tratamiento: $numeroTratamiento"),
                  const SizedBox(height: 10),
                ],
              ),
            TextField(
              controller: superficieController,
              decoration: const InputDecoration(
                labelText: "Superficie cosechable",
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: iniciarTratamiento,
              icon: const Icon(Icons.play_arrow),
              label: const Text("Iniciar tratamiento"),
            ),
          ],
        ),
      ),
    );
  }
}
