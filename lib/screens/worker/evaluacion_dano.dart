import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:audioplayers/audioplayers.dart';

class EvaluacionDanoScreen extends StatefulWidget {
  final DocumentReference parcelaRef;
  final int totalRaices;

  const EvaluacionDanoScreen({
    super.key,
    required this.parcelaRef,
    required this.totalRaices,
  });

  @override
  State<EvaluacionDanoScreen> createState() => _EvaluacionDanoScreenState();
}

class _EvaluacionDanoScreenState extends State<EvaluacionDanoScreen> {
  final AudioPlayer player = AudioPlayer();
  final TextEditingController cantidadController = TextEditingController();
  int evaluadas = 0;
  int faltan = 0;
  List<int> historialEvaluaciones = [];

  Map<int, int> evaluaciones = {}; // nota -> cantidad
  String mensaje = '';

  @override
  void initState() {
    super.initState();
    cargarEvaluacionDesdeFirestore(); // <- aquí se carga la evaluación previa
  }

  Widget _buildNotaButton(int nota) {
    return ElevatedButton(
      onPressed: faltan > 0 ? () => agregarEvaluacion(nota) : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color.fromARGB(255, 213, 182, 9),
        padding: const EdgeInsets.symmetric(horizontal: 150, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(
        "$nota",
        style: const TextStyle(
          fontSize: 40,
          color: Color.fromARGB(255, 0, 0, 0),
        ),
      ),
    );
  }

  Future<void> agregarEvaluacion(int nota) async {
    final cantidad = int.tryParse(cantidadController.text.trim());
    if (cantidad == null || cantidad <= 0 || cantidad > faltan) {
      setState(() {
        mensaje = "⚠️ Ingresa una cantidad válida (restantes: $faltan).";
      });
      return;
    }

    setState(() {
      evaluaciones.update(
        nota,
        (value) => value + cantidad,
        ifAbsent: () => cantidad,
      );
      cantidadController.clear();
      mensaje = '';
    });

    // 🔊 Feedback sonoro
    await player.play(AssetSource('sounds/beep.mp3'));
  }

  void borrarUltimo() {
    if (historialEvaluaciones.isNotEmpty) {
      final ultimaNota = historialEvaluaciones.removeLast();

      setState(() {
        final cantidadActual = evaluaciones[ultimaNota] ?? 0;
        if (cantidadActual > 1) {
          evaluaciones[ultimaNota] = cantidadActual - 1;
        } else {
          evaluaciones.remove(ultimaNota);
        }
      });
    }
  }

  void reiniciarEvaluacion() {
    setState(() {
      evaluaciones.clear();
      mensaje = '';
    });
  }

  Future<void> guardarEvaluacion() async {
    try {
      int suma = evaluaciones.entries
          .map((e) => e.key * e.value)
          .fold(0, (a, b) => a + b);

      double frecuencia =
          widget.totalRaices == 0 ? 0.0 : suma / (widget.totalRaices * 7);

      await widget.parcelaRef.update({
        "evaluacion": evaluaciones.map(
          (key, value) => MapEntry(key.toString(), value),
        ),
        "frecuencia_relativa": double.parse(frecuencia.toStringAsFixed(3)),
      });

      await player.play(AssetSource('sounds/done.mp3'));

      if (context.mounted) {
        showDialog(
          context: context,
          builder:
              (_) => AlertDialog(
                title: const Text("✅ Guardado exitoso"),
                content: const Text(
                  "La evaluación ha sido guardada correctamente.",
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // solo cierra modal
                    },
                    child: const Text("Aceptar"),
                  ),
                ],
              ),
        );
      }

      await cargarEvaluacionDesdeFirestore(); // Refresca evaluación
    } catch (e) {
      setState(() => mensaje = "❌ Error al guardar: $e");
    }
  }

  Future<void> cargarEvaluacionDesdeFirestore() async {
    try {
      final doc = await widget.parcelaRef.get();
      final data = doc.data() as Map<String, dynamic>?;

      if (data != null && data['evaluacion'] != null) {
        final mapa = Map<String, dynamic>.from(data['evaluacion']);
        setState(() {
          evaluaciones = mapa.map((k, v) => MapEntry(int.parse(k), v as int));
        });
      }
    } catch (e) {
      setState(() => mensaje = "❌ Error al cargar evaluación: $e");
    }
  }

  void _confirmarAvance() {
    final int totalEvaluadas = evaluaciones.values.fold(0, (a, b) => a + b);

    if (totalEvaluadas < widget.totalRaices) {
      showDialog(
        context: context,
        builder:
            (_) => AlertDialog(
              title: const Text("Evaluación incompleta"),
              content: Text(
                "Has evaluado $totalEvaluadas de ${widget.totalRaices} raíces. Completa la evaluación antes de continuar.",
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

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("¿Avanzar a la siguiente parcela?"),
            content: const Text(
              "¿Deseas continuar? Esta acción no se puede deshacer.",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancelar"),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context); // Cierra modal
                  await guardarEvaluacion(); // Guarda

                  if (mounted && mensaje.isEmpty) {
                    Navigator.pop(
                      context,
                      'siguiente',
                    ); // ⬅️ Devuelve señal a formulario_tratamiento
                  }
                },
                child: const Text("Sí, continuar"),
              ),
            ],
          ),
    );
  }

  void _confirmarReinicio() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("¿Reiniciar evaluación?"),
            content: const Text("Se eliminarán todos los datos actuales."),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancelar"),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  reiniciarEvaluacion();
                },
                child: const Text("Sí, reiniciar"),
              ),
            ],
          ),
    );
  }

  Widget build(BuildContext context) {
    int totalRaices = evaluaciones.values.fold(0, (a, b) => a + b);
    final bool completado = totalRaices >= widget.totalRaices;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          "QUINLEI - Evaluación de daño",
          style: TextStyle(color: Colors.black),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              Text(
                "Raíces a evaluar: ${widget.totalRaices}",
                style: const TextStyle(color: Colors.white, fontSize: 30),
              ),

              if (completado)
                Padding(
                  padding: const EdgeInsets.only(top: 12.0),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.redAccent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      "✅ Evaluación completa. No puedes ingresar más datos.",
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ),
              const SizedBox(height: 24),

              GridView.count(
                shrinkWrap: true,
                crossAxisCount: 4,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.1,
                physics: const NeverScrollableScrollPhysics(),
                children: List.generate(8, (index) {
                  final cantidad = evaluaciones[index] ?? 0;
                  return GestureDetector(
                    onTap:
                        completado
                            ? null
                            : () async {
                              setState(() {
                                evaluaciones[index] =
                                    (evaluaciones[index] ?? 0) + 1;
                                historialEvaluaciones.add(index);
                              });

                              await player.play(AssetSource('sounds/beep.mp3'));
                            },
                    child: Stack(
                      children: [
                        // Fondo del botón
                        Container(
                          decoration: BoxDecoration(
                            color:
                                completado
                                    ? Colors.grey.shade800
                                    : const Color.fromARGB(255, 0, 0, 0),
                            border: Border.all(color: Colors.white, width: 2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            "$index",
                            style: const TextStyle(
                              fontSize: 80,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                        // Contador amarillo al fondo, pegado al borde inferior
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.yellow.shade700,
                              borderRadius: const BorderRadius.only(
                                bottomLeft: Radius.circular(10),
                                bottomRight: Radius.circular(10),
                              ),
                            ),
                            child: Center(
                              child: Text(
                                "$cantidad",
                                style: const TextStyle(
                                  fontSize: 28,
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),

              const SizedBox(height: 20),

              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 40,
                ),
                child: Text(
                  "Total Raíces: $totalRaices ",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: guardarEvaluacion,
                  icon: const Icon(Icons.save),
                  label: const Text(
                    "Guardar evaluación",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF04bc04),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),
              const Divider(color: Colors.white38),

              Text(
                "Frecuencia acumulada",
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 20),

              if (evaluaciones.isNotEmpty)
                Center(
                  child: SizedBox(
                    height: 200,
                    width: 200,
                    child: PieChart(
                      PieChartData(
                        centerSpaceRadius: 30,
                        sectionsSpace: 2,
                        sections:
                            evaluaciones.entries.map((entry) {
                              final nota = entry.key;
                              final cantidad = entry.value;
                              final porcentaje = cantidad / widget.totalRaices;
                              final porcentajeTexto = (porcentaje * 100)
                                  .toStringAsFixed(1);

                              return PieChartSectionData(
                                value: porcentaje,
                                color:
                                    Colors.primaries[nota %
                                        Colors.primaries.length],
                                radius: 60,
                                title: "$nota\n$porcentajeTexto%",
                                titleStyle: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              );
                            }).toList(),
                      ),
                    ),
                  ),
                )
              else
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    "Sin datos aún.",
                    style: TextStyle(color: Colors.white54, fontSize: 18),
                  ),
                ),

              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  OutlinedButton.icon(
                    onPressed: borrarUltimo,
                    icon: const Icon(Icons.undo, color: Colors.red),
                    label: const Text(
                      "Borrar último",
                      style: TextStyle(color: Colors.white),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 26,
                        vertical: 28,
                      ),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: _confirmarReinicio,
                    icon: const Icon(Icons.restart_alt, color: Colors.white),
                    label: const Text(
                      "Reiniciar",
                      style: TextStyle(color: Colors.white),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 26,
                        vertical: 28,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              if (mensaje.isNotEmpty)
                Text(
                  mensaje,
                  style: TextStyle(
                    fontSize: 16,
                    color:
                        mensaje.startsWith("✅")
                            ? Colors.greenAccent
                            : Colors.red,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
