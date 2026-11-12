import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/animal_model.dart';
import '../../../data/services/animales_service.dart';
import '../../controllers/inventario_controller.dart';
import '../creacion/forms/animal_form.dart';

class EditarAnimalScreen extends StatelessWidget {
  final AnimalModel animal;
  final InventarioController controller;
  final AnimalesService? animalesService;

  const EditarAnimalScreen({
    super.key,
    required this.animal,
    required this.controller,
    this.animalesService,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Editar animal · ${animal.areteManejo}',
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: AnimalForm(
              fincas: controller.allFincas,
              animalAEditar: animal,
              animalesService: animalesService,
              onAnimalUpdated: (actualizado) {
                controller.actualizarAnimalOptimista(actualizado);
              },
            ),
          ),
        ),
      ),
    );
  }
}

