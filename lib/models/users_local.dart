class UsuarioLocal {
  final String uid;
  final String email;
  final String rol;
  final String nombre;
  final String ciudad;
  final String password;

  UsuarioLocal({
    required this.uid,
    required this.email,
    required this.rol,
    required this.nombre,
    required this.ciudad,
    required this.password,
  });

  factory UsuarioLocal.fromMap(Map<String, dynamic> map) {
    return UsuarioLocal(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      rol: map['rol'] ?? '',
      nombre: map['nombre'] ?? '',
      ciudad: map['ciudad'] ?? '',
      password: map['password'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'rol': rol,
      'nombre': nombre,
      'ciudad': ciudad,
      'password': password,
    };
  }
}
