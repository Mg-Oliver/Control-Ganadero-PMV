import 'package:flutter/material.dart';
import 'core/config/supabase_config.dart';
import 'core/constants/app_colors.dart';
import 'core/services/app_feedback.dart';
import 'data/dev/seed_service.dart';
import 'ui/controllers/inventario_controller.dart';
import 'ui/screens/creacion/creacion_screen.dart';
import 'ui/screens/inventario/inventario_screen.dart';
import 'ui/screens/reproduccion/reproduccion_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await SupabaseConfig.initialize();
  } catch (e) {
    debugPrint('Supabase init notice: $e');
  }
  runApp(const BovinoApp());
}

class BovinoApp extends StatelessWidget {
  const BovinoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      scaffoldMessengerKey: AppFeedback.messengerKey,
      title: 'MVP Bovino Ganadero',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        primaryColor: AppColors.primary,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          secondary: AppColors.secondary,
        ),
      ),
      home: const MainWorkspaceShell(),
    );
  }
}

class MainWorkspaceShell extends StatefulWidget {
  final int initialIndex;

  const MainWorkspaceShell({
    super.key,
    this.initialIndex = 0,
  });

  @override
  State<MainWorkspaceShell> createState() => _MainWorkspaceShellState();
}

class _MainWorkspaceShellState extends State<MainWorkspaceShell>
    with SingleTickerProviderStateMixin {
  late int _selectedModule;
  late final TabController _tabController;
  final _inventarioController = InventarioController();

  @override
  void initState() {
    super.initState();
    _selectedModule = widget.initialIndex.clamp(0, 2);
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: _selectedModule,
    );
    _tabController.addListener(() {
      if (_tabController.index != _selectedModule) {
        setState(() => _selectedModule = _tabController.index);
      }
    });
    _inventarioController.inicializar();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _inventarioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.agriculture_rounded, size: 23),
            SizedBox(width: 8),
            Flexible(
              child: Text(
                'MVP Ganadero',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Poblar Datos Semilla (Demo)',
            icon: const Icon(Icons.dataset_outlined, size: 20),
            onPressed: () {
              SeedService.cargarEnControlador(_inventarioController);
              AppFeedback.mostrarExito(
                context: context,
                mensaje:
                    '¡Datos semilla cargados con éxito! (3 fincas, 6 lotes y 28 animales con genealogía)',
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: MediaQuery.sizeOf(context).width < 600,
          tabAlignment: MediaQuery.sizeOf(context).width < 600
              ? TabAlignment.start
              : TabAlignment.fill,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          tabs: const [
            Tab(
              icon: Icon(Icons.edit_note_rounded, size: 20),
              text: 'Expediente',
              iconMargin: EdgeInsets.only(bottom: 2),
            ),
            Tab(
              icon: Icon(Icons.inventory_2_outlined, size: 20),
              text: 'Catálogo',
              iconMargin: EdgeInsets.only(bottom: 2),
            ),
            Tab(
              icon: Icon(Icons.favorite_border_rounded, size: 20),
              text: 'Ciclo de Reproducción',
              iconMargin: EdgeInsets.only(bottom: 2),
            ),
          ],
        ),
      ),
      body: IndexedStack(
        index: _selectedModule,
        children: [
          // Pestaña 1: Expediente (alta de Fincas, Lotes y Animales)
          CreacionScreen(
            showAppBar: false,
            onFincaCreatedGlobal: _inventarioController.registrarFincaOptimista,
            onLoteCreatedGlobal: _inventarioController.registrarLoteOptimista,
            onAnimalCreatedGlobal:
                _inventarioController.registrarAnimalOptimista,
          ),
          // Pestaña 2: Catálogo (todo lo registrado)
          InventarioScreen(
            externalController: _inventarioController,
            onGoToCreacion: () => _tabController.animateTo(0),
          ),
          // Pestaña 3: Ciclo de Reproducción (vacío por ahora)
          const ReproduccionScreen(),
        ],
      ),
    );
  }
}
