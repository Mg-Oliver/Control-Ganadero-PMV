import 'package:flutter_test/flutter_test.dart';
import 'package:bovino_mvp/core/utils/edad_animal.dart';

void main() {
  test('calcula años meses y días exactos', () {
    final edad = EdadAnimal.desdeFecha(
      DateTime(2024, 2, 2),
      DateTime(2026, 11, 12),
    );
    expect([edad.anios, edad.meses, edad.dias], [2, 9, 10]);
  });
  test('resta años y meses ajustando fin de mes bisiesto', () {
    expect(
      const EdadAnimal(0, 1, 0).fechaNacimiento(DateTime(2024, 3, 31)),
      DateTime(2024, 2, 29),
    );
    expect(
      const EdadAnimal(1, 0, 0).fechaNacimiento(DateTime(2024, 2, 29)),
      DateTime(2023, 2, 28),
    );
  });
  test('edad desde cumpleaños bisiesto se calcula sin fechas imposibles', () {
    final edad = EdadAnimal.desdeFecha(
      DateTime(2024, 2, 29),
      DateTime(2025, 2, 28),
    );
    expect([edad.anios, edad.meses, edad.dias], [1, 0, 0]);
  });
  test('rechaza nacimiento futuro y componentes fuera de rango', () {
    expect(
      () => EdadAnimal.desdeFecha(DateTime(2027), DateTime(2026)),
      throwsArgumentError,
    );
    expect(
      () => const EdadAnimal(1, 12, 0).fechaNacimiento(DateTime(2026)),
      throwsArgumentError,
    );
  });
}
