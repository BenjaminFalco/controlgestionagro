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
    backgroundColor: Colors.black,
    appBar: AppBar(
      backgroundColor: Colors.white,
      title: const Text(
        "Inicio de Tratamiento",
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.logout, color: Colors.black),
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
    body: GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    _buildFieldBox(
                      _buildDropdown(
                        "Ciudad",
                        ciudadSeleccionada,
                        ciudades.map((doc) {
                          return DropdownMenuItem(
                            value: doc.id,
                            child: Text(doc['nombre'],
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 20)),
                          );
                        }).toList(),
                        (value) {
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
                    ),
                    _buildFieldBox(
                      _buildDropdown(
                        "Serie",
                        serieSeleccionada,
                        series.map((doc) {
                          return DropdownMenuItem(
                            value: doc.id,
                            child: Text(doc['nombre'],
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 20)),
                          );
                        }).toList(),
                        (value) {
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
                    ),
                    _buildFieldBox(
                      _buildDropdown(
                        "Bloque",
                        bloqueSeleccionado,
                        bloques.map((b) {
                          return DropdownMenuItem(
                            value: b,
                            child: Text("Bloque $b",
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 20)),
                          );
                        }).toList(),
                        (value) {
                          setState(() {
                            bloqueSeleccionado = value;
                            parcelaSeleccionada = null;
                            parcelas.clear();
                          });
                          cargarParcelas();
                        },
                      ),
                    ),
                    _buildFieldBox(
                      _buildDropdown(
                        "Parcela de inicio",
                        parcelaSeleccionada,
                        parcelas.map((doc) {
                          return DropdownMenuItem(
                            value: doc.id,
                            child: Text("Parcela ${doc['numero']}",
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 20)),
                          );
                        }).toList(),
                        (value) {
                          setState(() {
                            parcelaSeleccionada = value;
                          });
                          if (value != null) actualizarInfoParcela(value);
                        },
                      ),
                    ),
                    _buildFieldBox(
                      TextField(
                        controller: superficieController,
                        style: const TextStyle(color: Colors.white, fontSize: 20),
                        decoration: const InputDecoration(
                          hintText: "Superficie cosechable (m²)",
                          hintStyle:
                              TextStyle(color: Colors.white70, fontSize: 18),
                          border: InputBorder.none,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // 🔹 Lista de parcelas
                    SizedBox(
                      height: 200,
                      child: parcelas.isEmpty
                          ? const Center(
                              child: Text(
                                "No hay parcelas cargadas.",
                                style:
                                    TextStyle(color: Colors.white60, fontSize: 18),
                              ),
                            )
                          : ListView.builder(
                              itemCount: parcelas.length,
                              itemBuilder: (context, index) {
                                final doc = parcelas[index];
                                return Card(
                                  color: Colors.grey[850],
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 4,
                                  margin:
                                      const EdgeInsets.symmetric(vertical: 10),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 20, vertical: 16),
                                    title: Text(
                                      "Parcela ${doc['numero']}",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 22,
                                      ),
                                    ),
                                    trailing: const Icon(
                                      Icons.arrow_forward_ios,
                                      color: Colors.white70,
                                    ),
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => FormularioTratamiento(
                                            ciudadId: ciudadSeleccionada!,
                                            serieId: serieSeleccionada!,
                                            bloqueId: bloqueSeleccionado!,
                                            parcelaDesde: doc['numero'],
                                            numeroFicha: numeroFicha,
                                            numeroTratamiento:
                                                numeroTratamiento,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                );
                              },
                            ),
                    ),

                    const SizedBox(height: 20),

                    // 🔹 Botón grande
                    SizedBox(
                      width: 300,
                      height: 60,
                      child: ElevatedButton.icon(
                        onPressed: parcelaSeleccionada != null
                            ? () {
                                final doc = parcelas.firstWhere(
                                    (p) => p.id == parcelaSeleccionada);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => FormularioTratamiento(
                                      ciudadId: ciudadSeleccionada!,
                                      serieId: serieSeleccionada!,
                                      bloqueId: bloqueSeleccionado!,
                                      parcelaDesde: doc['numero'],
                                      numeroFicha: numeroFicha,
                                      numeroTratamiento: numeroTratamiento,
                                    ),
                                  ),
                                );
                              }
                            : null,
                        icon: const Icon(Icons.play_arrow, size: 28),
                        label: const Text(
                          "EMPEZAR TRATAMIENTO",
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurpleAccent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

// 🔧 Dropdown estilizado
Widget _buildDropdown(
  String label,
  String? value,
  List<DropdownMenuItem<String>> items,
  Function(String?) onChanged,
) {
  return DropdownButtonFormField<String>(
  value: value,
  dropdownColor: Colors.grey[900],
  decoration: InputDecoration(
  labelText: label,
  labelStyle: const TextStyle(color: Colors.white70, fontSize: 20),
  filled: true,
  fillColor: Colors.transparent,
  enabledBorder: InputBorder.none,
  focusedBorder: InputBorder.none,
  border: InputBorder.none,
),

  style: const TextStyle(color: Colors.white, fontSize: 20), // <- TEXTOS SELECCIONADOS
  items: items,
  onChanged: onChanged,
);
}

// 🧩 Caja visual para inputs
Widget _buildFieldBox(Widget child) {
  return Container(
    margin: const EdgeInsets.symmetric(vertical: 8),
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    width: double.infinity,
    decoration: BoxDecoration(
      color: Colors.grey[850],
      borderRadius: BorderRadius.circular(14),
    ),
    child: child,
  );
}
}
