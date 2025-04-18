import 'inicio_tratamiento.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'evaluacion_dano.dart';
import 'package:intl/intl.dart';

class AlwaysDisabledFocusNode extends FocusNode {
  @override
  bool get hasFocus => false;
}

class FormularioTratamiento extends StatefulWidget {
  final String ciudadId;
  final String serieId;
  final String bloqueId;
  final int parcelaDesde;
  final String numeroFicha;
  final String numeroTratamiento;

  const FormularioTratamiento({
    super.key,
    required this.ciudadId,
    required this.serieId,
    required this.bloqueId,
    required this.parcelaDesde,
    required this.numeroFicha,
    required this.numeroTratamiento,
  });

  @override
  State<FormularioTratamiento> createState() => _FormularioTratamientoState();
}

class _FormularioTratamientoState extends State<FormularioTratamiento> {
  List<DocumentSnapshot> parcelas = [];
  int currentIndex = 0;
  TextEditingController? focusedController;

  final TextEditingController raicesAController = TextEditingController();
  final TextEditingController raicesBController = TextEditingController();
  final TextEditingController pesoAController = TextEditingController();
  final TextEditingController pesoBController = TextEditingController();
  final TextEditingController pesoHojasController = TextEditingController();
  final TextEditingController ndviController = TextEditingController();
  final TextEditingController observacionesController = TextEditingController();

  String mensaje = '';

  @override
  void initState() {
    super.initState();
    cargarCiudadYSerie();
    cargarTodasLasParcelas();
    raicesAController.addListener(() => setState(() {}));
    raicesBController.addListener(() => setState(() {}));
    pesoAController.addListener(() => setState(() {}));
    pesoBController.addListener(() => setState(() {}));
  }

  Map<String, dynamic>? ciudad;
  Map<String, dynamic>? serie;
  Map<String, String> nombresBloques =
      {}; // bloqueId -> nombre (ej: 'A' → 'Bloque 1')

  Future<void> cargarCiudadYSerie() async {
    final ciudadSnap =
        await FirebaseFirestore.instance
            .collection('ciudades')
            .doc(widget.ciudadId)
            .get();

    final serieSnap =
        await FirebaseFirestore.instance
            .collection('ciudades')
            .doc(widget.ciudadId)
            .collection('series')
            .doc(widget.serieId)
            .get();

    setState(() {
      ciudad = ciudadSnap.data();
      serie = serieSnap.data();
    });
  }

  Future<void> guardarTratamientoActual() async {
    final parcela = parcelas[currentIndex];
    final ref = parcela.reference.collection('tratamientos').doc('actual');

    await ref.set({
      'raicesA': raicesAController.text.trim(),
      'raicesB': raicesBController.text.trim(),
      'pesoA': pesoAController.text.trim(),
      'pesoB': pesoBController.text.trim(),
      'pesoHojas': pesoHojasController.text.trim(),
      'ndvi': ndviController.text.trim(),
      'observaciones': observacionesController.text.trim(),
      'fecha': Timestamp.now(),
      'trabajador': FirebaseAuth.instance.currentUser?.email ?? 'desconocido',
    });
  }

  Future<void> cargarTratamientoActual() async {
    if (parcelas.isEmpty) return;

    final parcela = parcelas[currentIndex];
    final doc =
        await parcela.reference.collection('tratamientos').doc('actual').get();

    if (doc.exists) {
      final data = doc.data()!;
      setState(() {
        raicesAController.text = data['raicesA'] ?? '';
        raicesBController.text = data['raicesB'] ?? '';
        pesoAController.text = data['pesoA'] ?? '';
        pesoBController.text = data['pesoB'] ?? '';
        pesoHojasController.text = data['pesoHojas'] ?? '';
        ndviController.text = data['ndvi'] ?? '';
        observacionesController.text = data['observaciones'] ?? '';
      });
    } else {
      limpiarFormulario();
    }
  }

