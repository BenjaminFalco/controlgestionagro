import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'admin/admin_dashboard.dart';
import 'worker/worker_dashboard.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  _SetupScreenState createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  String selectedRole = 'trabajador'; // Valor por defecto
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      String uid = FirebaseAuth.instance.currentUser!.uid;
      DocumentSnapshot userDoc =
          await FirebaseFirestore.instance
              .collection('usuarios')
              .doc(uid)
              .get();

      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

        setState(() {
          nameController.text = userData['nombre'] ?? '';
          phoneController.text = userData['telefono'] ?? '';
          selectedRole = userData['rol'] ?? 'trabajador';
        });
      }
    } catch (e) {
      print("❌ Error al cargar datos del usuario: $e");
    }
  }

  Future<void> saveUserInfo() async {
    try {
      // 🔹 Obtener UID del usuario actual
      String uid = FirebaseAuth.instance.currentUser!.uid;

      // 🔹 Guardar los datos en Firestore
      await FirebaseFirestore.instance.collection('usuarios').doc(uid).set({
        "nombre": nameController.text.trim(),
        "telefono": phoneController.text.trim(),
        "rol": selectedRole,
      }, SetOptions(merge: true));

      print("✅ Datos guardados en Firestore correctamente.");

      // 🔥 Redirigir al usuario según el rol seleccionado
      if (selectedRole == "admin") {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const AdminDashboard()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const WorkerDashboard()),
        );
      }
    } catch (e) {
      print("❌ Error al guardar datos: $e");
      setState(() {
        errorMessage = 'Error al guardar datos: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Configuración Inicial")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Completa tu información antes de continuar",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: "Nombre"),
            ),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(labelText: "Teléfono"),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 10),
            DropdownButton<String>(
              value: selectedRole,
              onChanged: (String? newValue) {
                setState(() {
                  selectedRole = newValue!;
                });
              },
              items:
                  <String>['trabajador', 'admin'].map<DropdownMenuItem<String>>(
                    (String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    },
                  ).toList(),
            ),
            const SizedBox(height: 10),
            if (errorMessage.isNotEmpty)
              Text(errorMessage, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: saveUserInfo,
              child: const Text("Guardar"),
            ),
          ],
        ),
      ),
    );
  }
}
