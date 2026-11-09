import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Servicio desacoplado y centralizado para mostrar retroalimentación global
/// (éxito, advertencia zootécnica, error de red) mediante SnackBars personalizadas
/// sin bloquear la navegación ni el hilo principal de la aplicación.
class AppFeedback {
  /// Clave global para emitir mensajes sin depender forzosamente de un BuildContext directo.
  static final GlobalKey<ScaffoldMessengerState> messengerKey =
      GlobalKey<ScaffoldMessengerState>();

  /// Muestra una notificación de éxito con estilo ganadero unificado.
  static void mostrarExito({
    BuildContext? context,
    required String mensaje,
    Duration duracion = const Duration(seconds: 4),
    String? accionLabel,
    VoidCallback? onAccion,
  }) {
    _mostrar(
      context: context,
      mensaje: mensaje,
      icono: Icons.check_circle_outline_rounded,
      colorFondo: AppColors.success,
      colorTexto: Colors.white,
      duracion: duracion,
      accionLabel: accionLabel,
      onAccion: onAccion,
    );
  }

  /// Muestra una advertencia zootécnica (inconsistencias genealógicas, fechas estimadas, etc.).
  static void mostrarAdvertenciaZootecnica({
    BuildContext? context,
    required String mensaje,
    Duration duracion = const Duration(seconds: 5),
    String? accionLabel,
    VoidCallback? onAccion,
  }) {
    _mostrar(
      context: context,
      mensaje: mensaje,
      icono: Icons.warning_amber_rounded,
      colorFondo: const Color(0xFFD97706), // Amber 600
      colorTexto: Colors.white,
      duracion: duracion,
      accionLabel: accionLabel,
      onAccion: onAccion,
    );
  }

  /// Muestra un error de red o de almacenamiento con sugerencia de reintento.
  static void mostrarError({
    BuildContext? context,
    required String mensaje,
    Duration duracion = const Duration(seconds: 5),
    String? accionLabel,
    VoidCallback? onAccion,
  }) {
    _mostrar(
      context: context,
      mensaje: mensaje,
      icono: Icons.error_outline_rounded,
      colorFondo: AppColors.error,
      colorTexto: Colors.white,
      duracion: duracion,
      accionLabel: accionLabel,
      onAccion: onAccion,
    );
  }

  /// Muestra un mensaje informativo o de proceso en segundo plano.
  static void mostrarInfo({
    BuildContext? context,
    required String mensaje,
    Duration duracion = const Duration(seconds: 3),
  }) {
    _mostrar(
      context: context,
      mensaje: mensaje,
      icono: Icons.info_outline_rounded,
      colorFondo: AppColors.primary,
      colorTexto: Colors.white,
      duracion: duracion,
    );
  }

  static void _mostrar({
    BuildContext? context,
    required String mensaje,
    required IconData icono,
    required Color colorFondo,
    required Color colorTexto,
    required Duration duracion,
    String? accionLabel,
    VoidCallback? onAccion,
  }) {
    final snackBar = SnackBar(
      duration: duracion,
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      content: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: colorFondo,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icono, color: colorTexto, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                mensaje,
                style: TextStyle(
                  color: colorTexto,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
              ),
            ),
            if (accionLabel != null && onAccion != null) ...[
              const SizedBox(width: 8),
              TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context ?? messengerKey.currentContext!)
                      .hideCurrentSnackBar();
                  onAccion();
                },
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  visualDensity: VisualDensity.compact,
                ),
                child: Text(
                  accionLabel,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ],
        ),
      ),
    );

    final messenger = context != null
        ? ScaffoldMessenger.maybeOf(context)
        : messengerKey.currentState;

    if (messenger != null) {
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(snackBar);
    }
  }
}

