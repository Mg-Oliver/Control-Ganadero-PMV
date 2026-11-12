import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../controllers/inventario_controller.dart';
import 'animal_expediente_view.dart';
import 'finca_expediente_view.dart';
import 'lote_expediente_view.dart';

class ExpedienteDrawer extends StatelessWidget {
  final InventarioController controller;
  final VoidCallback? onClose;

  const ExpedienteDrawer({
    super.key,
    required this.controller,
    this.onClose,
  });

  String _tituloDrawer() {
    if (controller.selectedAnimal != null) return 'Expediente Individual Bovino';
    if (controller.selectedLote != null) return 'Ficha de Manga';
    if (controller.selectedFinca != null) return 'Ficha de Finca / Predio';
    return 'Expediente';
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return Material(
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.folder_shared_outlined,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _tituloDrawer(),
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Cerrar expediente',
                      visualDensity: VisualDensity.compact,
                      onPressed: () {
                        controller.cerrarDrawer();
                        onClose?.call();
                      },
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _buildBody(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBody() {
    if (controller.selectedAnimal != null) {
      return AnimalExpedienteView(
        animal: controller.selectedAnimal!,
        controller: controller,
      );
    }
    if (controller.selectedLote != null) {
      return LoteExpedienteView(
        lote: controller.selectedLote!,
        controller: controller,
      );
    }
    if (controller.selectedFinca != null) {
      return FincaExpedienteView(
        finca: controller.selectedFinca!,
        controller: controller,
      );
    }
    return const Center(
      child: Text(
        'Selecciona un registro para visualizar su expediente.',
        style: TextStyle(color: AppColors.textSecondary),
      ),
    );
  }
}

