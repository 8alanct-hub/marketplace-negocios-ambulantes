import 'chat.dart';

/// Contrato para el chat entre usuarios y negocios.
abstract interface class ChatRepository {
  /// Chats del usuario (el más reciente primero).
  Future<List<Conversacion>> obtenerConversaciones(String usuarioId);

  /// Devuelve el chat con ese negocio; si no existe, lo crea.
  Future<Conversacion> obtenerOCrearConversacion({
    required String usuarioId,
    required String negocioId,
    required String negocioNombre,
  });

  /// Mensajes de la conversación, actualizados en tiempo real
  /// (cada vez que llega uno nuevo, el Stream emite la lista completa).
  Stream<List<Mensaje>> escucharMensajes(String conversacionId);

  Future<Mensaje> enviarMensaje({
    required String conversacionId,
    required String remitenteId,
    required String texto,
  });
}
