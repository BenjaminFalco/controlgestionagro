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

  int get evaluadas => evaluaciones.values.fold(0, (a, b) => a + b);
  int get faltan => widget.totalRaices - evaluadas;

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
    await player.play(AssetSource('sounds/click.mp3'));
  }

  void borrarUltimo() {
    if (evaluaciones.isNotEmpty) {
      final ultimaClave = evaluaciones.keys.last;
      setState(() {
        evaluaciones.remove(ultimaClave);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(title: const Text("QUINLEI - Evaluación de daño")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "🔢 Daño evaluado: $evaluadas / ${widget.totalRaices}",
              style: const TextStyle(color: Colors.white),
            ),
            Text(
              "⏳ Faltan: $faltan raíces",
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: cantidadController,
              readOnly: true, // <- evita teclado Android
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: "Cantidad de raíces",
                labelStyle: TextStyle(color: Colors.white70),
                filled: true,
                fillColor: Colors.black12,
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: List.generate(10, (index) {
                return ElevatedButton(
                  onPressed: () {
                    setState(() {
                      cantidadController.text += index.toString();
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: 18,
                    ),
                    backgroundColor: Colors.blueGrey[800],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    "$index",
                    style: const TextStyle(fontSize: 24, color: Colors.white),
                  ),
                );
              }),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  final texto = cantidadController.text;
                  if (texto.isNotEmpty) {
                    cantidadController.text = texto.substring(
                      0,
                      texto.length - 1,
                    );
                  }
                });
              },
              icon: const Icon(Icons.backspace),
              label: const Text("Borrar dígito"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
              ),
            ),

            const SizedBox(height: 5),

            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children:
                      [7, 6, 5].map((nota) => _buildNotaButton(nota)).toList(),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children:
                      [4, 3, 2].map((nota) => _buildNotaButton(nota)).toList(),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children:
                      [1, 0].map((nota) => _buildNotaButton(nota)).toList(),
                ),
              ],
            ),

            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                OutlinedButton.icon(
                  onPressed: borrarUltimo,
                  icon: const Icon(
                    Icons.undo,
                    color: Color.fromARGB(255, 255, 0, 0),
                  ),
                  label: const Text(
                    "Borrar último",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: reiniciarEvaluacion,
                  icon: const Icon(Icons.restart_alt, color: Colors.white),
                  label: const Text(
                    "Reiniciar",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),
            const Divider(color: Colors.white38),

            Text(
              "📊 Frecuencia acumulada",
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: Colors.white),
            ),

            const SizedBox(height: 10),
            Expanded(
              child:
                  evaluaciones.isEmpty
                      ? const Center(
                        child: Text(
                          "Sin datos aún.",
                          style: TextStyle(color: Colors.white54),
                        ),
                      )
                      : ListView(
                        children:
                            evaluaciones.entries.map((entry) {
                              final porcentaje = (entry.value /
                                      widget.totalRaices *
                                      100)
                                  .toStringAsFixed(1);
                              return ListTile(
                                title: Text(
                                  "Nota ${entry.key}",
                                  style: const TextStyle(color: Colors.white),
                                ),
                                subtitle: Text(
                                  "Cantidad: ${entry.value} | ${porcentaje}%",
                                  style: const TextStyle(color: Colors.white70),
                                ),
                              );
                            }).toList(),
                      ),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: guardarEvaluacion,
              icon: const Icon(Icons.save),
              label: const Text("Guardar evaluación"),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(60),
                backgroundColor: const Color.fromARGB(255, 23, 165, 25),
              ),
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
