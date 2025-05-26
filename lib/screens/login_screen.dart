import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:controlgestionagro/screens/worker/inicio_tratamiento.dart';
import 'package:controlgestionagro/services/global_services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import 'register_screen.dart';
import 'setup_screen.dart';
import 'admin/admin_dashboard.dart';
import 'worker/worker_dashboard.dart';

import 'package:connectivity_plus/connectivity_plus.dart';

import 'package:controlgestionagro/models/users_local.dart';

import '../models/users_local.dart';

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
    _verificarUsuarioOperadorPersistido(); // 👈 Agregamos esta verificación
  }

  void _verificarUsuarioOperadorPersistido() async {
    final usuario = await getUsuarioLocal();

    if (usuario != null && usuario.rol == 'operador') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const InicioTratamientoScreen()),
      );
    }
  }

  Future<UsuarioLocal?> getUsuarioLocal() async {
    final db = GlobalServices.syncService.db;

    try {
      final result = await db.query('usuarios_locales', limit: 1);
      if (result.isNotEmpty) {
        return UsuarioLocal.fromMap(result.first);
      }
    } catch (e) {
      print('❌ Error obteniendo usuario local: $e');
    }

    return null;
  }

  Future<UsuarioLocal?> obtenerUsuarioActual() async {
    final connectivity = await Connectivity().checkConnectivity();
    final db = GlobalServices.syncService.db;

    try {
      final result = await db.query('usuarios_locales', limit: 1);
      if (result.isEmpty) return null;
      return UsuarioLocal.fromMap(result.first);
    } catch (e) {
      print('❌ Error obteniendo usuario actual: $e');
      return null;
    }
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
        // ✅ Aquí se define `usuarioLocal` antes de usarlo
        final usuarioLocal = UsuarioLocal(
          uid: uid,
          email: emailController.text.trim(),
          rol: userData['rol'] ?? '',
          nombre: userData['nombre'] ?? '',
          ciudad: userData['ciudad'] ?? '',
          password: passwordController.text.trim(),
        );

        // ✅ Guardamos en SQLite
        await GlobalServices.syncService.db.insert(
          'usuarios_locales',
          usuarioLocal.toMap()
            ..['timestamp'] = DateTime.now().toIso8601String(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );

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

      final db = GlobalServices.syncService.db;

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

        final usuarioLocal = UsuarioLocal(
          uid: uid,
          email: email,
          rol: data['rol'] ?? '',
          nombre: data['nombre'] ?? '',
          ciudad: data['ciudad'] ?? '',
          password: '',
        );

        await db.insert(
          'usuarios_locales',
          usuarioLocal.toMap()
            ..['timestamp'] = DateTime.now().toIso8601String(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );

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
            MaterialPageRoute(builder: (_) => const InicioTratamientoScreen()),
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF005A56),
        centerTitle: true,
        elevation: 0,
        title: Image.asset('assets/images/iansa_logo.jpeg', height: 40),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
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
                        color: Color(0xFF004D4C),
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 10,
                      children:
                          usuariosRecientes.map((email) {
                            return ActionChip(
                              label: Text(email),
                              onPressed:
                                  () => setState(
                                    () => emailController.text = email,
                                  ),
                            );
                          }).toList(),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              _buildTextField(
                controller: emailController,
                label: "Usuario/Email",
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: passwordController,
                label: "Contraseña",
                obscure: true,
              ),
              const SizedBox(height: 5),
              SizedBox(
                width: 300,
                child: Center(
                  child: TextButton(
                    onPressed: recuperarContrasena,
                    child: const Text(
                      '¿Olvidaste tu contraseña?',
                      style: TextStyle(
                        color: Colors.black54,
                        fontSize: 14,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              if (errorMessage.isNotEmpty)
                Text(errorMessage, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: loginUser,
                icon: const Icon(Icons.login, size: 20),
                label: const Text(
                  "Inicio Admin",
                  style: TextStyle(fontSize: 22),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00B140),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              ElevatedButton.icon(
                onPressed: () async {
                  final db = GlobalServices.syncService.db;

                  try {
                    final conectado = await Connectivity().checkConnectivity();
                    final hayConexion = conectado != ConnectivityResult.none;

                    // 🔹 ¿Existe usuario operador local?
                    final result = await db.query(
                      'usuarios_locales',
                      where: 'rol = ?',
                      whereArgs: ['operador'],
                      limit: 1,
                    );

                    if (result.isNotEmpty) {
                      print("✅ Operador local encontrado");
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const InicioTratamientoScreen(),
                        ),
                      );
                      return;
                    }

                    if (!hayConexion) {
                      print("⚠️ Sin conexión, pero crearé operador localmente");

                      final usuarioLocal = UsuarioLocal(
                        uid: 'operador_local',
                        email: 'local@operador.com',
                        rol: 'operador',
                        nombre: 'Usuario Operador',
                        ciudad: '',
                        password: '',
                      );

                      await db.insert(
                        'usuarios_locales',
                        usuarioLocal.toMap()
                          ..['timestamp'] = DateTime.now().toIso8601String(),
                        conflictAlgorithm: ConflictAlgorithm.replace,
                      );

                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const InicioTratamientoScreen(),
                        ),
                      );
                      return;
                    }

                    // 🔹 Crear operador local si no existe (usando solo SQLite)
                    final usuarioLocal = UsuarioLocal(
                      uid: 'operador_local',
                      email: 'local@operador.com',
                      rol: 'operador',
                      nombre: 'Usuario Operador',
                      ciudad: '',
                      password: '',
                    );

                    // ✅ INSERTAR EN SQLITE
                    await db.insert(
                      'usuarios_locales',
                      usuarioLocal.toMap()
                        ..['timestamp'] = DateTime.now().toIso8601String(),
                      conflictAlgorithm: ConflictAlgorithm.replace,
                    );

                    // ✅ PASO 2: GUARDAR EN FIRESTORE TAMBIÉN
                    await FirebaseFirestore.instance
                        .collection('usuarios')
                        .doc('operador_local')
                        .set({
                          'email': 'local@operador.com',
                          'rol': 'operador',
                          'nombre': 'Usuario Operador',
                          'ciudad': '',
                          'timestamp': DateTime.now().toIso8601String(),
                        });

                    print("✅ Usuario operador creado en SQLite y Firestore");
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const InicioTratamientoScreen(),
                      ),
                    );
                  } catch (e) {
                    print('❌ Error al crear usuario operador: $e');
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Error al iniciar sesión')),
                    );
                  }
                },
                icon: const Icon(Icons.play_arrow),
                label: const Text("Operador", style: TextStyle(fontSize: 40)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF005A56),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 80,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),

              const SizedBox(height: 16),

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
                  style: TextStyle(fontSize: 18, color: Colors.black),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    bool obscure = false,
  }) {
    return SizedBox(
      width: 400,
      child: TextField(
        controller: controller,
        obscureText: obscure,
        style: const TextStyle(fontSize: 18, color: Colors.black),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.black87, fontSize: 18),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 20,
            horizontal: 16,
          ),
          border: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.black),
            borderRadius: BorderRadius.circular(8),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.black),
            borderRadius: BorderRadius.circular(8),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Color(0xFF005A56), width: 2),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}
