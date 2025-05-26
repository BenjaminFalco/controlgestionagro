class Parcela {
  final String parcelaId;
  final String bloqueId;
  final List<int> evaluacion;
  final double frecuenciaRelativa;
  final int numero;
  final String numeroFicha;
  final int numeroTratamiento;
  final int totalRaices;
  final String trabajadorId;
  final bool tratamiento;

  Parcela({
    required this.parcelaId,
    required this.bloqueId,
    required this.evaluacion,
    required this.frecuenciaRelativa,
    required this.numero,
    required this.numeroFicha,
    required this.numeroTratamiento,
    required this.totalRaices,
    required this.trabajadorId,
    required this.tratamiento,
  });

  factory Parcela.fromMap(Map<String, dynamic> map) {
    return Parcela(
      parcelaId: map['parcelaId'] ?? '',
      bloqueId: map['bloqueId'] ?? '',
      evaluacion: (map['evaluacion'] as List?)?.cast<int>() ?? [],
      frecuenciaRelativa: (map['frecuencia_relativa'] ?? 0).toDouble(),
      numero: map['numero'] ?? 0,
      numeroFicha: map['numero_ficha'] ?? '',
      numeroTratamiento: map['numero_tratamiento'] ?? 0,
      totalRaices: map['total_raices'] ?? 0,
      trabajadorId: map['trabajador_id'] ?? '',
      tratamiento: map['tratamiento'] == 1 || map['tratamiento'] == true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'parcelaId': parcelaId,
      'bloqueId': bloqueId,
      'evaluacion': evaluacion,
      'frecuencia_relativa': frecuenciaRelativa,
      'numero': numero,
      'numero_ficha': numeroFicha,
      'numero_tratamiento': numeroTratamiento,
      'total_raices': totalRaices,
      'trabajador_id': trabajadorId,
      'tratamiento': tratamiento ? 1 : 0,
    };
  }
}
