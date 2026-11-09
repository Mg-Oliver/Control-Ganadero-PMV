enum AptitudProductiva { carne, leche, dobleProposito, criolla }

class RazaItem {
  final String id;
  final String nombre;
  final AptitudProductiva aptitud;
  final String origen;

  const RazaItem({
    required this.id,
    required this.nombre,
    required this.aptitud,
    required this.origen,
  });

  String get aptitudLabel {
    switch (aptitud) {
      case AptitudProductiva.carne:
        return 'Carne';
      case AptitudProductiva.leche:
        return 'Leche';
      case AptitudProductiva.dobleProposito:
        return 'Doble Propósito';
      case AptitudProductiva.criolla:
        return 'Criolla';
    }
  }
}

class RazasCatalog {
  static const List<RazaItem> razas = [
    // Carne
    RazaItem(id: 'brahman_gris', nombre: 'Brahman Gris', aptitud: AptitudProductiva.carne, origen: 'Cebú / India - EE.UU.'),
    RazaItem(id: 'brahman_rojo', nombre: 'Brahman Rojo', aptitud: AptitudProductiva.carne, origen: 'Cebú / India - EE.UU.'),
    RazaItem(id: 'nelore', nombre: 'Nelore', aptitud: AptitudProductiva.carne, origen: 'Cebú / Brasil'),
    RazaItem(id: 'angus_negro', nombre: 'Angus Negro', aptitud: AptitudProductiva.carne, origen: 'Taurino / Escocia'),
    RazaItem(id: 'red_angus', nombre: 'Red Angus', aptitud: AptitudProductiva.carne, origen: 'Taurino / Escocia'),
    RazaItem(id: 'brangus', nombre: 'Brangus', aptitud: AptitudProductiva.carne, origen: 'Sintética (Angus x Brahman)'),
    RazaItem(id: 'charolais', nombre: 'Charolais', aptitud: AptitudProductiva.carne, origen: 'Taurino / Francia'),
    RazaItem(id: 'simmental', nombre: 'Simmental', aptitud: AptitudProductiva.carne, origen: 'Taurino / Suiza'),
    RazaItem(id: 'limousin', nombre: 'Limousin', aptitud: AptitudProductiva.carne, origen: 'Taurino / Francia'),
    RazaItem(id: 'hereford', nombre: 'Hereford', aptitud: AptitudProductiva.carne, origen: 'Taurino / Inglaterra'),
    RazaItem(id: 'senepol', nombre: 'Senepol', aptitud: AptitudProductiva.carne, origen: 'Taurino Criollo / St. Croix'),
    RazaItem(id: 'wagyu', nombre: 'Wagyu', aptitud: AptitudProductiva.carne, origen: 'Taurino / Japón'),

    // Leche
    RazaItem(id: 'holstein', nombre: 'Holstein', aptitud: AptitudProductiva.leche, origen: 'Taurino / Países Bajos'),
    RazaItem(id: 'jersey', nombre: 'Jersey', aptitud: AptitudProductiva.leche, origen: 'Taurino / Reino Unido'),
    RazaItem(id: 'pardo_suizo', nombre: 'Pardo Suizo', aptitud: AptitudProductiva.leche, origen: 'Taurino / Suiza'),
    RazaItem(id: 'gyr_lechero', nombre: 'Gyr Lechero', aptitud: AptitudProductiva.leche, origen: 'Cebú / Brasil - India'),
    RazaItem(id: 'guernsey', nombre: 'Guernsey', aptitud: AptitudProductiva.leche, origen: 'Taurino / Reino Unido'),
    RazaItem(id: 'ayrshire', nombre: 'Ayrshire', aptitud: AptitudProductiva.leche, origen: 'Taurino / Escocia'),

    // Doble Propósito / Criollas
    RazaItem(id: 'girolando', nombre: 'Girolando', aptitud: AptitudProductiva.dobleProposito, origen: 'Sintética (Holstein x Gyr)'),
    RazaItem(id: 'simbrah', nombre: 'Simbrah', aptitud: AptitudProductiva.dobleProposito, origen: 'Sintética (Simmental x Brahman)'),
    RazaItem(id: 'guzera', nombre: 'Guzerá', aptitud: AptitudProductiva.dobleProposito, origen: 'Cebú / Brasil - India'),
    RazaItem(id: 'beefmaster', nombre: 'Beefmaster', aptitud: AptitudProductiva.dobleProposito, origen: 'Sintética / EE.UU.'),
    RazaItem(id: 'santa_gertrudis', nombre: 'Santa Gertrudis', aptitud: AptitudProductiva.dobleProposito, origen: 'Sintética / EE.UU.'),
    RazaItem(id: 'blanco_orejinegro', nombre: 'Blanco Orejinegro (BON)', aptitud: AptitudProductiva.criolla, origen: 'Criollo Colombiano'),
    RazaItem(id: 'romosinuano', nombre: 'Romosinuano', aptitud: AptitudProductiva.criolla, origen: 'Criollo Colombiano'),
    RazaItem(id: 'costeno_con_cuernos', nombre: 'Costeño con Cuernos', aptitud: AptitudProductiva.criolla, origen: 'Criollo Colombiano'),
  ];

  static const List<String> fraccionesZootecnicas = [
    '1/2',
    '3/4',
    '1/4',
    '5/8',
    '3/8',
    '7/8',
    '1/8',
  ];

  static List<RazaItem> porAptitud(AptitudProductiva aptitud) {
    return razas.where((r) => r.aptitud == aptitud).toList();
  }
}

