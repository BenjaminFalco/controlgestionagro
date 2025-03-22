import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class EditarParcela extends StatefulWidget {
  final String ciudadId;
  final String serieId;
  final String bloqueId;
  final String parcelaId;

  const EditarParcela({
    super.key,
    required this.ciudadId,
    required this.serieId,
    required this.bloqueId,
    required this.parcelaId,
  });

  @override
  State<EditarParcela> createState() => _EditarParcelaState();
}

class _EditarParcelaState extends State<EditarParcela> {
  final TextEditingController fichaController = TextEditingController();
  final TextEditingController asignadoController = TextEditingController();
  bool cargando = true;

  @override
  void initState() {
    super.initState();
    cargarDatosParcela();
  }

  Future<void> cargarDatosParcela() async {
    final doc =
        await FirebaseFirestore.instance
            .collection('ciudades')
            .doc(widget.ciudadId)
            .collection('series')
            .doc(widget.serieId)
            .collection('bloques')
            .doc(widget.bloqueId)
            .collection('parcelas')
            .doc(widget.parcelaId)
            .get();

    if (doc.exists) {
      final data = doc.data() ?? {};

      fichaController.text = (data['numero_ficha'] ?? '').toString();
      asignadoController.text = (data['numero_asignado'] ?? '').toString();
    }

    setState(() => cargando = false);
  }

  Future<void> guardarCambios() async {
    await FirebaseFirestore.instance
        .collection('ciudades')
        .doc(widget.ciudadId)
        .collection('series')
        .doc(widget.serieId)
        .collection('bloques')
        .doc(widget.bloqueId)
        .collection('parcelas')
        .doc(widget.parcelaId)
        .update({
          "numero_ficha": int.tryParse(fichaController.text.trim()),
          "numero_asignado": int.tryParse(asignadoController.text.trim()),
        });

    Navigator.pop(context); // Volver atrás
  }

  Future<void> reiniciarParcela() async {
    await FirebaseFirestore.instance
        .collection('ciudades')
        .doc(widget.ciudadId)
        .collection('series')
        .doc(widget.serieId)
        .collection('bloques')
        .doc(widget.bloqueId)
        .collection('parcelas')
        .doc(widget.parcelaId)
        .update({"numero_ficha": null, "numero_asignado": null});

    fichaController.clear();
    asignadoController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Editar Parcela")),
      body:
          cargando
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    TextField(
                      controller: fichaController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: "Número de ficha (único)",
                      ),
                    ),
                    TextField(
                      controller: asignadoController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: "Número asignado (manual)",
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: guardarCambios,
                      icon: const Icon(Icons.save),
                      label: const Text("Guardar cambios"),
                    ),
                    const SizedBox(height: 10),
                    TextButton.icon(
                      onPressed: reiniciarParcela,
                      icon: const Icon(Icons.refresh),
                      label: const Text("Reiniciar datos de esta parcela"),
                    ),
                  ],
                ),
              ),
    );
  }
}
