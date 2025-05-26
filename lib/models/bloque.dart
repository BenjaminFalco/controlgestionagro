class Bloque {
  final String bloqueId;
  final String serieId;
  final String nombre;

  Bloque({required this.bloqueId, required this.serieId, required this.nombre});

  factory Bloque.fromMap(Map<String, dynamic> map) {
    return Bloque(
      bloqueId: map['bloqueId'] ?? '',
      serieId: map['serieId'] ?? '',
      nombre: map['nombre'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {'bloqueId': bloqueId, 'serieId': serieId, 'nombre': nombre};
  }
}
