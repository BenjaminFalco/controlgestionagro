import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'admin/admin_dashboard.dart';
import 'worker/worker_dashboard.dart';
import 'login_screen.dart';

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
          await FirebaseFirestore.instance.collection('usuarios').doc(uid).get();

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
      String uid = FirebaseAuth.instance.currentUser!.uid;

      await FirebaseFirestore.instance.collection('usuarios').doc(uid).set({
        "nombre": nameController.text.trim(),
        "telefono": phoneController.text.trim(),
        "rol": selectedRole,
      }, SetOptions(merge: true));

      print("✅ Datos guardados en Firestore correctamente.");

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
      backgroundColor: Colors.black,
      body: Center(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 350),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Completa tu información antes de continuar",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 24),

                  // Campo: Nombre
                  TextField(
                    controller: nameController,
                    style: const TextStyle(fontSize: 20, color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: "Nombre",
                      labelStyle: TextStyle(color: Colors.white, fontSize: 18),
                      filled: true,
                      fillColor: Colors.black,
                      contentPadding: EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                      border: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white),
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white),
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white, width: 2),
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Campo: Teléfono
                  TextField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    style: const TextStyle(fontSize: 20, color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: "Teléfono",
                      labelStyle: TextStyle(color: Colors.white, fontSize: 18),
                      filled: true,
                      fillColor: Colors.black,
                      contentPadding: EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                      border: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white),
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white),
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white, width: 2),
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Dropdown: Rol
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white),
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.black,
                    ),
                    child: DropdownButton<String>(
                      value: selectedRole,
                      dropdownColor: Colors.black,
                      isExpanded: true,
                      style: const TextStyle(color: Colors.white, fontSize: 18),
                      underline: const SizedBox(),
                      iconEnabledColor: Colors.white,
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedRole = newValue!;
                        });
                      },
                      items: <String>['trabajador', 'admin']
                          .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 20),

                  if (errorMessage.isNotEmpty)
                    Text(errorMessage, style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 20),

                  ElevatedButton(
                    onPressed: saveUserInfo,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 35, vertical: 20),
                      backgroundColor: Colors.deepPurpleAccent,
                      foregroundColor: Colors.white,
                      textStyle: const TextStyle(fontSize: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text("Guardar"),
                  ),
                  const SizedBox(height: 25),

                  // Botón: Volver al login
                  TextButton(
                    onPressed: () {
                      FirebaseAuth.instance.signOut();
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const LoginScreen()),
                      );
                    },
                    child: const Text(
                      "Volver al login",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
