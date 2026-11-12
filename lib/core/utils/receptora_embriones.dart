/// Conserva el dato obstétrico en las observaciones del animal, separado del linaje.
class ReceptoraEmbriones {
  static const _prefijo = 'Vaca receptora (TE): ';
  static String? extraer(String? observaciones) {
    final ultima = (observaciones ?? '').trimRight().split('\n').last;
    if (!ultima.startsWith(_prefijo)) return null;
    final dato = ultima.substring(_prefijo.length).trim();
    return dato.isEmpty ? null : dato;
  }

  static String sinReceptora(String? observaciones) {
    final texto = (observaciones ?? '').trimRight();
    final lineas = texto.split('\n');
    if (lineas.last.startsWith(_prefijo)) lineas.removeLast();
    return lineas.join('\n').trimRight();
  }

  static String guardar(String? observaciones, String? receptora) {
    final texto = sinReceptora(observaciones);
    final dato = (receptora ?? '').trim().replaceAll(RegExp(r'[\r\n]+'), ' ');
    if (dato.isEmpty) return texto;
    return texto.isEmpty ? '$_prefijo$dato' : '$texto\n$_prefijo$dato';
  }
}
