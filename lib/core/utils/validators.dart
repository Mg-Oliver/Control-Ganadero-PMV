class Validators {
  static String? requerido(String? value, [String mensaje = 'Este campo es requerido']) {
    if (value == null || value.trim().isEmpty) {
      return mensaje;
    }
    return null;
  }

  static String? numeroPositivo(String? value, [String mensaje = 'Ingrese un número válido mayor a 0']) {
    if (value == null || value.trim().isEmpty) return null;
    final parsed = double.tryParse(value.replaceAll(',', '.'));
    if (parsed == null || parsed < 0) {
      return mensaje;
    }
    return null;
  }
}

