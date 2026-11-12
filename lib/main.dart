import 'package:flutter/material.dart';
import 'core/config/supabase_config.dart';
import 'core/constants/app_colors.dart';
import 'core/services/app_feedback.dart';
import 'core/services/categoria_rules_service.dart';
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
  CategoriaRulesService.updateInstance(await CategoriaRulesService.cargar());
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
//   1 → Inventario       (InventarioScreen)
//   2 → Ciclo Reproductivo (ReproduccionScreen)
//   3 → Configuración    (ConfiguracionScreen)
//
// AppDrawer permanent sidebar destination index → main index (0-3).

const List<String> _sectionTitles = [
  'Panel de Control',
  'Inventario',
  'Ciclo Reproductivo',
  'Configuración',
];

class MainWorkspaceShell extends StatefulWidget {
  final int initialIndex;
  final InventarioController? inventarioController;

  const MainWorkspaceShell({
    super.key,
    this.initialIndex = 0,
    this.inventarioController,
  });

  @override
  State<MainWorkspaceShell> createState() => _MainWorkspaceShellState();
}

class _MainWorkspaceShellState extends State<MainWorkspaceShell> {
  late int _selectedIndex;
  late final InventarioController _inventarioController;
  final _navigatorKeys = List.generate(4, (_) => GlobalKey<NavigatorState>());
  final _registroTab = ValueNotifier<int?>(null);
  Route<void>? _registroRoute;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex.clamp(0, 3);
    _inventarioController =
        widget.inventarioController ?? InventarioController();
    if (widget.inventarioController == null) {
      _inventarioController.inicializar().then((_) {
        if (mounted && _inventarioController.allAnimales.isEmpty) {
          SeedService.cargarEnControlador(_inventarioController);
        }
      });
    }
  }

  @override
  void dispose() {
    if (widget.inventarioController == null) _inventarioController.dispose();
    _registroTab.dispose();
    super.dispose();
  }

  void _navigateTo(int index) {
    setState(() => _selectedIndex = index.clamp(0, 3));
  }

  void _volverAlRegistro() {
    final tab = _registroTab.value;
    final route = _registroRoute;
    if (tab == null || route == null) return;
    _navigatorKeys[tab].currentState!.popUntil((r) => identical(r, route));
    _navigateTo(tab);
  }

  Future<void> _abrirCreacion(ModuloCreacionTab tab) async {
    if (tab == ModuloCreacionTab.animal && _registroTab.value != null) {
      _volverAlRegistro();
      return;
    }
    final origen = _selectedIndex;
    final route = MaterialPageRoute<void>(
      builder: (_) => CreacionScreen(
        inventarioController: _inventarioController,
        showAppBar: true,
        initialTab: tab,
        onFincaCreatedGlobal: _inventarioController.registrarFincaOptimista,
        onLoteCreatedGlobal: _inventarioController.registrarLoteOptimista,
        onAnimalCreatedGlobal: _inventarioController.registrarAnimalOptimista,
      ),
    );
    if (tab == ModuloCreacionTab.animal) {
      _registroRoute = route;
      _registroTab.value = origen;
    }
    await _navigatorKeys[origen].currentState!.push(route);
    if (mounted && identical(_registroRoute, route)) {
      _registroRoute = null;
      _registroTab.value = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          // Menú lateral izquierdo fijo (sin ícono de hamburguesa)
          AppDrawer(
            selectedIndex: _selectedIndex,
            onDestinationSelected: _navigateTo,
          ),
          // Contenido principal de la aplicación
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: [
                for (var index = 0; index < 4; index++)
                  NavigatorPopHandler<void>(
                    enabled: _selectedIndex == index,
                    onPopWithResult: (_) {
                      final navigator = _navigatorKeys[index].currentState;
                      if (_selectedIndex == index &&
                          navigator != null &&
                          navigator.canPop()) {
                        navigator.pop();
                      }
                    },
                    child: Navigator(
                      key: _navigatorKeys[index],
                      onGenerateRoute: (_) => MaterialPageRoute<void>(
                        builder: (_) => ValueListenableBuilder<int?>(
                          valueListenable: _registroTab,
                          builder: (_, _, _) => _buildSection(index),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(int index) => Scaffold(
    backgroundColor: AppColors.background,
    appBar: AppBar(
      automaticallyImplyLeading: false, // Sin ícono de menú hamburguesa
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      toolbarHeight: index == 0 ? 80 : kToolbarHeight,
      title: Text(
        _sectionTitles[index],
        style: TextStyle(
          fontSize: index == 0 ? 30 : 17,
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: [
        if (index == 0)
          IconButton(
            tooltip: 'Poblar Datos Semilla (Demo)',
            icon: const Icon(Icons.dataset_outlined, size: 20),
            onPressed: () async {
              SeedService.cargarEnControlador(_inventarioController);
              final sincronizado = await SeedService.repoblarEnSupabase();
              if (!mounted) return;
              AppFeedback.mostrarExito(
                context: context,
                mensaje: sincronizado
                    ? '¡Datos semilla cargados y sincronizados con Supabase! (3 fincas, 6 mangas y 28 animales)'
                    : '¡Datos semilla cargados con éxito! (3 fincas, 6 mangas y 28 animales)',
              );
            },
          ),
      ],
    ),
    body: <Widget Function()>[
      // 0: Panel de Control
      () => DashboardScreen(
        controller: _inventarioController,
        onGoToExpediente: () => _abrirCreacion(ModuloCreacionTab.animal),
        onGoToInventario: () => _navigateTo(1),
        onRegistrarAnimal: () => _abrirCreacion(ModuloCreacionTab.animal),
      ),
      // 1: Inventario
      () => InventarioScreen(
        externalController: _inventarioController,
        onVolverAlRegistro: _registroTab.value != null
            ? _volverAlRegistro
            : null,
        onGoToCreacion: () => _abrirCreacion(ModuloCreacionTab.animal),
        onGoToCrearFinca: () => _abrirCreacion(ModuloCreacionTab.finca),
        onGoToCrearManga: () => _abrirCreacion(ModuloCreacionTab.lote),
      ),
      // 2: Ciclo Reproductivo
      () => ReproduccionScreen(inventarioController: _inventarioController),
      // 3: Configuración
      () => ConfiguracionScreen(inventarioController: _inventarioController),
    ][index](),
  );
}
