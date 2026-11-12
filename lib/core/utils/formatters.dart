import 'package:intl/intl.dart';

class Formatters {
  static const codigoMoneda = 'USD';

  static String formatearMoneda(double? valor) {
    return NumberFormat.currency(
      locale: 'en_US',
      name: codigoMoneda,
      symbol: 'US\$ ',
      decimalDigits: 2,
    ).format(valor ?? 0);
  }

  static String formatearMonedaCompacta(double valor) {
    if (valor >= 1000000000) return '${formatearMoneda(valor / 1000000000)} B';
    if (valor >= 1000000) return '${formatearMoneda(valor / 1000000)} M';
    return formatearMoneda(valor);
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
