class Ciudad {
  final String ciudadId;
  final String nombre;
  final String fechaCreacion;

  Ciudad({
    required this.ciudadId,
    required this.nombre,
    required this.fechaCreacion,
  });

  factory Ciudad.fromMap(Map<String, dynamic> map) {
    return Ciudad(
      ciudadId: map['ciudadId'] ?? '',
      nombre: map['nombre'] ?? '',
      fechaCreacion: map['fecha_creacion'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'ciudadId': ciudadId,
      'nombre': nombre,
      'fecha_creacion': fechaCreacion,
    };
  }
}
