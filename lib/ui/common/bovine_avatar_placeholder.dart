import 'package:flutter/material.dart';

/// Placeholder estilizado de alta calidad para animales, lotes y fincas
/// cuando no poseen fotografías o cuando la descarga de red falla.
class BovineAvatarPlaceholder extends StatelessWidget {
  final String? titulo;
  final String? subtitulo;
  final String? sexo; // 'Macho' | 'Hembra'
  final String? tipoExplotacion; // 'Lecheria' | 'Ceba' | 'Cria' | 'Doble Proposito'
  final double width;
  final double height;
  final BorderRadius? borderRadius;
  final bool isFinca;
  final bool isLote;

  const BovineAvatarPlaceholder({
    super.key,
    this.titulo,
    this.subtitulo,
    this.sexo,
    this.tipoExplotacion,
    this.width = double.infinity,
    this.height = 140,
    this.borderRadius,
    this.isFinca = false,
    this.isLote = false,
  });

  factory BovineAvatarPlaceholder.animal({
    Key? key,
    required String? areteOMote,
    required String? razaODescripcion,
    String? sexo,
    String? tipoExplotacion,
    double width = double.infinity,
    double height = 140,
    BorderRadius? borderRadius,
  }) {
    return BovineAvatarPlaceholder(
      key: key,
      titulo: areteOMote,
      subtitulo: razaODescripcion,
      sexo: sexo,
      tipoExplotacion: tipoExplotacion,
      width: width,
      height: height,
      borderRadius: borderRadius,
    );
  }

  factory BovineAvatarPlaceholder.finca({
    Key? key,
    required String nombreFinca,
    String? identificador,
    double width = double.infinity,
    double height = 140,
    BorderRadius? borderRadius,
  }) {
    return BovineAvatarPlaceholder(
      key: key,
      titulo: nombreFinca,
      subtitulo: identificador,
      isFinca: true,
      width: width,
      height: height,
      borderRadius: borderRadius,
    );
  }

  factory BovineAvatarPlaceholder.lote({
    Key? key,
    required String nombreLote,
    String? proposito,
    double width = double.infinity,
    double height = 140,
    BorderRadius? borderRadius,
  }) {
    return BovineAvatarPlaceholder(
      key: key,
      titulo: nombreLote,
      subtitulo: proposito,
      isLote: true,
      width: width,
      height: height,
      borderRadius: borderRadius,
    );
  }

  String _extraerIniciales(String? texto) {
    if (texto == null || texto.trim().isEmpty) return 'GN';
    final partes = texto.trim().split(RegExp(r'\s+'));
    if (partes.length >= 2) {
      final p1 = partes[0].isNotEmpty ? partes[0][0].toUpperCase() : '';
      final p2 = partes[1].isNotEmpty ? partes[1][0].toUpperCase() : '';
      return '$p1$p2';
    }
    return texto.trim().length >= 2
        ? texto.trim().substring(0, 2).toUpperCase()
        : texto.trim().toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveRadius = borderRadius ?? BorderRadius.circular(12);

    // Paleta de gradientes según la entidad zootécnica
    List<Color> gradientColors;
    IconData icon;
    Color badgeColor;

    if (isFinca) {
      gradientColors = const [Color(0xFF1E3A2F), Color(0xFF2D5A47)];
      icon = Icons.landscape_rounded;
      badgeColor = const Color(0xFF4ADE80);
    } else if (isLote) {
      gradientColors = const [Color(0xFF3B2F1F), Color(0xFF5D472F)];
      icon = Icons.grid_view_rounded;
      badgeColor = const Color(0xFFFBBF24);
    } else {
      final esMacho = sexo == 'Macho';
      if (esMacho) {
        gradientColors = const [Color(0xFF1E293B), Color(0xFF0F3A5D)];
        icon = Icons.male_rounded;
        badgeColor = const Color(0xFF38BDF8);
      } else {
        gradientColors = const [Color(0xFF261E38), Color(0xFF4C1D42)];
        icon = Icons.female_rounded;
        badgeColor = const Color(0xFFF472B6);
      }
    }

    final iniciales = _extraerIniciales(titulo);

    return Container(
      width: width,
      height: height,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: effectiveRadius,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 130;
          if (isCompact) {
            final size = (constraints.maxWidth * 0.52).clamp(24.0, 42.0);
            return Center(
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.15),
                  border: Border.all(
                    color: badgeColor.withValues(alpha: 0.7),
                    width: 1.5,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  iniciales,
                  style: TextStyle(
                    color: badgeColor,
                    fontSize: size * 0.42,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          }

          return Stack(
            fit: StackFit.expand,
            children: [
              // Patrón de fondo abstracto (ícono grande con baja opacidad)
              Positioned(
                right: -15,
                bottom: -20,
                child: Icon(
                  icon,
                  size: height * 0.9,
                  color: Colors.white.withValues(alpha: 0.07),
                ),
              ),

              // Contenido central estilizado
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Monograma circular estilizado
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.12),
                        border: Border.all(
                          color: badgeColor.withValues(alpha: 0.6),
                          width: 1.5,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        iniciales,
                        style: TextStyle(
                          color: badgeColor,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Título y subtítulo con etiqueta zootécnica
                    Flexible(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            titulo ?? 'Sin Identificación',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 3),
                          if (subtitulo != null && subtitulo!.trim().isNotEmpty)
                            Text(
                              subtitulo!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 11.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          if (tipoExplotacion != null) ...[
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                tipoExplotacion!,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

