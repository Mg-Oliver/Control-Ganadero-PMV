import 'package:flutter_test/flutter_test.dart';
import 'package:bovino_mvp/core/utils/receptora_embriones.dart';

void main() {
  test('receptora se conserva separada de las observaciones originales', () {
    final texto = ReceptoraEmbriones.guardar('Animal sano', 'RC-01 · Luna');
    expect(ReceptoraEmbriones.extraer(texto), 'RC-01 · Luna');
    expect(ReceptoraEmbriones.sinReceptora(texto), 'Animal sano');
  });
  test('actualizar o quitar receptora no duplica ni borra notas', () {
    final texto = ReceptoraEmbriones.guardar('Nota de compra', 'RC-01');
    final actualizado = ReceptoraEmbriones.guardar(texto, 'RC-02');
    expect(actualizado.split('Vaca receptora (TE):').length, 2);
    expect(ReceptoraEmbriones.extraer(actualizado), 'RC-02');
    expect(ReceptoraEmbriones.guardar(actualizado, null), 'Nota de compra');
    expect(ReceptoraEmbriones.sinReceptora('Nota de compra'), 'Nota de compra');
  });
}
