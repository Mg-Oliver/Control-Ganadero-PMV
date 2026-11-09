import 'package:intl/intl.dart';

class Formatters {
  static String formatearMoneda(double? valor) {
    if (valor == null) return '\$0';
    return NumberFormat.currency(
      locale: 'es_CO',
      symbol: '\$',
      decimalDigits: 0,
    ).format(valor);
  }

  static String formatearPeso(double? kg) {
    if (kg == null) return '0.00 kg';
    return '${kg.toStringAsFixed(2)} kg';
  }

  static String formatearFecha(DateTime? fecha) {
    if (fecha == null) return '-';
    return DateFormat('dd/MM/yyyy').format(fecha);
  }
}

