import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/config/supabase_config.dart';
import '../../../ui/controllers/inventario_controller.dart';
import 'configuracion_categorias_screen.dart';

class ConfiguracionScreen extends StatefulWidget {
  final InventarioController? inventarioController;

  const ConfiguracionScreen({super.key, this.inventarioController});

  @override
  State<ConfiguracionScreen> createState() => _ConfiguracionScreenState();
}

class _ConfiguracionScreenState extends State<ConfiguracionScreen> {
  bool _verificando = false;
  bool? _conectado;

  Future<void> _verificarConexion() async {
    setState(() {
      _verificando = true;
      _conectado = null;
    });
    try {
      final client = SupabaseConfig.client;
      await client.from('fincas').select('id').limit(1);
      if (mounted) setState(() => _conectado = true);
    } catch (_) {
      if (mounted) setState(() => _conectado = false);
    } finally {
      if (mounted) setState(() => _verificando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            icon: Icons.cloud_outlined,
            title: 'Conexión a Supabase',
          ),
          const SizedBox(height: 12),
          _ConexionCard(
            verificando: _verificando,
            conectado: _conectado,
            onVerificar: _verificarConexion,
          ),
          const SizedBox(height: 28),
          _SectionHeader(
            icon: Icons.info_outline_rounded,
            title: 'Acerca de la Aplicación',
          ),
          const SizedBox(height: 12),
          _InfoCard(),
          const SizedBox(height: 28),
          _SectionHeader(
            icon: Icons.tune_rounded,
            title: 'Opciones Generales',
          ),
          const SizedBox(height: 12),
          _OpcionesCard(),
          const SizedBox(height: 28),
          _SectionHeader(
            icon: Icons.category_outlined,
            title: 'Categorías Zootécnicas',
          ),
          const SizedBox(height: 12),
          _CategoriasCard(
            inventarioController: widget.inventarioController,
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;

  const _SectionHeader({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }
}

class _ConexionCard extends StatelessWidget {
  final bool verificando;
  final bool? conectado;
  final VoidCallback onVerificar;

  const _ConexionCard({
    required this.verificando,
    required this.conectado,
    required this.onVerificar,
  });

  @override
  Widget build(BuildContext context) {
    Color statusColor = AppColors.textSecondary;
    IconData statusIcon = Icons.circle_outlined;
    String statusLabel = 'Estado desconocido';

    if (verificando) {
      statusColor = AppColors.warning;
      statusIcon = Icons.sync_rounded;
      statusLabel = 'Verificando…';
    } else if (conectado == true) {
      statusColor = AppColors.success;
      statusIcon = Icons.check_circle_outline_rounded;
      statusLabel = 'Conectado correctamente';
    } else if (conectado == false) {
      statusColor = AppColors.error;
      statusIcon = Icons.error_outline_rounded;
      statusLabel = 'Sin conexión — revise las credenciales';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(statusIcon, color: statusColor, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              statusLabel,
              style: TextStyle(
                fontSize: 14,
                color: statusColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 12),
          OutlinedButton.icon(
            onPressed: verificando ? null : onVerificar,
            icon: verificando
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Verificar'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final items = [
      ('Aplicación', 'Control Ganadero Bovino'),
      ('Versión', '1.0.0 · MVP Fase 5'),
      ('Framework', 'Flutter 3 · Dart >= 3.8'),
      ('Backend', 'Supabase / PostgreSQL 15+'),
    ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: items
            .map(
              (e) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    SizedBox(
                      width: 100,
                      child: Text(
                        e.$1,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    Text(
                      e.$2,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _OpcionesCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: const Column(
        children: [
          ListTile(
            leading: Icon(Icons.language_rounded,
                color: AppColors.textSecondary),
            title: Text('Idioma', style: TextStyle(fontSize: 14)),
            trailing: Text(
              'Español (ES)',
              style: TextStyle(
                  fontSize: 13, color: AppColors.textSecondary),
            ),
            onTap: null,
          ),
          Divider(height: 1, indent: 56),
          ListTile(
            leading: Icon(Icons.dark_mode_outlined,
                color: AppColors.textSecondary),
            title: Text('Tema', style: TextStyle(fontSize: 14)),
            trailing: Text(
              'Claro (por defecto)',
              style: TextStyle(
                  fontSize: 13, color: AppColors.textSecondary),
            ),
            onTap: null,
          ),
        ],
      ),
    );
  }
}

class _CategoriasCard extends StatelessWidget {
  final InventarioController? inventarioController;

  const _CategoriasCard({this.inventarioController});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        leading:
            const Icon(Icons.edit_note_rounded, color: AppColors.primary),
        title: const Text(
          'Configurar Categorías',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        subtitle: const Text(
          'Editar rangos de edad, agregar categorías personalizadas o restaurar valores de fábrica.',
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        trailing: const Icon(Icons.chevron_right_rounded,
            color: AppColors.textSecondary),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ConfiguracionCategoriasScreen(
                inventarioController: inventarioController,
              ),
            ),
          );
        },
      ),
    );
  }
}
