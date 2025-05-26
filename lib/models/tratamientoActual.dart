class TratamientoActual {
  final String parcelaId;
  final String fecha;
  final String ndvi;
  final String observaciones;
  final double pesoA;
  final double pesoB;
  final double pesoHojas;
  final double raicesA;
  final double raicesB;
  final String trabajador;

  TratamientoActual({
    required this.parcelaId,
    required this.fecha,
    required this.ndvi,
    required this.observaciones,
    required this.pesoA,
    required this.pesoB,
    required this.pesoHojas,
    required this.raicesA,
    required this.raicesB,
    required this.trabajador,
  });

  factory TratamientoActual.fromMap(Map<String, dynamic> map) {
    return TratamientoActual(
      parcelaId: map['parcelaId'] ?? '',
      fecha: map['fecha'] ?? '',
      ndvi: map['ndvi'] ?? '',
      observaciones: map['observaciones'] ?? '',
      pesoA: (map['pesoA'] ?? 0).toDouble(),
      pesoB: (map['pesoB'] ?? 0).toDouble(),
      pesoHojas: (map['pesoHojas'] ?? 0).toDouble(),
      raicesA: (map['raicesA'] ?? 0).toDouble(),
      raicesB: (map['raicesB'] ?? 0).toDouble(),
      trabajador: map['trabajador'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'parcelaId': parcelaId,
      'fecha': fecha,
      'ndvi': ndvi,
      'observaciones': observaciones,
      'pesoA': pesoA,
      'pesoB': pesoB,
      'pesoHojas': pesoHojas,
      'raicesA': raicesA,
      'raicesB': raicesB,
      'trabajador': trabajador,
    };
  }
}
