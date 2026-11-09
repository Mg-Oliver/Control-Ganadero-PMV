import '../../data/models/lote_model.dart';

/// Funciones puras y utilidades para garantizar consistencia zootécnica
/// en asignaciones de predio, lotes y estados de baja/salida.
class PredioConsistencyHelper {
  /// Lista de estados zootécnicos que representan una baja o salida física del predio.
  static const Set<String> estadosDeBaja = {
    'Vendido',
    'Muerto',
    'Robado',
    'Descartado',
  };

  /// Determina si un estado zootécnico corresponde a una baja del predio.
  static bool esEstadoDeBaja(String estado) =>
      estadosDeBaja.contains(estado.trim());

  /// Valida y resuelve el lote asignado tras un cambio de finca.
  /// Si el lote actual no pertenece a [nuevaFincaId], se desasocia inmediatamente retornando `null`.
  static String? resolverLoteTrasCambioFinca({
    required String? nuevaFincaId,
    required String? loteActualId,
    required List<LoteModel> lotesDisponibles,
  }) {
    if (nuevaFincaId == null || loteActualId == null) return null;

    final pertenece = lotesDisponibles.any(
      (lote) => lote.id == loteActualId && lote.fincaId == nuevaFincaId,
    );

    return pertenece ? loteActualId : null;
  }

  /// Filtra los lotes disponibles garantizando que pertenezcan estrictamente a la finca seleccionada.
  static List<LoteModel> filtrarLotesPorFinca({
    required String? fincaId,
    required List<LoteModel> todosLosLotes,
  }) {
    if (fincaId == null || fincaId.isEmpty) return const [];
    return todosLosLotes.where((l) => l.fincaId == fincaId).toList();
  }

  /// Valida los campos requeridos cuando un animal entra en estado de baja.
  /// Retorna un mapa con los valores ajustados para guardar consistentemente:
  /// - `loteId`: forzado a `null`
  /// - `potreroActual`: forzado a `null`
  /// - `fechaSalida`: garantizada (si es null, usa `DateTime.now()`)
  static ({
    String? loteId,
    String? potreroActual,
    DateTime? fechaSalida,
    bool esBaja,
  }) procesarUbicacionPorEstado({
    required String estadoActual,
    required String? loteIdOriginal,
    required String? potreroOriginal,
    required DateTime? fechaSalidaOriginal,
  }) {
    final esBaja = esEstadoDeBaja(estadoActual);
    if (!esBaja) {
      return (
        loteId: loteIdOriginal,
        potreroActual: potreroOriginal,
        fechaSalida: fechaSalidaOriginal,
        esBaja: false,
      );
    }

    return (
      loteId: null,
      potreroActual: null,
      fechaSalida: fechaSalidaOriginal ?? DateTime.now(),
      esBaja: true,
    );
  }
}

