import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:excel/excel.dart';

class GraficoFrecuencia extends StatefulWidget {
  const GraficoFrecuencia({super.key});

  @override
  State<GraficoFrecuencia> createState() => _GraficoFrecuenciaState();
}

class _GraficoFrecuenciaState extends State<GraficoFrecuencia> {
  String? ciudadSeleccionada;
  String? serieSeleccionada;
  String? bloqueSeleccionado;
  int? parcelaSeleccionada;

  List<QueryDocumentSnapshot> ciudades = [];
  List<QueryDocumentSnapshot> series = [];
  List<QueryDocumentSnapshot> bloques = [];
  List<int> parcelasUnicas = [];

  List<_DatoParcela> datosParcela = [];
  List<_DatoParcela> todasLasParcelas = [];
  Map<int, int> frecuenciaNotas = {};

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
      bloques = snapshot.docs;
    });
  }

  Future<void> cargarFrecuencias() async {
    if (ciudadSeleccionada == null || serieSeleccionada == null) return;

    List<_DatoParcela> tempDatos = [];
    Map<int, int> acumulador = {for (var i = 0; i <= 7; i++) i: 0};
    parcelasUnicas.clear();

    List<String> bloquesAFiltrar =
        bloqueSeleccionado != null
            ? [bloqueSeleccionado!]
            : bloques.map((b) => b.id).toList();

    for (var bloque in bloquesAFiltrar) {
      final snapshot =
          await FirebaseFirestore.instance
              .collection('ciudades')
              .doc(ciudadSeleccionada)
              .collection('series')
              .doc(serieSeleccionada)
              .collection('bloques')
              .doc(bloque)
              .collection('parcelas')
              .get();

      for (var doc in snapshot.docs) {
        final evaluaciones = doc['evaluacion'] as Map<String, dynamic>?;
        final numero = doc['numero'] ?? int.tryParse(doc.id);

        if (evaluaciones != null && numero != null) {
          int total = evaluaciones.values.fold(
            0,
            (suma, v) => suma + (v as int),
          );
          parcelasUnicas.add(numero);

          if (parcelaSeleccionada == null || parcelaSeleccionada == numero) {
            tempDatos.add(
              _DatoParcela(
                bloque: bloque,
                numero: numero,
                valor: total.toDouble(),
              ),
            );

            for (var i = 0; i <= 7; i++) {
              acumulador[i] =
                  acumulador[i]! + ((evaluaciones['$i'] ?? 0) as num).toInt();
            }
          }
        }
      }
    }

    parcelasUnicas = parcelasUnicas.toSet().toList()..sort();

    setState(() {
      todasLasParcelas = tempDatos;
      datosParcela = tempDatos;
      frecuenciaNotas = acumulador;
    });
  }

  Future<void> mostrarRutaExportacion(String ruta) async {
    await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("✅ Archivo exportado"),
            content: Text("Se ha guardado en:\n$ruta"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Entendido"),
              ),
            ],
          ),
    );
  }

  Future<void> exportarExcel() async {
    final excel = Excel.createExcel();
    final sheet = excel['Frecuencia'];
    sheet.appendRow(['Nota', 'Frecuencia']);
    for (var i = 0; i <= 7; i++) {
      sheet.appendRow([i, frecuenciaNotas[i] ?? 0]);
    }
    final bytes = excel.encode();
    final dir = await getApplicationDocumentsDirectory();
    final path = "${dir.path}/frecuencia_export.xlsx";
    final file = File(path)..writeAsBytesSync(bytes!);
    await mostrarRutaExportacion(path);
    Share.shareFiles([file.path], text: "Exportación de Frecuencia (Excel)");
  }

  Future<void> exportarPDF() async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        build:
            (pw.Context context) => pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  "Frecuencia por Nota",
                  style: pw.TextStyle(fontSize: 20),
                ),
                pw.SizedBox(height: 10),
                pw.Table(
                  border: pw.TableBorder.all(),
                  children: [
                    pw.TableRow(
                      children: [
                        pw.Center(child: pw.Text('Nota')),
                        pw.Center(child: pw.Text('Frecuencia')),
                      ],
                    ),
                    for (int i = 0; i <= 7; i++)
                      pw.TableRow(
                        children: [
                          pw.Center(child: pw.Text("$i")),
                          pw.Center(
                            child: pw.Text("${frecuenciaNotas[i] ?? 0}"),
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ),
      ),
    );

    final dir = await getApplicationDocumentsDirectory();
    final path = "${dir.path}/frecuencia_export.pdf";
    final file = File(path);
    await file.writeAsBytes(await pdf.save());
    await mostrarRutaExportacion(path);
    Share.shareFiles([file.path], text: "Exportación de Frecuencia (PDF)");
  }

  Future<void> exportarCSV() async {
    final csv = StringBuffer();
    csv.writeln("Nota,Frecuencia");
    for (var i = 0; i <= 7; i++) {
      csv.writeln("$i,${frecuenciaNotas[i] ?? 0}");
    }
    final dir = await getApplicationDocumentsDirectory();
    final path = "${dir.path}/frecuencia_export.csv";
    final file = File(path);
    await file.writeAsString(csv.toString());
    await mostrarRutaExportacion(path);
    Share.shareFiles([path], text: "Exportación de Frecuencia (CSV)");
  }

  @override
  Widget _buildDropdown<T>(
    String label,
    T? value,
    List<DropdownMenuItem<T>> items,
    void Function(T?) onChanged,
  ) {
    return DropdownButtonFormField<T>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          color: Colors.black, // <-- aquí el color del texto
          fontWeight: FontWeight.w500,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.black),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
      iconEnabledColor: Colors.black,
      dropdownColor: Colors.white,
      style: const TextStyle(color: Colors.black),
      items: items,
      onChanged: onChanged,
    );
  }

  @override
  Widget build(BuildContext context) {
    double promedio =
        datosParcela.isEmpty
            ? 0
            : datosParcela.map((e) => e.valor).reduce((a, b) => a + b) /
                datosParcela.length;
    double maximo =
        datosParcela.isEmpty
            ? 0
            : datosParcela.map((e) => e.valor).reduce((a, b) => a > b ? a : b);
    double minimo =
        datosParcela.isEmpty
            ? 0
            : datosParcela.map((e) => e.valor).reduce((a, b) => a < b ? a : b);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Gráfico Frecuencia Absoluta"),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildDropdown(
              "Localidad",
              ciudadSeleccionada,
              ciudades.map((doc) {
                return DropdownMenuItem(
                  value: doc.id,
                  child: Text(doc['nombre']),
                );
              }).toList(),
              (value) {
                setState(() {
                  ciudadSeleccionada = value;
                  serieSeleccionada = null;
                  bloqueSeleccionado = null;
                  datosParcela = [];
                  parcelaSeleccionada = null;
                });
                cargarSeries();
              },
            ),
            const SizedBox(height: 10),
            _buildDropdown(
              "Ensayo",
              serieSeleccionada,
              series.map((doc) {
                return DropdownMenuItem(
                  value: doc.id,
                  child: Text(doc['nombre']),
                );
              }).toList(),
              (value) {
                setState(() {
                  serieSeleccionada = value;
                  bloqueSeleccionado = null;
                  parcelaSeleccionada = null;
                  datosParcela = [];
                });
                cargarBloques();
              },
            ),
            const SizedBox(height: 10),
            _buildDropdown(
              "Bloque (opcional)",
              bloqueSeleccionado,
              bloques.map((b) {
                return DropdownMenuItem(
                  value: b.id,
                  child: Text("Bloque ${b.id}"),
                );
              }).toList(),
              (value) {
                setState(() {
                  bloqueSeleccionado = value;
                  parcelaSeleccionada = null;
                });
                cargarFrecuencias();
              },
            ),
            const SizedBox(height: 10),
            _buildDropdown(
              "Parcela (opcional)",
              parcelaSeleccionada,
              parcelasUnicas.map((n) {
                return DropdownMenuItem(value: n, child: Text("Parcela $n"));
              }).toList(),
              (value) {
                setState(() {
                  parcelaSeleccionada = value;
                });
                cargarFrecuencias();
              },
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Column(
                children: [
                  if (frecuenciaNotas.isEmpty)
                    const Center(child: Text("No hay datos para mostrar."))
                  else ...[
                    Table(
                      border: TableBorder.all(color: Colors.black),
                      defaultVerticalAlignment:
                          TableCellVerticalAlignment.middle,
                      children: [
                        TableRow(
                          decoration: const BoxDecoration(
                            color: Color(0xFFE0E0E0),
                          ),
                          children: [
                            for (int i = 0; i <= 7; i++)
                              Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(
                                    "$i",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text(
                                "Total",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        TableRow(
                          children: [
                            for (int i = 0; i <= 7; i++)
                              Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text("${frecuenciaNotas[i] ?? 0}"),
                                ),
                              ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                "${frecuenciaNotas.values.reduce((a, b) => a + b)}",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: SizedBox(
                        width:
                            MediaQuery.of(context).size.width *
                            0.5, // mitad del ancho
                        height: 250,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 10,
                    children: [
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade600,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: exportarExcel,
                        icon: const Icon(Icons.table_chart),
                        label: const Text("Exportar Excel"),
                      ),
                    ],
                  ),
                ],
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
