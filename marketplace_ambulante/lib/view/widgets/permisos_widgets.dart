import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../model/imagen_service.dart';
import '../../viewmodel/resultado.dart';
import 'auth_widgets.dart';

/// Menú inferior: "Tomar foto" / "Elegir de la galería" / "Cancelar".
/// Devuelve null si el usuario cancela.
Future<FuenteImagen?> elegirFuenteImagen(
  BuildContext context, {
  String titulo = 'Agregar foto',
}) {
  return showModalBottomSheet<FuenteImagen>(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              titulo,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.photo_camera_outlined),
            title: const Text('Tomar foto'),
            onTap: () => Navigator.pop(context, FuenteImagen.camara),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: const Text('Elegir de la galería'),
            onTap: () => Navigator.pop(context, FuenteImagen.galeria),
          ),
          ListTile(
            leading: const Icon(Icons.close),
            title: const Text('Cancelar'),
            onTap: () => Navigator.pop(context),
          ),
        ],
      ),
    ),
  );
}

/// Pop-up que explica por qué se necesita un permiso, con botón a Ajustes.
Future<void> mostrarDialogoAjustes(
  BuildContext context, {
  required String mensaje,
  required AjustesDestino destino,
  required VoidCallback onAbrirAjustes,
}) {
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(
        destino == AjustesDestino.ubicacion
            ? 'Activa tu ubicación'
            : 'Permiso necesario',
      ),
      content: Text(mensaje),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Ahora no'),
        ),
        FilledButton(
          // El tema hace los botones de ancho completo; aquí no.
          style: FilledButton.styleFrom(minimumSize: const Size(0, 40)),
          onPressed: () {
            Navigator.pop(context);
            onAbrirAjustes();
          },
          child: const Text('Abrir ajustes'),
        ),
      ],
    ),
  );
}

/// Muestra lo que corresponde según el [Resultado] de una acción.
Future<void> procesarResultado(
  BuildContext context,
  Resultado resultado, {
  required void Function(AjustesDestino destino) abrirAjustes,
}) async {
  switch (resultado) {
    case Exito():
      break;
    case Fallo(:final mensaje):
      mostrarMensaje(context, mensaje);
    case RequiereAjustes(:final mensaje, :final destino):
      await mostrarDialogoAjustes(
        context,
        mensaje: mensaje,
        destino: destino,
        onAbrirAjustes: () => abrirAjustes(destino),
      );
  }
}

/// Muestra una imagen a partir de su URL (http o "data:" del mock).
class ImagenDesdeUrl extends StatelessWidget {
  const ImagenDesdeUrl({super.key, required this.url, this.fit = BoxFit.cover});

  final String url;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    if (url.startsWith('data:')) {
      return Image.memory(
        UriData.parse(url).contentAsBytes(),
        fit: fit,
        gaplessPlayback: true,
      );
    }
    return Image.network(
      url,
      fit: fit,
      errorBuilder: (context, error, stackTrace) => const ColoredBox(
        color: AppColors.grisFondo,
        child: Center(
          child: Icon(Icons.broken_image_outlined, color: AppColors.grisTexto),
        ),
      ),
    );
  }
}
