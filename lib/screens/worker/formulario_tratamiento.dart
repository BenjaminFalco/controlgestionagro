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

  @override
  void initState() {
    super.initState();
    cargarNombreTrabajador();
    cargarParcelasDesde().then((_) => cargarRegistrosTratamiento());
  }

  Future<void> cargarNombreTrabajador() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final snapshot =
        await FirebaseFirestore.instance.collection('usuarios').doc(uid).get();

    setState(() {
      nombreTrabajador = snapshot['nombre'] ?? 'Desconocido';
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

  Future<void> cargarRegistrosTratamiento() async {
    if (parcelas.isEmpty) return;

    final parcela = parcelas[currentIndex];
    final snap = await parcela.reference.collection('tratamientos').get();

    final List<Map<String, dynamic>> nuevosRegistros = [];

    for (var doc in snap.docs) {
      final data = doc.data();
      final detalle = data['detalle'] as List<dynamic>?;

      if (detalle != null) {
        for (var r in detalle) {
          if (r is Map<String, dynamic>) {
            nuevosRegistros.add({
              'nombre': r['nombre'] ?? 'Desconocido',
              'cantidad': r['cantidad'] as int? ?? 0,
              'peso': r['peso'] is num ? (r['peso'] as num).toDouble() : 0.0,
            });
          }
        }
      }
    }

    setState(() {
      registros = nuevosRegistros;
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
      });
      mensaje = '';
      raicesController.clear();
      pesoRaicesController.clear();
      pesoHojasController.clear();
      ndviController.clear();
      observacionesController.clear();
    });
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
      });

      if (currentIndex < parcelas.length - 1) {
        setState(() {
          currentIndex++;
        });
      } else {
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() {
        mensaje = "❌ Error al guardar: ${e.toString()}";
      });
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
      appBar: AppBar(
        title: Text("Parcela ${parcela['numero']} - Bloque ${widget.bloqueId}"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("📅 Fecha: $fechaActual"),
            Text("🧾 N° Ficha: ${widget.numeroFicha}"),
            Text("🧪 N° Tratamiento: ${widget.numeroTratamiento}"),
            const SizedBox(height: 16),
            Text(
              "Tratamiento de raíces (Parcela ${currentIndex + 1} de ${parcelas.length})",
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: raicesController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Cantidad de raíces",
              ),
            ),
            TextField(
              controller: pesoRaicesController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(labelText: "Peso raíces (kg)"),
            ),
            TextField(
              controller: pesoHojasController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(labelText: "Peso hojas (kg)"),
            ),
            TextField(
              controller: ndviController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "NDVI"),
            ),
            TextField(
              controller: observacionesController,
              decoration: const InputDecoration(labelText: "Observaciones"),
              maxLines: 2,
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: agregarRegistro,
              icon: const Icon(Icons.add),
              label: const Text("Agregar tratamiento"),
            ),
            const SizedBox(height: 16),
            Expanded(
              child:
                  registros.isEmpty
                      ? const Center(child: Text("No hay datos aún."))
                      : ListView.builder(
                        itemCount: registros.length,
                        itemBuilder: (context, index) {
                          final r = registros[index];
                          return ListTile(
                            title: Text(r['nombre'] ?? 'Desconocido'),
                            subtitle: Text(
                              "Raíces: ${r['cantidad']} | Peso: ${r['peso']} kg",
                            ),
                          );
                        },
                      ),
            ),
            const Divider(),
            Text("Total raíces: $totalRaices"),
            Text("Total peso raíces: ${totalPeso.toStringAsFixed(2)} kg"),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: irAEvaluacionDano,
                  icon: const Icon(Icons.analytics),
                  label: const Text("QUINLEI"),
                ),
                ElevatedButton.icon(
                  onPressed: guardarTratamiento,
                  icon: const Icon(Icons.save),
                  label: const Text("Guardar"),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (mensaje.isNotEmpty)
              Text(
                mensaje,
                style: TextStyle(
                  color: mensaje.startsWith("✅") ? Colors.green : Colors.red,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
