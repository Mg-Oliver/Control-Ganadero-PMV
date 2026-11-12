import 'package:flutter/material.dart';
import '../../../data/models/animal_model.dart';
import '../../../data/services/animales_service.dart';
import '../../../data/services/fincas_service.dart';
import '../creacion/forms/animal_form.dart';

class AnimalesExternosScreen extends StatefulWidget {
  final AnimalesService? animalesService;
  const AnimalesExternosScreen({super.key, this.animalesService});

  @override
  State<AnimalesExternosScreen> createState() => _AnimalesExternosScreenState();
}

class _AnimalesExternosScreenState extends State<AnimalesExternosScreen> {
  late final AnimalesService _service =
      widget.animalesService ?? AnimalesService();
  late Future<List<AnimalModel>> _animales;
  String _busqueda = '';

  @override
  void initState() {
    super.initState();
    _recargar();
  }

  void _recargar() {
    _animales = _service.consultarInventarioRelacional().then(
      (animales) => animales.where((a) => a.esExterno).toList(),
    );
  }

  Future<void> _abrir(AnimalModel animal) async {
    try {
      final fincas = await FincasService().obtenerTodas();
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(title: const Text('Animal externo')),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: AnimalForm(
                fincas: fincas,
                animalAEditar: animal,
                animalesService: _service,
              ),
            ),
          ),
        ),
      );
      if (mounted) setState(_recargar);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo abrir el animal. Intente nuevamente.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Animales externos'),
      actions: [
        IconButton(
          tooltip: 'Actualizar',
          onPressed: () => setState(_recargar),
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    body: Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            decoration: const InputDecoration(
              labelText: 'Buscar por arete o nombre',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: (value) =>
                setState(() => _busqueda = value.trim().toLowerCase()),
          ),
        ),
        Expanded(
          child: FutureBuilder<List<AnimalModel>>(
            future: _animales,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(
                  child: TextButton(
                    onPressed: () => setState(_recargar),
                    child: const Text(
                      'No se pudieron cargar los animales. Reintentar',
                    ),
                  ),
                );
              }
              final lista = snapshot.data!
                  .where(
                    (a) => [
                      a.areteManejo,
                      a.areteOficial ?? '',
                      a.nombreAlias ?? '',
                      a.codigoSistema,
                    ].any((v) => v.toLowerCase().contains(_busqueda)),
                  )
                  .toList();
              if (lista.isEmpty) {
                return const Center(
                  child: Text('Sin animales externos para mostrar.'),
                );
              }
              return ListView.separated(
                itemCount: lista.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final animal = lista[index];
                  return ListTile(
                    leading: Icon(
                      animal.sexo == 'Macho' ? Icons.male : Icons.female,
                    ),
                    title: Text(
                      '${animal.areteManejo} · ${animal.nombreAlias ?? animal.codigoSistema}',
                    ),
                    subtitle: Text(
                      '${animal.sexo} · ${animal.razaEtiquetaDisplay} · ${animal.edadFormateada}',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _abrir(animal),
                  );
                },
              );
            },
          ),
        ),
      ],
    ),
  );
}
