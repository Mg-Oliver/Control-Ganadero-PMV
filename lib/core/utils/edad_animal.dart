class EdadAnimal {
  final int anios, meses, dias;
  const EdadAnimal(this.anios, this.meses, this.dias);

  static DateTime _mesConDia(int anio, int mes, int dia) {
    final base = DateTime(anio, mes);
    final ultimo = DateTime(base.year, base.month + 1, 0).day;
    return DateTime(base.year, base.month, dia > ultimo ? ultimo : dia);
  }

  static EdadAnimal desdeFecha(DateTime nacimiento, DateTime referencia) {
    final hoy = DateTime(referencia.year, referencia.month, referencia.day);
    final fecha = DateTime(nacimiento.year, nacimiento.month, nacimiento.day);
    if (fecha.isAfter(hoy)) {
      throw ArgumentError('El nacimiento no puede ser futuro');
    }
    var meses = (hoy.year - fecha.year) * 12 + hoy.month - fecha.month;
    var aniversario = _mesConDia(fecha.year, fecha.month + meses, fecha.day);
    if (aniversario.isAfter(hoy)) {
      meses--;
      aniversario = _mesConDia(fecha.year, fecha.month + meses, fecha.day);
    }
    return EdadAnimal(
      meses ~/ 12,
      meses % 12,
      hoy.difference(aniversario).inDays,
    );
  }

  static bool esMayorDeMeses(
    DateTime nacimiento,
    int meses,
    DateTime referencia,
  ) {
    final hoy = DateTime(referencia.year, referencia.month, referencia.day);
    final limite = _mesConDia(
      nacimiento.year,
      nacimiento.month + meses,
      nacimiento.day,
    );
    return hoy.isAfter(limite);
  }

  DateTime fechaNacimiento(DateTime referencia) {
    if (anios < 0 ||
        anios > 150 ||
        meses < 0 ||
        meses > 11 ||
        dias < 0 ||
        dias > 30) {
      throw ArgumentError('Edad fuera de rango');
    }
    return _mesConDia(
      referencia.year - anios,
      referencia.month - meses,
      referencia.day,
    ).subtract(Duration(days: dias));
  }
}
