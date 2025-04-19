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
    text: "10 m²",
  );

  @override
  void initState() {
    super.initState();
    cargarCiudades();
  }

  Future<void> guardarSuperficieEnSerie() async {
    if (ciudadSeleccionada == null || serieSeleccionada == null) return;

    final superficie = superficieController.text.trim();

    await FirebaseFirestore.instance
        .collection('ciudades')
        .doc(ciudadSeleccionada!)
        .collection('series')
        .doc(serieSeleccionada!)
        .update({'superficie': superficie});
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

    final docs = snapshot.docs;

    // Verificación de campo
    bool faltanCampos = docs.any((doc) {
      final data = doc.data() as Map<String, dynamic>?;
      return data == null || !data.containsKey('numero_tratamiento');
    });

    if (faltanCampos) {
      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text("⚠️ Campo faltante"),
              content: const Text(
                "Este bloque contiene parcelas sin 'número de tratamiento'.\n\nPor favor, pide al administrador que lo genere antes de continuar.",
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text("Aceptar"),
                ),
              ],
            ),
      );
      return;
    }

    setState(() {
      parcelas = docs;
    });
  }

  Future<void> actualizarInfoParcela(String id) async {
    final doc = parcelas.firstWhere((p) => p.id == id);
    final data = doc.data() as Map<String, dynamic>?;

    if (data == null || !data.containsKey('numero_tratamiento')) {
      setState(() {
        numeroFicha = '';
        numeroTratamiento = '';
      });

      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text("Campo faltante"),
              content: const Text(
                "Las parcelas de este bloque no tienen asignado el campo 'número de tratamiento'.\n\nPor favor, pide al administrador que lo genere antes de continuar.",
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text("Aceptar"),
                ),
              ],
            ),
      );
      return;
    }

    setState(() {
      numeroFicha = data['numero_ficha']?.toString() ?? '';
      numeroTratamiento = data['numero_tratamiento']?.toString() ?? '';
    });
  }

  Future<bool> puedeGenerarNumerosFicha() async {
    if (bloqueSeleccionado != 'A' || parcelaSeleccionada == null) return false;

    final doc = parcelas.firstWhere((p) => p.id == parcelaSeleccionada);
    final numeroParcela = doc['numero'];
    if (numeroParcela != 1) return false;

    final bloquesSnapshot =
        await FirebaseFirestore.instance
            .collection('ciudades')
            .doc(ciudadSeleccionada!)
            .collection('series')
            .doc(serieSeleccionada!)
            .collection('bloques')
            .get();

    for (var bloqueDoc in bloquesSnapshot.docs) {
      final parcelasSnapshot =
          await bloqueDoc.reference
              .collection('parcelas')
              .where('numero_ficha', isGreaterThanOrEqualTo: 1)
              .limit(1)
              .get();
      if (parcelasSnapshot.docs.isNotEmpty) return false;
    }

    return true;
  }

  Future<void> generarNumerosFicha(int numeroInicial) async {
    int contador = numeroInicial;

    final bloquesSnapshot =
        await FirebaseFirestore.instance
            .collection('ciudades')
            .doc(ciudadSeleccionada!)
            .collection('series')
            .doc(serieSeleccionada!)
            .collection('bloques')
            .orderBy(FieldPath.documentId)
            .get();

    for (var bloqueDoc in bloquesSnapshot.docs) {
      final parcelasSnapshot =
          await bloqueDoc.reference
              .collection('parcelas')
              .orderBy('numero')
              .get();

      for (var parcelaDoc in parcelasSnapshot.docs) {
        await parcelaDoc.reference.update({'numero_ficha': contador});
        contador++;
      }
    }

    await cargarParcelas(); // Refresca la UI
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("✅ Números de ficha generados exitosamente"),
      ),
    );
  }

  void mostrarModalGenerarFicha() async {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text("Ingresar número inicial de ficha"),
            content: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(hintText: "Ej: 100"),
            ),
            actions: [
              TextButton(
                child: const Text("Cancelar"),
                onPressed: () => Navigator.pop(context),
              ),
              ElevatedButton(
                child: const Text("Generar"),
                onPressed: () {
                  final input = int.tryParse(controller.text.trim());
                  if (input != null) {
                    Navigator.pop(context);
                    generarNumerosFicha(input);
                  }
                },
              ),
            ],
          ),
    );
  }

  Future<void> iniciarTratamiento() async {
    if (ciudadSeleccionada == null ||
        serieSeleccionada == null ||
        bloqueSeleccionado == null ||
        parcelaSeleccionada == null)
      return;

    await guardarSuperficieEnSerie(); // 🟢 Guardamos la superficie antes de avanzar

    final doc = parcelas.firstWhere((p) => p.id == parcelaSeleccionada);
    final data = doc.data() as Map<String, dynamic>?;

    if (data == null || !data.containsKey('numero_tratamiento')) {
      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text("Falta número de tratamiento"),
              content: const Text(
                "Esta parcela no tiene asignado el número de tratamiento. Por favor, pide al administrador que lo genere.",
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Aceptar"),
                ),
              ],
            ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => FormularioTratamiento(
              ciudadId: ciudadSeleccionada!,
              serieId: serieSeleccionada!,
              bloqueId: bloqueSeleccionado!,
              parcelaDesde: int.parse(data['numero'].toString()),
              numeroFicha: data['numero_ficha']?.toString() ?? '',
              numeroTratamiento: data['numero_tratamiento']?.toString() ?? '',
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
        centerTitle: true,
        toolbarHeight: 70,
        title: const Text(
          "POSICIONAR TERRENO",
          style: TextStyle(
            fontSize: 30,
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
                constraints: const BoxConstraints(maxWidth: 900),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40.0),
                  child: Column(
                    children: [
                      const SizedBox(height: 34),
                      Row(
                        children: [
                          Expanded(
                            child: _buildFieldBox(
                              _buildDropdown(
                                "Localidad",
                                ciudadSeleccionada,
                                ciudades.map((doc) {
                                  return DropdownMenuItem(
                                    value: doc.id,
                                    child: Text(
                                      doc['nombre'],
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
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
                          ),
                          const SizedBox(width: 35),
                          Expanded(
                            child: _buildFieldBox(
                              _buildDropdown(
                                "Ensayo",
                                serieSeleccionada,
                                series.map((doc) {
                                  return DropdownMenuItem(
                                    value: doc.id,
                                    child: Text(
                                      doc['nombre'],
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
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
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildFieldBox(
                              _buildDropdown(
                                "Bloque",
                                bloqueSeleccionado,
                                bloques.map((b) {
                                  return DropdownMenuItem(
                                    value: b,
                                    child: Text(
                                      "Bloque $b",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
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
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            child: _buildFieldBox(
                              _buildDropdown(
                                "Tratamiento de inicio",
                                parcelaSeleccionada,
                                parcelas.map((doc) {
                                  return DropdownMenuItem(
                                    value: doc.id,
                                    child: Text(
                                      "T ${doc['numero_tratamiento']}",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  );
                                }).toList(),
                                (value) {
                                  setState(() => parcelaSeleccionada = value);
                                  if (value != null)
                                    actualizarInfoParcela(value);
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildFieldBox(
                        TextField(
                          controller: superficieController,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                          decoration: const InputDecoration(
                            hintText: "Superficie cosechable (m²)",
                            hintStyle: TextStyle(
                              color: Colors.white70,
                              fontSize: 15,
                            ),
                            border: InputBorder.none,
                          ),
                        ),
                      ),

                      FutureBuilder<bool>(
                        future: puedeGenerarNumerosFicha(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const SizedBox(); // o loader
                          }

                          if (snapshot.data == true) {
                            return Column(
                              children: [
                                SizedBox(
                                  width:
                                      MediaQuery.of(context).size.width * 0.85,
                                  height: 50,
                                  child: ElevatedButton.icon(
                                    onPressed: mostrarModalGenerarFicha,
                                    icon: const Icon(
                                      Icons.auto_fix_high,
                                      size: 34,
                                    ),
                                    label: const Text(
                                      "GENERAR N° FICHA",
                                      style: TextStyle(
                                        fontSize: 26,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: Colors.black,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                              ],
                            );
                          }

                          return const SizedBox.shrink();
                        },
                      ),

                      const SizedBox(height: 20),
                      SizedBox(
                        width: MediaQuery.of(context).size.width * 0.85,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed:
                              parcelaSeleccionada != null
                                  ? () async {
                                    // Guardar superficie en la serie
                                    final superficie =
                                        superficieController.text.trim();
                                    await FirebaseFirestore.instance
                                        .collection('ciudades')
                                        .doc(ciudadSeleccionada!)
                                        .collection('series')
                                        .doc(serieSeleccionada!)
                                        .update({'superficie': superficie});

                                    // Ir al formulario de tratamiento
                                    final doc = parcelas.firstWhere(
                                      (p) => p.id == parcelaSeleccionada,
                                    );
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (_) => FormularioTratamiento(
                                              ciudadId: ciudadSeleccionada!,
                                              serieId: serieSeleccionada!,
                                              bloqueId: bloqueSeleccionado!,
                                              parcelaDesde: doc['numero'],
                                              numeroFicha:
                                                  (doc.data()
                                                              as Map<
                                                                String,
                                                                dynamic
                                                              >)
                                                          .containsKey(
                                                            'numero_ficha',
                                                          )
                                                      ? doc['numero_ficha']
                                                              ?.toString() ??
                                                          ''
                                                      : '',
                                              numeroTratamiento:
                                                  doc['numero_tratamiento']
                                                      ?.toString() ??
                                                  '',
                                            ),
                                      ),
                                    );
                                  }
                                  : null, // Desactiva si no hay parcela seleccionada
                          icon: const Icon(Icons.play_arrow, size: 34),
                          label: const Text(
                            "INICIAR TOMA DE DATOS",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF04bc04),
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
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

  Widget _buildDropdown(
    String label,
    String? value,
    List<DropdownMenuItem<String>> items,
    Function(String?) onChanged,
  ) {
    final validValues = items.map((item) => item.value).toList();
    final fixedValue = validValues.contains(value) ? value : null;

    return DropdownButtonFormField<String>(
      value: fixedValue, // usa el valor fijo corregido
      isExpanded: true,
      dropdownColor: Colors.black,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          color: Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.bold,
        ),
        filled: true,
        fillColor: Colors.black,
        border: InputBorder.none,
      ),
      style: const TextStyle(color: Colors.white, fontSize: 22),
      items: items,
      onChanged: onChanged,
    );
  }

  Widget _buildFieldBox(Widget child) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border.all(color: Colors.white, width: 10),
        borderRadius: BorderRadius.circular(5),
      ),
      child: child,
    );
  }
}
