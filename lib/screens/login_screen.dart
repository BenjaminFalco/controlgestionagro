import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'register_screen.dart';
import 'setup_screen.dart';
import 'admin/admin_dashboard.dart';
import 'worker/worker_dashboard.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  String errorMessage = '';
  List<String> usuariosRecientes = [];

  @override
  void initState() {
    super.initState();
    _cargarUsuariosRecientes();
  }

  Future<void> _cargarUsuariosRecientes() async {
    final prefs = await SharedPreferences.getInstance();
    final lista = prefs.getStringList('usuariosRecientes') ?? [];
    setState(() => usuariosRecientes = lista);
  }

  Future<void> _guardarUsuarioReciente(String email) async {
    final prefs = await SharedPreferences.getInstance();
    final lista = prefs.getStringList('usuariosRecientes') ?? [];
    if (!lista.contains(email)) {
      lista.insert(0, email);
      if (lista.length > 5) lista.removeLast();
      await prefs.setStringList('usuariosRecientes', lista);
    }
  }

  Future<void> loginUser() async {
    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
            email: emailController.text.trim(),
            password: passwordController.text.trim(),
          );

      await _guardarUsuarioReciente(emailController.text.trim());

      final uid = userCredential.user!.uid;
      final userDoc =
          await FirebaseFirestore.instance
              .collection('usuarios')
              .doc(uid)
              .get();
      final userData = userDoc.data() as Map<String, dynamic>?;

      if (userData == null ||
          userData['nombre'] == null ||
          userData['rol'] == null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const SetupScreen()),
        );
      } else {
        final rol = userData['rol'];
        if (rol == "admin") {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const AdminDashboard()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const WorkerDashboard()),
          );
        }
      }
    } catch (e) {
      setState(() => errorMessage = "⚠️ Usuario o contraseña incorrectos.");
    }
  }

  Future<void> loginWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return;

      final googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await FirebaseAuth.instance.signInWithCredential(
        credential,
      );
      final email = userCredential.user?.email ?? '';
      await _guardarUsuarioReciente(email);

      final uid = userCredential.user!.uid;
      final userDoc =
          await FirebaseFirestore.instance
              .collection('usuarios')
              .doc(uid)
              .get();

      if (!userDoc.exists) {
        await FirebaseFirestore.instance.collection('usuarios').doc(uid).set({
          'email': email,
          'nombre': '',
          'rol': '',
          'ciudad': '',
          'ensayos_asignados': [],
        });
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const SetupScreen()),
        );
      } else {
        final data = userDoc.data() as Map<String, dynamic>;
        if (data['rol'] == null || data['nombre'] == null) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const SetupScreen()),
          );
        } else if (data['rol'] == 'admin') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const AdminDashboard()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const WorkerDashboard()),
          );
        }
      }
    } catch (e) {
      setState(() => errorMessage = 'Error al iniciar sesión con Google');
    }
  }

  Future<void> recuperarContrasena() async {
    final email = emailController.text.trim();
    if (email.isEmpty) {
      setState(
        () => errorMessage = "Ingresa tu correo para recuperar la contraseña.",
      );
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      setState(() => errorMessage = "✅ Se envió un enlace a tu correo.");
    } catch (e) {
      setState(() => errorMessage = "❌ No se pudo enviar el correo.");
    }
  }

 @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(title: const Text("Iniciar sesión")),
    backgroundColor: Colors.black,
    body: Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (usuariosRecientes.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Usuarios recientes:",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 10,
                    children: usuariosRecientes.map((email) {
                      return ActionChip(
                        label: Text(email),
                        onPressed: () =>
                            setState(() => emailController.text = email),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            SizedBox(
              width: 300,
              child: TextField(
                controller: emailController,
                style: const TextStyle(fontSize: 20, color: Colors.white),
                decoration: const InputDecoration(
                  labelText: "Usuario/Email",
                  labelStyle: TextStyle(color: Colors.white, fontSize: 18),
                  filled: true,
                  fillColor: Colors.black,
                  contentPadding:
                      EdgeInsets.symmetric(vertical: 20, horizontal: 16),
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
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: 300,
              child: TextField(
                controller: passwordController,
                obscureText: true,
                style: const TextStyle(fontSize: 20, color: Colors.white),
                decoration: const InputDecoration(
                  labelText: "Contraseña",
                  labelStyle: TextStyle(color: Colors.white, fontSize: 18),
                  filled: true,
                  fillColor: Colors.black,
                  contentPadding:
                      EdgeInsets.symmetric(vertical: 20, horizontal: 16),
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
            ),
           const SizedBox(height: 5),

            SizedBox(
              width: 300,
              child: Center(
                child: TextButton(
                  onPressed: () {
                    // lógica para recuperar contraseña
                  },
                  child: const Text(
                    '¿Olvidaste tu contraseña?',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 8),
            if (errorMessage.isNotEmpty)
              Text(errorMessage,
                  style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: loginUser,
              icon: const Icon(Icons.login, size: 28),
              label: const Text(
                "Iniciar sesión",
                style: TextStyle(fontSize: 22),
              ),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: loginWithGoogle,
              icon: const Icon(Icons.g_mobiledata, size: 28),
              label: const Text(
                "Iniciar con Google",
                style: TextStyle(fontSize: 22),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RegisterScreen()),
                );
              },
              child: const Text(
                "¿No tienes cuenta? Regístrate aquí",
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
}
