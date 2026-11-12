import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bovino_mvp/core/utils/formatters.dart';
import 'package:bovino_mvp/core/utils/validators.dart';
import 'package:bovino_mvp/data/models/animal_model.dart';
import 'package:bovino_mvp/data/models/finca_model.dart';
import 'package:bovino_mvp/data/services/animales_service.dart';
import 'package:bovino_mvp/ui/common/custom_text_field.dart';
import 'package:bovino_mvp/ui/screens/creacion/forms/animal_form.dart';
import '../helpers/test_theme.dart';

class _Service extends AnimalesService {
  AnimalModel? guardado;
  @override
  Future<AnimalModel> actualizar(AnimalModel animal) async {
    guardado = animal;
    return animal;
  }
}

Finder caja(String label) =>
    find.byWidgetPredicate((w) => w is CustomTextField && w.label == label);
Finder campo(String label) =>
    find.descendant(of: caja(label), matching: find.byType(TextFormField));
void main() {
  test('formato USD conserva centavos y diferencia la divisa', () {
    expect(Formatters.formatearMoneda(null), r'US$ 0.00');
    expect(Formatters.formatearMoneda(1500.75), r'US$ 1,500.75');
    expect(Formatters.formatearMoneda(0.05), r'US$ 0.05');
    expect(Formatters.formatearMonedaCompacta(5500000), r'US$ 5.50 M');
  });
  test('importes aceptan punto o coma decimal y rechazan precisión extra', () {
    for (final v in ['1500.75', '1500,75', '0', '800.0', '']) {
      expect(Validators.monedaUSD(v), isNull);
    }
    for (final v in ['1500.755', '-1', 'NaN', '1e6', '99999999999']) {
      expect(Validators.monedaUSD(v), isNotNull);
    }
  });
  for (final venta in [false, true]) {
    testWidgets(
      '${venta ? "Venta" : "Compra"} se ingresa en USD y conserva sus centavos al guardar',
      (tester) async {
        tester.view.physicalSize = const Size(1440, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final service = _Service();
        final animal = AnimalModel(
          id: 'a1',
          codigoSistema: 'GAN1',
          areteManejo: 'TR-01',
          sexo: 'Macho',
          razaPuraNombre: 'Holstein',
          razaEtiquetaDisplay: 'Holstein',
          tipoExplotacion: 'Lecheria',
          fechaNacimiento: DateTime(2020),
          origen: 'Comprado en subasta',
          fincaId: 'f1',
          fechaEntrada: DateTime(2024),
          precioCompra: 800,
          estadoActual: venta ? 'Vendido' : 'Activo',
        );
        await tester.pumpWidget(
          MaterialApp(
            theme: testTheme,
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => Scaffold(
                        body: SingleChildScrollView(
                          child: AnimalForm(
                            fincas: const [
                              FincaModel(
                                id: 'f1',
                                identificador: 'F1',
                                nombre: 'Finca',
                              ),
                            ],
                            animalAEditar: animal,
                            animalesService: service,
                          ),
                        ),
                      ),
                    ),
                  ),
                  child: const Text('Abrir'),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Abrir'));
        await tester.pumpAndSettle();
        final label = venta ? 'Precio de Venta' : 'Precio de Compra (Opcional)';
        expect(tester.widget<CustomTextField>(caja(label)).suffixText, 'USD');
        await tester.ensureVisible(campo(label));
        await tester.enterText(campo(label), venta ? '1450,50' : '1500.75');
        await tester.ensureVisible(find.text('Guardar Cambios'));
        await tester.tap(find.text('Guardar Cambios'));
        await tester.pumpAndSettle();
        expect(service.guardado, isNotNull);
        if (venta) {
          expect(
            service.guardado!.observaciones,
            r'Precio de Venta: US$ 1,450.50',
          );
          expect(service.guardado!.precioCompra, 800);
        } else {
          expect(service.guardado!.precioCompra, 1500.75);
        }
        expect(find.text('COP'), findsNothing);
      },
    );
  }
}
