import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'evaluacion_dano.dart';
import 'package:intl/intl.dart';

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

  final TextEditingController raicesController = TextEditingController();
  final TextEditingController pesoRaicesController = TextEditingController();
  final TextEditingController pesoHojasController = TextEditingController();
  final TextEditingController ndviController = TextEditingController();
  final TextEditingController observacionesController = TextEditingController();

  String mensaje = '';
  List<Map<String, dynamic>> registros = [];
  String? nombreTrabajador;
  String? ciudadNombre;
  String? serieNombre;

  @override
  void initState() {
    super.initState();
    cargarNombreTrabajador();
    cargarParcelasDesde().then((_) => cargarUltimoTratamiento());
    obtenerNombres();
  }

  bool secuenciaInversa = true;

  void cambiarSecuencia() {
    setState(() {
      secuenciaInversa = !secuenciaInversa;
    });
  }

  void avanzarParcela() {
    if (secuenciaInversa) {
      // Derecha a izquierda (como está ahora)
      if (currentIndex < parcelas.length - 1) {
        setState(() {
          currentIndex++;
          registros.clear();
          mensaje = '';
        });
      } else {
        Navigator.pop(context);
      }
    } else {
      // Izquierda a derecha
      if (currentIndex > 0) {
        setState(() {
          currentIndex--;
          registros.clear();
          mensaje = '';
        });
      } else {
        Navigator.pop(context);
      }
    }
  }

  Future<void> cargarNombreTrabajador() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final snapshot =
        await FirebaseFirestore.instance.collection('usuarios').doc(uid).get();

    setState(() {
      nombreTrabajador =
          snapshot.data()?['nombre'] ??
          FirebaseAuth.instance.currentUser?.email ??
          'Desconocido';
    });
  }

  Future<void> cargarParcelasDesde() async {
    final snapshot =
        await FirebaseFirestore.instance
            .collection('ciudades')
            .doc(widget.ciudadId)
            .collection('series')
            .doc(widget.serieId)
            .collection('bloques')
            .doc(widget.bloqueId)
            .collection('parcelas')
            .orderBy('numero')
            .get();

    final todas = snapshot.docs;
    final desde = todas.indexWhere((p) => p['numero'] == widget.parcelaDesde);
    setState(() {
      parcelas = todas.sublist(desde);
    });
  }

  void agregarRegistro() {
    final cantidad = int.tryParse(raicesController.text.trim());
    final peso = double.tryParse(pesoRaicesController.text.trim());
    final hojas = double.tryParse(pesoHojasController.text.trim());
    final ndvi = int.tryParse(ndviController.text.trim());
    final observaciones = observacionesController.text.trim();

    if (cantidad == null || peso == null || hojas == null || ndvi == null) {
      setState(
        () => mensaje = "⚠️ Todos los campos numéricos deben ser válidos.",
      );
      return;
    }

    final trabajador = FirebaseAuth.instance.currentUser;
    if (trabajador == null) return;

    setState(() {
      registros.add({
        "nombre": trabajador.email,
        "cantidad": cantidad,
        "peso": peso,
        "bloque": widget.bloqueId,
      });
      mensaje = '';
      raicesController.clear();
      pesoRaicesController.clear();
      pesoHojasController.clear();
      ndviController.clear();
      observacionesController.clear();
    });
  }

  Future<void> obtenerNombres() async {
    try {
      final ciudadDoc =
          await FirebaseFirestore.instance
              .collection('ciudades')
              .doc(widget.ciudadId)
              .get();
      final serieDoc =
          await FirebaseFirestore.instance
              .collection('ciudades')
              .doc(widget.ciudadId)
              .collection('series')
              .doc(widget.serieId)
              .get();

      setState(() {
        ciudadNombre = ciudadDoc.data()?['nombre'] ?? 'Ciudad';
        serieNombre = serieDoc.data()?['nombre'] ?? 'Serie';
      });
    } catch (e) {
      setState(() {
        ciudadNombre = 'Ciudad';
        serieNombre = 'Serie';
      });
    }
  }

  Future<void> cargarUltimoTratamiento() async {
    if (parcelas.isEmpty) return;

    final parcela = parcelas[currentIndex];
    final snap =
        await parcela.reference
            .collection('tratamientos')
            .orderBy('fecha', descending: true)
            .limit(1)
            .get();

    if (snap.docs.isNotEmpty) {
      final data = snap.docs.first.data();
      final detalle = data['detalle'] as List<dynamic>?;

      if (detalle != null) {
        setState(() {
          registros =
              detalle
                  .whereType<Map<String, dynamic>>()
                  .map(
                    (r) => {
                      'nombre': r['nombre'] ?? 'Desconocido',
                      'cantidad': r['cantidad'] as int? ?? 0,
                      'peso':
                          r['peso'] is num
                              ? (r['peso'] as num).toDouble()
                              : 0.0,
                    },
                  )
                  .toList();
        });
      }
    }
  }

  Future<void> guardarTratamiento() async {
    final parcela = parcelas[currentIndex];
    final totalRaices = registros.fold<int>(
      0,
      (sum, r) => sum + (r['cantidad'] as int? ?? 0),
    );
    final totalPeso = registros.fold<double>(
      0.0,
      (sum, r) => sum + (r['peso'] as double? ?? 0.0),
    );

    try {
      await parcela.reference.collection('tratamientos').add({
        "trabajador_id": FirebaseAuth.instance.currentUser?.uid,
        "nombre":
            registros.isNotEmpty ? registros.last['nombre'] : 'Desconocido',
        "detalle": registros,
        "fecha": Timestamp.now(),
        "total_raices": totalRaices,
        "peso_total_raices": totalPeso,
      });

      setState(() {
        mensaje = "✅ Tratamiento guardado.";
        registros = [];
      });

      avanzarParcela();
    } catch (e) {
      setState(() {
        mensaje = "❌ Error al guardar: ${e.toString()}";
      });
    }
  }

  Future<void> reiniciarTratamiento() async {
    final parcela = parcelas[currentIndex];
    final snap = await parcela.reference.collection('tratamientos').get();

    for (final doc in snap.docs) {
      await doc.reference.delete();
    }

    setState(() {
      registros.clear();
      mensaje = "⚠️ Tratamiento eliminado.";
    });
  }

  void confirmarYSiguiente() {
    if (registros.isEmpty) {
      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text("¿Avanzar sin guardar?"),
              content: const Text(
                "Aún no has registrado ningún dato en esta parcela.",
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancelar"),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    if (currentIndex < parcelas.length - 1) {
                      setState(() {
                        registros.clear();
                        mensaje = '';
                        currentIndex++;
                      });
                    }
                  },
                  child: const Text("Avanzar"),
                ),
              ],
            ),
      );
    } else {
      if (currentIndex < parcelas.length - 1) {
        setState(() {
          registros.clear();
          mensaje = '';
          currentIndex++;
        });
      }
    }
  }

  void irAEvaluacionDano() {
    final totalRaices = registros.fold<int>(
      0,
      (sum, r) => sum + (r['cantidad'] as int? ?? 0),
    );
    final parcela = parcelas[currentIndex];

    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => EvaluacionDanoScreen(
              parcelaRef: parcela.reference,
              totalRaices: totalRaices,
            ),
      ),
    );
  }

  Widget _buildInput(
    String label,
    TextEditingController controller, {
    int maxLines = 1,
  }) {
    return SizedBox(
      width: 300,
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: const TextStyle(fontSize: 18, color: Colors.black),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(fontSize: 18, color: Colors.black),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (parcelas.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final parcela = parcelas[currentIndex];
    final String fechaActual = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final totalRaices = registros.fold<int>(
      0,
      (sum, r) => sum + (r['cantidad'] as int? ?? 0),
    );
    final totalPeso = registros.fold<double>(
      0.0,
      (sum, r) => sum + (r['peso'] as double? ?? 0.0),
    );

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                "Parcela ${parcela['numero']} - Bloque ${widget.bloqueId}",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Ciudad: ${ciudadNombre ?? '...'}",
                  style: const TextStyle(fontSize: 20, color: Colors.white70),
                ),
                Text(
                  "Serie: ${serieNombre ?? '...'}",
                  style: const TextStyle(fontSize: 20, color: Colors.white70),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "📅 Fecha: $fechaActual",
                    style: const TextStyle(fontSize: 20, color: Colors.white),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text("🧾", style: TextStyle(fontSize: 20)),
                          const SizedBox(width: 8),
                          Text(
                            "N° Ficha: ${widget.numeroFicha}",
                            style: const TextStyle(
                              fontSize: 20,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Text("🧪", style: TextStyle(fontSize: 20)),
                          const SizedBox(width: 8),
                          Text(
                            "N° Tratamiento: ${widget.numeroTratamiento}",
                            style: const TextStyle(
                              fontSize: 20,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                "Tratamiento de raíces (Parcela ${currentIndex + 1} de ${parcelas.length})",
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 20,
                runSpacing: 20,
                children: [
                  _buildInput("Cantidad de raíces", raicesController),
                  _buildInput("Peso raíces (kg)", pesoRaicesController),
                  _buildInput("Peso hojas (kg)", pesoHojasController),
                  _buildInput("NDVI", ndviController),
                  _buildInput(
                    "Observaciones",
                    observacionesController,
                    maxLines: 2,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Center(
                child: ElevatedButton.icon(
                  onPressed: agregarRegistro,
                  icon: const Icon(Icons.add, size: 28, color: Colors.black),
                  label: const Text(
                    "",
                    style: TextStyle(fontSize: 18, color: Colors.black),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              registros.isEmpty
                  ? const Center(
                    child: Text(
                      "No hay datos aún.",
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  )
                  : Column(
                    children:
                        registros.map((r) {
                          return Card(
                            color: Colors.white,
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            child: ListTile(
                              title: const Text(
                                "Nuevo registro",
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.black,
                                ),
                              ),
                              subtitle: Text(
                                "Raíces: ${r['cantidad']} | Peso: ${r['peso']} kg",
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                  ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Total raíces: $totalRaices",
                      style: const TextStyle(fontSize: 18, color: Colors.black),
                    ),
                    Text(
                      "Total peso raíces: ${totalPeso.toStringAsFixed(2)} kg",
                      style: const TextStyle(fontSize: 18, color: Colors.black),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: irAEvaluacionDano,
                    icon: const Icon(Icons.analytics, color: Colors.black),
                    label: const Text(
                      "QUINLEI",
                      style: TextStyle(color: Colors.black),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: guardarTratamiento,
                    icon: const Icon(Icons.save, color: Colors.black),
                    label: const Text(
                      "Guardar",
                      style: TextStyle(color: Colors.black),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: reiniciarTratamiento,
                    icon: const Icon(Icons.refresh),
                    label: const Text("Reiniciar"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade600,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: cambiarSecuencia,
                    icon: const Icon(Icons.swap_horiz),
                    label: Text(
                      secuenciaInversa
                          ? "Secuencia: Derecha → Izquierda"
                          : "Secuencia: Izquierda → Derecha",
                      style: const TextStyle(color: Colors.black),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (mensaje.isNotEmpty)
                Center(
                  child: Text(
                    mensaje,
                    style: TextStyle(
                      fontSize: 16,
                      color:
                          mensaje.startsWith("✅") ? Colors.green : Colors.red,
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
