import 'package:flutter_test/flutter_test.dart';
import 'package:bovino_mvp/core/utils/edad_animal.dart';

void main() {
  test('partos: umbral estrictamente mayor de 18 meses', () {
    final fecha = DateTime(2025, 5, 12);
    expect(
      EdadAnimal.esMayorDeMeses(fecha, 18, DateTime(2026, 11, 11)),
      isFalse,
    );
    expect(
      EdadAnimal.esMayorDeMeses(fecha, 18, DateTime(2026, 11, 12)),
      isFalse,
    );
    expect(
      EdadAnimal.esMayorDeMeses(fecha, 18, DateTime(2026, 11, 13)),
      isTrue,
    );
  });
  test('umbral de 18 meses ajusta los días al final del mes', () {
    final fecha = DateTime(2024, 8, 31);
    expect(
      EdadAnimal.esMayorDeMeses(fecha, 18, DateTime(2026, 2, 28)),
      isFalse,
    );
    expect(EdadAnimal.esMayorDeMeses(fecha, 18, DateTime(2026, 3, 1)), isTrue);
  });

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
