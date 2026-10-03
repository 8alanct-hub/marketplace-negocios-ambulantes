import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../model/chat.dart';
import '../model/repository_providers.dart';
import 'configuracion_negocio_viewmodel.dart' show CargaException;
import 'resultado.dart';
import 'seleccion_rol_viewmodel.dart' show errorSinSesion;
import 'sesion_viewmodel.dart';

/// Lista de chats del usuario (pantalla "Chats").
final conversacionesProvider =
    FutureProvider.autoDispose<List<Conversacion>>((ref) async {
  final sesion = ref.watch(sesionProvider);
  if (sesion == null) return const [];
  return ref.read(chatRepositoryProvider).obtenerConversaciones(sesion.id);
});

/// Abre (o crea) el chat con un negocio. Uno por negocio (".family").
final conversacionConNegocioProvider =
    FutureProvider.autoDispose.family<Conversacion, String>(
  (ref, negocioId) async {
    final sesion = ref.watch(sesionProvider);
    if (sesion == null) throw const CargaException(errorSinSesion);
    final negocio =
        await ref.read(negocioRepositoryProvider).obtenerPorId(negocioId);
    if (negocio == null) {
      throw const CargaException('Este negocio ya no está disponible.');
    }
    return ref.read(chatRepositoryProvider).obtenerOCrearConversacion(
          usuarioId: sesion.id,
          negocioId: negocio.id,
          negocioNombre: negocio.nombre,
        );
  },
);

/// Mensajes de una conversación en tiempo real (StreamProvider).
final mensajesProvider =
    StreamProvider.autoDispose.family<List<Mensaje>, String>(
  (ref, conversacionId) =>
      ref.read(chatRepositoryProvider).escucharMensajes(conversacionId),
);

/// ViewModel para enviar mensajes. Su estado es "¿se está enviando?".
class ChatViewModel extends Notifier<bool> {
  @override
  bool build() => false;

  Future<Resultado> enviar(String conversacionId, String texto) async {
    final limpio = texto.trim();
    if (limpio.isEmpty || state) return const Exito();
    final sesion = ref.read(sesionProvider);
    if (sesion == null) return const Fallo(errorSinSesion);

    state = true;
    try {
      await ref.read(chatRepositoryProvider).enviarMensaje(
            conversacionId: conversacionId,
            remitenteId: sesion.id,
            texto: limpio,
          );
      // La lista de chats muestra el último mensaje: que se actualice.
      ref.invalidate(conversacionesProvider);
      return const Exito();
    } catch (_) {
      return const Fallo('No se pudo enviar el mensaje. Intenta de nuevo.');
    } finally {
      if (ref.mounted) state = false;
    }
  }
}

final chatViewModelProvider =
    NotifierProvider<ChatViewModel, bool>(ChatViewModel.new);
