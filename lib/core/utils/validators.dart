class Validators {
  static String? requerido(
    String? value, [
    String mensaje = 'Este campo es requerido',
  ]) {
    if (value == null || value.trim().isEmpty) {
      return mensaje;
    }
    return null;
  }

  static String? numeroPositivo(
    String? value, [
    String mensaje = 'Ingrese un número válido mayor a 0',
  ]) {
    if (value == null || value.trim().isEmpty) return null;
    final parsed = double.tryParse(value.replaceAll(',', '.'));
    if (parsed == null || parsed < 0) {
      return mensaje;
    }
    return null;
  }

  static String? monedaUSD(String? value) {
    final texto = value?.trim() ?? '';
    if (texto.isEmpty) return null;
    if (!RegExp(r'^\d+([.,]\d{1,2})?$').hasMatch(texto)) {
      return 'Ingrese un importe en USD con hasta 2 decimales';
    }
    final valor = double.tryParse(texto.replaceAll(',', '.'));
    if (valor == null || !valor.isFinite || valor > 9999999999.99) {
      return 'Ingrese un importe válido en USD';
    }
    return null;
  }
}
