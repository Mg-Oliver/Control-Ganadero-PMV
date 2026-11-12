enum ColumnaTabla {
  arete,
  nombreAlias,
  sexo,
  categoria,
  raza,
  peso,
  potrero,
  finca,
  estado,
}

extension ColumnaTablaLabel on ColumnaTabla {
  String get label {
    switch (this) {
      case ColumnaTabla.arete:
        return 'Arete de manejo';
      case ColumnaTabla.nombreAlias:
        return 'Nombre / Alias';
      case ColumnaTabla.sexo:
        return 'Sexo';
      case ColumnaTabla.categoria:
        return 'Categoría';
      case ColumnaTabla.raza:
        return 'Raza / Composición';
      case ColumnaTabla.peso:
        return 'Peso actual';
      case ColumnaTabla.potrero:
        return 'Potrero';
      case ColumnaTabla.finca:
        return 'Finca';
      case ColumnaTabla.estado:
        return 'Estado';
    }
  }

  bool get esAnclaje => this == ColumnaTabla.arete;
}

const kColumnasDefault = {
  ColumnaTabla.arete,
  ColumnaTabla.sexo,
  ColumnaTabla.categoria,
  ColumnaTabla.raza,
  ColumnaTabla.estado,
};
