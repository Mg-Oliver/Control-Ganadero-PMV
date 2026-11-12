import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// Simula las respuestas PostgREST sin crear registros en la finca real.
class AnimalesSchemaServer {
  final bool legado;
  bool denegarAnimal = false, denegarGenealogia = false;
  int intentosAnimal = 0, insertados = 0, borrados = 0;
  final animales = <String, Map<String, dynamic>>{};
  final genealogias = <String, Map<String, dynamic>>{};
  AnimalesSchemaServer({this.legado = true});
  late final http.Client client = MockClient((request) async {
    final response = await _handle(request);
    return http.Response.bytes(
      response.bodyBytes,
      response.statusCode,
      headers: response.headers,
      request: request,
    );
  });
  http.Response _json(Object? data, [int status = 200]) => http.Response(
    jsonEncode(data),
    status,
    headers: {'content-type': 'application/json'},
  );
  http.Response _ausente(String tabla, String campo) => _json({
    'code': 'PGRST204',
    'message':
        "Could not find the '$campo' column of '$tabla' in the schema cache",
    'details': null,
    'hint': null,
  }, 400);
  http.Response _denegado() => _json({
    'code': '42501',
    'message': 'new row violates row-level security policy',
    'details': null,
    'hint': null,
  }, 403);
  Future<http.Response> _handle(http.Request request) async {
    final tabla = request.url.pathSegments.last;
    final filtro = request.url.queryParameters['id'];
    final id = filtro?.replaceFirst('eq.', '');
    final body = request.body.isEmpty
        ? <String, dynamic>{}
        : Map<String, dynamic>.from(jsonDecode(request.body) as Map);
    if (tabla == 'animales') {
      if (request.method == 'POST' || request.method == 'PATCH') {
        intentosAnimal++;
        if (denegarAnimal) return _denegado();
        if (legado) {
          for (final c in ['es_externo', 'numero_partos']) {
            if (body.containsKey(c)) return _ausente(tabla, c);
          }
        }
        final clave = id ?? body['id'] as String;
        final dato = {
          ...?animales[clave],
          ...body,
          'id': clave,
          'codigo_sistema': 'GAN-${animales.length + 1}',
        };
        animales[clave] = dato;
        if (request.method == 'POST') insertados++;
        return request.method == 'POST'
            ? _json(dato, 201)
            : http.Response('', 204);
      }
      if (request.method == 'DELETE') {
        animales.remove(id);
        genealogias.remove(id);
        borrados++;
        return http.Response('', 204);
      }
      if (request.method == 'GET') {
        Map<String, dynamic> conGene(Map<String, dynamic> a) => {
          ...a,
          'genealogia': genealogias[a['id']],
        };
        if (id != null) return _json(conGene(animales[id]!));
        return _json(animales.values.map(conGene).toList());
      }
    }
    if (tabla == 'genealogia') {
      if (request.method == 'POST') {
        if (denegarGenealogia) return _denegado();
        if (legado) {
          for (final c in ['toro_donante_id', 'toro_donante_snapshot']) {
            if (body.containsKey(c)) return _ausente(tabla, c);
          }
        }
        final dato = {...body, 'id': 'g-${body['animal_id']}'};
        genealogias[body['animal_id'] as String] = dato;
        return request.headers['prefer']?.contains('return=representation') ==
                true
            ? _json(dato, 201)
            : http.Response('', 201);
      }
      if (request.method == 'GET') return _json(genealogias.values.toList());
    }
    return _json({'code': '404', 'message': 'Ruta de prueba desconocida'}, 404);
  }
}
