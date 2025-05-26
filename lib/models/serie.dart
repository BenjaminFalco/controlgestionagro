class Serie {
  final String serieId;
  final String ciudadId;
  final String nombre;
  final String fechaCosecha;
  final String fechaCreacion;
  final int matrizAlto;
  final int matrizLargo;
  final double superficie;

  Serie({
    required this.serieId,
    required this.ciudadId,
    required this.nombre,
    required this.fechaCosecha,
    required this.fechaCreacion,
    required this.matrizAlto,
    required this.matrizLargo,
    required this.superficie,
  });

  factory Serie.fromMap(Map<String, dynamic> map) {
    return Serie(
      serieId: map['serieId'] ?? '',
      ciudadId: map['ciudadId'] ?? '',
      nombre: map['nombre'] ?? '',
      fechaCosecha: map['fecha_cosecha'] ?? '',
      fechaCreacion: map['fecha_creacion'] ?? '',
      matrizAlto: map['matriz_alto'] ?? 0,
      matrizLargo: map['matriz_largo'] ?? 0,
      superficie: (map['superficie'] ?? 10).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'serieId': serieId,
      'ciudadId': ciudadId,
      'nombre': nombre,
      'fecha_cosecha': fechaCosecha,
      'fecha_creacion': fechaCreacion,
      'matriz_alto': matrizAlto,
      'matriz_largo': matrizLargo,
      'superficie': superficie,
    };
  }
}
