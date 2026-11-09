import 'dart:async';
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/config/supabase_config.dart';

/// Excepción amigable para fallas de almacenamiento y subida de archivos
class StorageException implements Exception {
  final String message;
  final Object? originalError;

  const StorageException(this.message, [this.originalError]);

  @override
  String toString() => message;
}

class StorageService {
  SupabaseClient get _supabase => SupabaseConfig.client;

  /// Ejecuta una operación asíncrona con lógica de reintentos y timeout por intento.
  Future<T> _conReintentos<T>(
    Future<T> Function() operacion, {
    int maxIntentos = 2,
    Duration timeout = const Duration(seconds: 15),
  }) async {
    int intento = 0;
    while (true) {
      intento++;
      try {
        return await operacion().timeout(timeout);
      } on TimeoutException {
        if (intento >= maxIntentos) {
          throw const StorageException(
            'Tiempo de espera agotado al comunicar con el servidor de almacenamiento. Compruebe su conexión a internet.',
          );
        }
        await Future.delayed(Duration(milliseconds: 500 * intento));
      } catch (e) {
        if (intento >= maxIntentos) {
          if (e is StorageException) rethrow;
          throw StorageException(
            'Error al cargar el archivo tras $maxIntentos intentos: $e',
            e,
          );
        }
        await Future.delayed(Duration(milliseconds: 500 * intento));
      }
    }
  }

  /// Sube un archivo binario a Supabase Storage con reintentos automáticos y timeout.
  Future<String> uploadPhoto({
    required String bucket,
    required String entityId,
    required Uint8List fileBytes,
    required String fileExtension,
  }) async {
    final sanitizedExt = fileExtension.replaceAll('.', '').toLowerCase();
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    final fileName = '$entityId/$timestamp.$sanitizedExt';

    return _conReintentos(() async {
      await _supabase.storage.from(bucket).uploadBinary(
        fileName,
        fileBytes,
        fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
      );

      return _supabase.storage.from(bucket).getPublicUrl(fileName);
    });
  }

  /// Sube múltiples fotos (máx 3) reportando progreso porcentual.
  Future<List<String>> uploadMultiplePhotos({
    required String bucket,
    required String entityId,
    required List<({Uint8List bytes, String extension})> files,
    void Function(int completed, int total)? onProgress,
  }) async {
    if (files.length > 3) {
      throw const StorageException(
        'Se permite un máximo de 3 fotografías por registro.',
      );
    }

    final urls = <String>[];
    for (int i = 0; i < files.length; i++) {
      final url = await uploadPhoto(
        bucket: bucket,
        entityId: entityId,
        fileBytes: files[i].bytes,
        fileExtension: files[i].extension,
      );
      urls.add(url);
      onProgress?.call(i + 1, files.length);
    }
    return urls;
  }
}
