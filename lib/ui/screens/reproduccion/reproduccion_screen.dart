import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

/// Pantalla 3: Ciclo de Reproducción.
/// Módulo reservado para próximas fases (celos, servicios, palpaciones,
/// gestaciones y partos). Por ahora se muestra vacío.
class ReproduccionScreen extends StatelessWidget {
  const ReproduccionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.favorite_border_rounded,
              size: 64,
              color: AppColors.primary.withValues(alpha: 0.35),
            ),
            const SizedBox(height: 16),
            const Text(
              'Ciclo de Reproducción',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Este módulo estará disponible próximamente.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}

