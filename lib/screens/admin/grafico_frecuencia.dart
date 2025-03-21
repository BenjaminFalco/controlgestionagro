import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class GraficoFrecuencia extends StatefulWidget {
  const GraficoFrecuencia({super.key});

  @override
  State<GraficoFrecuencia> createState() => _GraficoFrecuenciaState();
}

class _GraficoFrecuenciaState extends State<GraficoFrecuencia> {
  String? ciudadSeleccionada;
  String? serieSeleccionada;

  List<QueryDocumentSnapshot> ciudades = [];
  List<QueryDocumentSnapshot> series = [];
  List<_DatoParcela> datosParcela = [];

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

  Future<void> cargarFrecuencias() async {
    if (ciudadSeleccionada == null || serieSeleccionada == null) return;

    List<_DatoParcela> tempDatos = [];

    for (var bloque in ['A', 'B', 'C', 'D']) {
      final snapshot =
          await FirebaseFirestore.instance
              .collection('ciudades')
              .doc(ciudadSeleccionada)
              .collection('series')
              .doc(serieSeleccionada)
              .collection('bloques')
              .doc(bloque)
              .collection('parcelas')
              .orderBy('numero')
              .get();

      for (var doc in snapshot.docs) {
        final frecuencia = doc['frecuencia_relativa'];
        if (frecuencia != null) {
          tempDatos.add(
            _DatoParcela(
              bloque: bloque,
              numero: doc['numero'],
              valor: (frecuencia as num).toDouble(),
            ),
          );
        }
      }
    }

    setState(() {
      datosParcela = tempDatos;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Gráfico Frecuencia Relativa")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
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
                  datosParcela = [];
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
                  datosParcela = [];
                });
                cargarFrecuencias();
              },
            ),
            const SizedBox(height: 20),
            Expanded(
              child:
                  datosParcela.isEmpty
                      ? const Center(child: Text("No hay datos para mostrar."))
                      : BarChart(
                        BarChartData(
                          barGroups:
                              datosParcela
                                  .asMap()
                                  .entries
                                  .map(
                                    (entry) => BarChartGroupData(
                                      x: entry.key,
                                      barRods: [
                                        BarChartRodData(
                                          toY: entry.value.valor,
                                          width: 12,
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                  .toList(),
                          titlesData: FlTitlesData(
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (double value, _) {
                                  int i = value.toInt();
                                  if (i >= 0 && i < datosParcela.length) {
                                    final d = datosParcela[i];
                                    return Text(
                                      "${d.bloque}${d.numero}",
                                      style: const TextStyle(fontSize: 10),
                                    );
                                  }
                                  return const Text("");
                                },
                              ),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 28,
                              ),
                            ),
                            rightTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            topTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                          ),
                          borderData: FlBorderData(show: false),
                          gridData: FlGridData(show: true),
                        ),
                      ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DatoParcela {
  final String bloque;
  final int numero;
  final double valor;

  _DatoParcela({
    required this.bloque,
    required this.numero,
    required this.valor,
  });
}
