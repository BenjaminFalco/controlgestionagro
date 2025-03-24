import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class EvaluacionDanoScreen extends StatefulWidget {
  final DocumentReference parcelaRef;
  final int totalRaices; // 🔹 NUEVO

  const EvaluacionDanoScreen({
    super.key,
    required this.parcelaRef,
    required this.totalRaices, // 🔹 NUEVO
  });

  @override
  State<EvaluacionDanoScreen> createState() => _EvaluacionDanoScreenState();
}

class _EvaluacionDanoScreenState extends State<EvaluacionDanoScreen> {
  final List<TextEditingController> evaluacionesControllers = [
    TextEditingController(),
  ];
  String mensaje = '';
  double frecuenciaRelativa = 0.0;

  void agregarCampo() {
    if (evaluacionesControllers.length >= widget.totalRaices) {
      setState(() {
        mensaje = "⚠️ Ya ingresaste todos los valores de daño posibles.";
      });
      return;
    }

    setState(() {
      evaluacionesControllers.add(TextEditingController());
      mensaje = '';
    });
  }

  void calcularFrecuencia() {
    List<double> valores = [];

    for (var c in evaluacionesControllers) {
      double? valor = double.tryParse(c.text.trim());
      if (valor == null || valor < 0 || valor > 7) {
        setState(() {
          mensaje = "⚠️ Todos los valores deben estar entre 0.0 y 7.0";
        });
        return;
      }
      valores.add(valor);
    }

    double suma = valores.fold(0, (a, b) => a + b);
    double resultado = suma / (valores.length * 7);

    setState(() {
      frecuenciaRelativa = double.parse(resultado.toStringAsFixed(3));
      mensaje = "✅ Frecuencia relativa: $frecuenciaRelativa";
    });
  }

  Future<void> guardarEvaluacion() async {
    try {
      List<double> valores =
          evaluacionesControllers
              .map((c) => double.parse(c.text.trim()))
              .toList();

      await widget.parcelaRef.collection('evaluacion_dano').add({
        "valores": valores,
        "frecuencia_relativa": frecuenciaRelativa,
        "fecha": FieldValue.serverTimestamp(),
      });

      await widget.parcelaRef.update({
        "evaluacion": valores,
        "frecuencia_relativa": frecuenciaRelativa,
      });

      setState(() {
        mensaje = "✅ Evaluación guardada correctamente.";
      });

      Navigator.pop(context);
    } catch (e) {
      setState(() {
        mensaje = "❌ Error: ${e.toString()}";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    int evaluacionesIngresadas = evaluacionesControllers.length;
    int evaluacionesRestantes = widget.totalRaices - evaluacionesIngresadas;

    return Scaffold(
      appBar: AppBar(title: const Text("Evaluación de daño")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Text(
              "🔢 Daño evaluado: $evaluacionesIngresadas / ${widget.totalRaices}",
            ),
            Text("⏳ Faltan: $evaluacionesRestantes raíces por evaluar"),
            const SizedBox(height: 10),
            ...evaluacionesControllers.asMap().entries.map((entry) {
              int index = entry.key;
              TextEditingController controller = entry.value;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: TextField(
                  controller: controller,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: "Valor ${index + 1}",
                    border: const OutlineInputBorder(),
                  ),
                ),
              );
            }).toList(),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: agregarCampo,
              icon: const Icon(Icons.add),
              label: const Text("Agregar otro valor"),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: calcularFrecuencia,
              icon: const Icon(Icons.calculate),
              label: const Text("Calcular frecuencia relativa"),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: guardarEvaluacion,
              icon: const Icon(Icons.save),
              label: const Text("Guardar evaluación"),
            ),
            const SizedBox(height: 10),
            Text(mensaje),
          ],
        ),
      ),
    );
  }
}
