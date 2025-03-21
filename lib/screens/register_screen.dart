import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  String errorMessage = '';

  Future<void> registerUser() async {
    try {
      // 🔹 Crear usuario en Firebase Authentication
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: emailController.text.trim(),
            password: passwordController.text.trim(),
          );

      // 🔹 Obtener UID del usuario
      String uid = userCredential.user!.uid;

      // 🔹 Guardar usuario en Firestore
      await FirebaseFirestore.instance.collection('usuarios').doc(uid).set({
        "email": emailController.text.trim(),
        "fecha_creacion":
            FieldValue.serverTimestamp(), // Guarda la fecha de creación
      });

      print("✅ Usuario registrado y guardado en Firestore correctamente.");

      // 🔹 Regresar a la pantalla de Login
      Navigator.pop(context);
    } catch (e) {
      print("❌ Error en registro: $e");
      setState(() {
        errorMessage = 'Error en registro: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Registro de usuario")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: "Email"),
            ),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(labelText: "Contraseña"),
              obscureText: true,
            ),
            const SizedBox(height: 10),
            if (errorMessage.isNotEmpty)
              Text(errorMessage, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: registerUser,
              child: const Text("Registrarse"),
            ),
          ],
        ),
      ),
    );
  }
}
