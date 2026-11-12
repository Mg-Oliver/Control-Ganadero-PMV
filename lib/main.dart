import 'package:flutter/material.dart';
import 'core/config/supabase_config.dart';
import 'core/constants/app_colors.dart';
import 'core/services/app_feedback.dart';
import 'data/dev/seed_service.dart';
import 'ui/common/app_drawer.dart';
import 'ui/controllers/inventario_controller.dart';
import 'ui/screens/configuracion/configuracion_screen.dart';
import 'ui/screens/creacion/creacion_screen.dart';
import 'ui/screens/dashboard/dashboard_screen.dart';
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
      title: 'Control Ganadero Bovino',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        splashFactory: InkRipple.splashFactory,
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

// Navigation indices:
//   0 → Panel de Control (DashboardScreen)
//   1 → Expediente       (CreacionScreen)
//   2 → Inventario       (InventarioScreen)
//   3 → Ciclo Reproductivo (ReproduccionScreen)
//   4 → Configuración    (ConfiguracionScreen)
//
// Drawer destination index → main index (1:1 mapping, 0-4).

const List<String> _sectionTitles = [
  'Panel de Control',
  'Expediente',
  'Inventario',
  'Ciclo Reproductivo',
  'Configuración',
];

class MainWorkspaceShell extends StatefulWidget {
  final int initialIndex;

  const MainWorkspaceShell({
    super.key,
    this.initialIndex = 0,
  });

  @override
  State<MainWorkspaceShell> createState() => _MainWorkspaceShellState();
}

class _MainWorkspaceShellState extends State<MainWorkspaceShell> {
  late int _selectedIndex;
  ModuloCreacionTab _pendingCreacionTab = ModuloCreacionTab.finca;
  final _inventarioController = InventarioController();

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex.clamp(0, 4);
    _inventarioController.inicializar();
  }

  @override
  void dispose() {
    _inventarioController.dispose();
    super.dispose();
  }

  void _navigateTo(int index) {
    setState(() => _selectedIndex = index.clamp(0, 4));
  }

  void _irACrearFinca() {
    setState(() {
      _pendingCreacionTab = ModuloCreacionTab.finca;
      _selectedIndex = 1;
    });
  }

  void _irACrearManga() {
    setState(() {
      _pendingCreacionTab = ModuloCreacionTab.lote;
      _selectedIndex = 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: AppDrawer(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _navigateTo,
      ),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          _sectionTitles[_selectedIndex],
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (_selectedIndex == 0)
            IconButton(
              tooltip: 'Poblar Datos Semilla (Demo)',
              icon: const Icon(Icons.dataset_outlined, size: 20),
              onPressed: () {
                SeedService.cargarEnControlador(_inventarioController);
                AppFeedback.mostrarExito(
                  context: context,
                  mensaje:
                      '¡Datos semilla cargados con éxito! (3 fincas, 6 mangas y 28 animales)',
                );
              },
            ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          // 0: Panel de Control
          DashboardScreen(
            controller: _inventarioController,
            onGoToExpediente: () => _navigateTo(1),
            onGoToInventario: () => _navigateTo(2),
            onRegistrarAnimal: () {
              setState(() => _pendingCreacionTab = ModuloCreacionTab.animal);
              _navigateTo(1);
            },
          ),
          // 1: Expediente
          CreacionScreen(
            showAppBar: false,
            initialTab: _pendingCreacionTab,
            onFincaCreatedGlobal: _inventarioController.registrarFincaOptimista,
            onLoteCreatedGlobal: _inventarioController.registrarLoteOptimista,
            onAnimalCreatedGlobal:
                _inventarioController.registrarAnimalOptimista,
          ),
          // 2: Inventario
          InventarioScreen(
            externalController: _inventarioController,
            onGoToCreacion: () {
              setState(() => _pendingCreacionTab = ModuloCreacionTab.animal);
              _navigateTo(1);
            },
            onGoToCrearFinca: _irACrearFinca,
            onGoToCrearManga: _irACrearManga,
          ),
          // 3: Ciclo Reproductivo
          const ReproduccionScreen(),
          // 4: Configuración
          ConfiguracionScreen(inventarioController: _inventarioController),
        ],
      ),
    );
  }
}

