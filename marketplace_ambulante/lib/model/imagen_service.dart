import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

enum FuenteImagen { camara, galeria }

/// Foto elegida por el usuario, todavía sin subir.
class ImagenElegida {
  const ImagenElegida({required this.bytes, required this.mime});

  final Uint8List bytes;

  /// Tipo de archivo, ej. "image/jpeg".
  final String mime;
}

class ImagenException implements Exception {
  const ImagenException(this.mensaje, {this.permisoBloqueado = false});

  final String mensaje;

  /// true si el usuario negó el permiso (hay que mandarlo a Ajustes).
  final bool permisoBloqueado;

  @override
  String toString() => mensaje;
}

/// Abre la cámara o el selector de fotos del sistema.
abstract interface class ImagenService {
  /// Devuelve null si el usuario canceló.
  Future<ImagenElegida?> elegir(FuenteImagen fuente);
}

/// Implementación con el paquete image_picker.
///
/// En Android 13+ la galería usa el selector de fotos del sistema, que no
/// necesita permiso. La cámara sí lo pide la primera vez (aviso del sistema).
class ImagenServicePicker implements ImagenService {
  final _picker = ImagePicker();

  @override
  Future<ImagenElegida?> elegir(FuenteImagen fuente) async {
    try {
      final archivo = await _picker.pickImage(
        source: fuente == FuenteImagen.camara
            ? ImageSource.camera
            : ImageSource.gallery,
        // Reduce el peso de la foto antes de subirla.
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 80,
      );
      if (archivo == null) return null; // canceló
      return ImagenElegida(
        bytes: await archivo.readAsBytes(),
        mime: archivo.mimeType ?? 'image/jpeg',
      );
    } on PlatformException catch (e) {
      if (e.code == 'camera_access_denied' ||
          e.code == 'photo_access_denied') {
        throw ImagenException(
          fuente == FuenteImagen.camara
              ? 'Para tomar fotos de tu negocio necesitamos acceso a la '
                  'cámara. Puedes activarlo en los ajustes de la app.'
              : 'Para elegir fotos necesitamos acceso a tu galería. '
                  'Puedes activarlo en los ajustes de la app.',
          permisoBloqueado: true,
        );
      }
      throw ImagenException(
        fuente == FuenteImagen.camara
            ? 'No se pudo abrir la cámara.'
            : 'No se pudo abrir la galería.',
      );
    }
  }
}