  Future<void> cargarTodasLasParcelas() async {
    final bloquesSnap =
        await FirebaseFirestore.instance
            .collection('ciudades')
            .doc(widget.ciudadId)
            .collection('series')
            .doc(widget.serieId)
            .collection('bloques')
            .orderBy('nombre') // Ordenar A-Z
            .get();

    List<DocumentSnapshot> todasParcelas = [];

    for (final bloque in bloquesSnap.docs) {
      final bloqueId = bloque.id;
      final nombreBloque = bloque['nombre'];
      nombresBloques[bloqueId] = nombreBloque;

      final parcelasSnap =
          await bloque.reference.collection('parcelas').orderBy('numero').get();

      todasParcelas.addAll(parcelasSnap.docs);
    }

    setState(() {
      parcelas = todasParcelas;
      currentIndex = 0;
    });

    await cargarTratamientoActual();
  }

  Widget _buildInput(
    String label,
    TextEditingController controller, {
    int maxLines = 1,
    bool isNumeric = false,
  }) {
    return GestureDetector(
      onTap: () {
        if (isNumeric) {
          setState(() => focusedController = controller);

          showModalBottomSheet(
            context: context,
            backgroundColor: Colors.black,
            isScrollControlled: true,
            builder: (_) {
              return Padding(
                padding: const EdgeInsets.all(4),
                child:
                    label == "NDVI"
                        ? CustomNDVIPad(
                          initialValue: controller.text,
                          onChanged: (val) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              setState(() {
                                controller.text = val;
                              });
                            });
                          },
                        )
                        : CustomNumPad(
                          initialValue: controller.text,
                          onChanged: (val) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              setState(() {
                                controller.text = val;
                              });
                            });
                          },
                        ),
              );
            },
          );
        }
      },
      child: AbsorbPointer(
        absorbing: isNumeric,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 10),
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: isNumeric ? TextInputType.none : TextInputType.text,
            style: const TextStyle(
              fontSize: 20,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
            decoration: InputDecoration(
              labelText: label,
              labelStyle: const TextStyle(fontSize: 20, color: Colors.white),
              filled: true,
              fillColor: Colors.black,
              contentPadding: const EdgeInsets.symmetric(
                vertical: 20,
                horizontal: 25,
              ),
              enabledBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Colors.white, width: 5),
              ),
              focusedBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Colors.cyanAccent, width: 5),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputPair(
    String label1,
    TextEditingController controller1,
    String label2,
    TextEditingController controller2, {
    bool isNumeric = false,
  }) {
    return Row(
      children: [
        Expanded(child: _buildInput(label1, controller1, isNumeric: isNumeric)),
        const SizedBox(width: 15),
        Expanded(child: _buildInput(label2, controller2, isNumeric: isNumeric)),
      ],
    );
  }

  void limpiarFormulario() {
    raicesAController.clear();
    raicesBController.clear();
    pesoAController.clear();
    pesoBController.clear();
    pesoHojasController.clear();
    ndviController.clear();
    observacionesController.clear();
  }

  void irAEvaluacionDano() {
    final cantidadA = int.tryParse(raicesAController.text.trim()) ?? 0;
    final cantidadB = int.tryParse(raicesBController.text.trim()) ?? 0;
    final totalRaices = cantidadA + cantidadB;

    final parcela = parcelas[currentIndex];

    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => EvaluacionDanoScreen(
              parcelaRef: parcela.reference,
              totalRaices: totalRaices,
              ciudadId: widget.ciudadId, // 👈 agregado
              serieId: widget.serieId,
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (parcelas.isEmpty) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    final parcela = parcelas[currentIndex];
    final String fechaActual = DateFormat('yyyy-MM-dd').format(DateTime.now());

    final cantidadA = int.tryParse(raicesAController.text.trim()) ?? 0;
    final cantidadB = int.tryParse(raicesBController.text.trim()) ?? 0;
    final totalRaices = cantidadA + cantidadB;

    final pesoA = double.tryParse(pesoAController.text.trim()) ?? 0.0;
    final pesoB = double.tryParse(pesoBController.text.trim()) ?? 0.0;
    final pesoTotal = pesoA + pesoB;

    final parcelaData =
        parcelas.isNotEmpty
            ? parcelas[currentIndex].data() as Map<String, dynamic>
            : <String, dynamic>{};

    final numeroFicha =
        parcelaData.containsKey('numero_ficha')
            ? parcelaData['numero_ficha']?.toString() ?? '-'
            : '-';

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "T ${parcelas[currentIndex]['numero_tratamiento']} - BLOQUE ${nombresBloques[parcelas[currentIndex].reference.parent.parent!.id] ?? '...'}",
              style: const TextStyle(fontSize: 20, color: Colors.white),
            ),

            if (ciudad != null && serie != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    ciudad!['nombre'],
                    style: const TextStyle(fontSize: 16, color: Colors.white),
                  ),
                  Text(
                    serie!['nombre'],
                    style: const TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ],
              ),
          ],
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "N° Ficha: $numeroFicha",
                    style: const TextStyle(
                      fontSize: 20,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    fechaActual,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 15),

              _buildInputPair(
                "N° Raíces 1",
                raicesAController,
                "N° Raíces 2",
                raicesBController,
                isNumeric: true,
              ),
              _buildInputPair(
                "Peso Raíces 1 (kg)",
                pesoAController,
                "Peso Raíces 2 (kg)",
                pesoBController,
                isNumeric: true,
              ),
              _buildInputPair(
                "Peso hojas (kg)",
                pesoHojasController,
                "NDVI",
                ndviController,
                isNumeric: true,
              ),
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white, width: 1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "TOTAL RAÍCES: $totalRaices",
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "TOTAL PESO RAÍCES: ${pesoTotal.toStringAsFixed(2)} kg",
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 12.0,
                  horizontal: 10,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Botón SIGUIENTE
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              await guardarTratamientoActual();

                              if (currentIndex < parcelas.length - 1) {
                                setState(() => currentIndex++);
                                await cargarTratamientoActual();
                              } else {
                                await guardarTratamientoActual();

                                final serieRef = FirebaseFirestore.instance
                                    .collection('ciudades')
                                    .doc(widget.ciudadId)
                                    .collection('series')
                                    .doc(widget.serieId);

                                await serieRef.update({
                                  'fecha_cosecha': Timestamp.now(),
                                });

                                showDialog(
                                  context: context,
                                  barrierDismissible: false,
                                  builder:
                                      (context) => AlertDialog(
                                        title: const Text(
                                          "¡Tratamiento Finalizado!",
                                        ),
                                        content: const Text(
                                          "Has terminado todas las parcelas de todos los bloques.",
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () {
                                              Navigator.of(
                                                context,
                                              ).pushAndRemoveUntil(
                                                MaterialPageRoute(
                                                  builder:
                                                      (_) =>
                                                          const InicioTratamientoScreen(),
                                                ),
                                                (route) => false,
                                              );
                                            },
                                            child: const Text(
                                              "Volver al inicio",
                                            ),
                                          ),
                                        ],
                                      ),
                                );
                              }
                            },
                            icon: const Icon(
                              Icons.save_alt,
                              size: 34,
                              color: Colors.white,
                            ),
                            label: const Text(
                              "SIGUIENTE ➡️",
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.white,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 30,
                                vertical: 10,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 15),
              _buildInput(
                "Observaciones",
                observacionesController,
                maxLines: 1,
              ),

              const SizedBox(height: 15),
              Row(
                children: [
                  // Botón LIMPIAR DATOS
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          raicesAController.clear();
                          raicesBController.clear();
                          pesoAController.clear();
                          pesoBController.clear();
                          pesoHojasController.clear();
                          ndviController.clear();
                          observacionesController.clear();
                          mensaje = "🧹 Formulario limpiado.";
                          focusedController = null;
                        });
                      },
                      icon: const Icon(
                        Icons.delete_forever,
                        color: Colors.white,
                        size: 20,
                      ),
                      label: const Text(
                        "LIMPIAR DATOS",
                        style: TextStyle(fontSize: 15, color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 16), // Espacio entre los botones
                  // Botón QUINLEI
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: irAEvaluacionDano,
                      icon: const Icon(
                        Icons.analytics_outlined,
                        size: 20,
                        color: Colors.white,
                      ),
                      label: const Text(
                        "QUINLEI",
                        style: TextStyle(fontSize: 15, color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueGrey,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              if (mensaje.isNotEmpty)
                Center(
                  child: Text(
                    mensaje,
                    style: TextStyle(
                      fontSize: 24,
                      color:
                          mensaje.startsWith("✅")
                              ? Colors.greenAccent
                              : Colors.redAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class CustomNumPad extends StatefulWidget {
  final String initialValue;
  final Function(String) onChanged;

  const CustomNumPad({
    Key? key,
    required this.initialValue,
    required this.onChanged,
  }) : super(key: key);

  @override
  State<CustomNumPad> createState() => _CustomNumPadState();
}

class _CustomNumPadState extends State<CustomNumPad> {
  late String current;

  @override
  void initState() {
    super.initState();
    current = widget.initialValue;
  }

  void _input(String val) {
    setState(() {
      current += val;
      widget.onChanged(current); // Actualiza en tiempo real
    });
  }

  void _backspace() {
    setState(() {
      if (current.isNotEmpty) {
        current = current.substring(0, current.length - 1);
        widget.onChanged(current);
      }
    });
  }

  void _submit() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final keys = [
      '7',
      '8',
      '9',
      '4',
      '5',
      '6',
      '1',
      '2',
      '3',
      '0',
      '.',
      'BORRAR',
    ];

    return Container(
      color: Colors.black,
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 18),
            decoration: BoxDecoration(
              color: Colors.black,
              border: Border.all(color: Colors.white, width: 3),
            ),
            child: Text(
              current,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 46,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 24),
          GridView.builder(
            shrinkWrap: true,
            itemCount: keys.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.6,
            ),
            itemBuilder: (context, index) {
              final key = keys[index];
              return ElevatedButton(
                onPressed: () {
                  if (key == 'BORRAR') {
                    _backspace();
                  } else {
                    _input(key);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: key == 'BORRAR' ? Colors.red : Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                child: Text(key),
              );
            },
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                textStyle: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              child: const Text("ACEPTAR"),
            ),
          ),
        ],
      ),
    );
  }
}

class CustomNDVIPad extends StatefulWidget {
  final String initialValue;
  final Function(String) onChanged;

  const CustomNDVIPad({
    Key? key,
    required this.initialValue,
    required this.onChanged,
  }) : super(key: key);

  @override
  State<CustomNDVIPad> createState() => _CustomNDVIPadState();
}

class _CustomNDVIPadState extends State<CustomNDVIPad> {
  late String current;
  String? error;

  @override
  void initState() {
    super.initState();
    current = widget.initialValue;
    _validate();
  }

  void _input(String val) {
    setState(() {
      if (val == '.' && current.contains('.')) return;
      current += val;
      _validate();
    });
  }

  void _backspace() {
    setState(() {
      if (current.isNotEmpty) {
        current = current.substring(0, current.length - 1);
        _validate();
      }
    });
  }

  void _validate() {
    final value = double.tryParse(current);
    if (value == null || value < 0 || value > 1) {
      error = "Debe estar entre 0.00 y 1.00";
    } else {
      error = null;
    }
    widget.onChanged(current);
  }

  void _submit() {
    _validate();
    if (error == null) {
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.redAccent,
          content: Text(error!, style: const TextStyle(fontSize: 20)),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final keys = [
      '7',
      '8',
      '9',
      '4',
      '5',
      '6',
      '1',
      '2',
      '3',
      '0',
      '.',
      'BORRAR',
    ];

    return Container(
      color: Colors.black,
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            decoration: BoxDecoration(
              border: Border.all(
                color: error == null ? Colors.white : Colors.red,
                width: 3,
              ),
            ),
            child: Text(
              current,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 50,
                color: error == null ? Colors.white : Colors.redAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 8),
          if (error != null)
            Text(
              error!,
              style: const TextStyle(color: Colors.redAccent, fontSize: 20),
            ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            itemCount: keys.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.6,
            ),
            itemBuilder: (context, index) {
              final key = keys[index];
              return ElevatedButton(
                onPressed: () => key == 'BORRAR' ? _backspace() : _input(key),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 0, 0, 0),
                  foregroundColor:
                      key == 'BORRAR'
                          ? Colors.red
                          : const Color.fromARGB(255, 255, 255, 255),
                  textStyle: const TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                child: Text(key),
              );
            },
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text(
                "ACEPTAR",
                style: TextStyle(fontSize: 24, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
