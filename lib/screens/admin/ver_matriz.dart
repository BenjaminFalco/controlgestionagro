import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class VerMatriz extends StatefulWidget {
  final String ciudadId;
  final String serieId;

  const VerMatriz({super.key, required this.ciudadId, required this.serieId});

  @override
  State<VerMatriz> createState() => _VerMatrizState();
}

class _VerMatrizState extends State<VerMatriz> {
  Map<String, List<int>> bloques = {'A': [], 'B': [], 'C': [], 'D': []};

  bool cargando = true;

  @override
  void initState() {
    super.initState();
    cargarParcelas();
  }

  Future<void> cargarParcelas() async {
    final serieRef = FirebaseFirestore.instance
        .collection('ciudades')
        .doc(widget.ciudadId)
        .collection('series')
        .doc(widget.serieId);

    for (var bloque in ['A', 'B', 'C', 'D']) {
      final snapshot =
          await serieRef
              .collection('bloques')
              .doc(bloque)
              .collection('parcelas')
              .orderBy('numero')
              .get();

      setState(() {
        bloques[bloque] = snapshot.docs.map((d) => d['numero'] as int).toList();
      });
    }

    setState(() {
      cargando = false;
    });
  }

  Widget buildBloque(String bloqueId, List<int> parcelas) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Bloque $bloqueId",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: 40,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: parcelas.length,
            itemBuilder: (context, index) {
              return Container(
                width: 40,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.deepPurple[100],
                  border: Border.all(color: Colors.deepPurple),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(parcelas[index].toString()),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Visualización de Matriz")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child:
            cargando
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                  children:
                      bloques.entries.map((entry) {
                        return buildBloque(entry.key, entry.value);
                      }).toList(),
                ),
      ),
    );
  }
}
