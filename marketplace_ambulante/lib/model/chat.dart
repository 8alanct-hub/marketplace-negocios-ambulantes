/// Tabla `conversaciones`: un chat entre un usuario y un negocio.
class Conversacion {
  const Conversacion({
    required this.id,
    required this.usuarioId,
    required this.negocioId,
    required this.negocioNombre,
    required this.fechaUltimoMensaje,
    this.ultimoMensaje,
  });

  final String id;
  final String usuarioId;
  final String negocioId;

  /// Nombre del negocio (en el backend real vendría unido desde `negocios`).
  final String negocioNombre;
  final DateTime fechaUltimoMensaje;

  /// Texto del último mensaje, para mostrar en la lista de chats.
  final String? ultimoMensaje;

  Conversacion copyWith({String? ultimoMensaje, DateTime? fechaUltimoMensaje}) =>
      Conversacion(
        id: id,
        usuarioId: usuarioId,
        negocioId: negocioId,
        negocioNombre: negocioNombre,
        fechaUltimoMensaje: fechaUltimoMensaje ?? this.fechaUltimoMensaje,
        ultimoMensaje: ultimoMensaje ?? this.ultimoMensaje,
      );
}

/// Tabla `mensajes`.
class Mensaje {
  const Mensaje({
    required this.id,
    required this.conversacionId,
    required this.remitenteId,
    required this.texto,
    required this.fechaEnvio,
    this.leido = false,
  });

  final String id;
  final String conversacionId;

  /// id del usuario o del negocio que lo escribió.
  final String remitenteId;

  /// Columna `mensaje`.
  final String texto;
  final DateTime fechaEnvio;
  final bool leido;
}
