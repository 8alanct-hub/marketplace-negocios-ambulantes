import 'dart:async';

import 'chat.dart';
import 'chat_repository.dart';

/// Chat de prueba en memoria.
///
/// Para que se sienta "vivo", el negocio responde automáticamente al primer
/// mensaje de cada conversación. Con un backend real, las respuestas
/// llegarían por el mismo Stream (por ejemplo, con WebSockets).
class ChatRepositoryMock implements ChatRepository {
  ChatRepositoryMock({
    this.latencia = const Duration(milliseconds: 300),
    this.esperaRespuesta = const Duration(seconds: 2),
  });

  final Duration latencia;
  final Duration esperaRespuesta;

  final Map<String, Conversacion> _conversaciones = {};
  final Map<String, List<Mensaje>> _mensajes = {};
  final Map<String, StreamController<List<Mensaje>>> _canales = {};
  int _siguienteId = 1;

  Future<void> _esperar() => Future<void>.delayed(latencia);

  StreamController<List<Mensaje>> _canal(String conversacionId) =>
      _canales.putIfAbsent(
        conversacionId,
        () => StreamController<List<Mensaje>>.broadcast(),
      );

  @override
  Future<List<Conversacion>> obtenerConversaciones(String usuarioId) async {
    await _esperar();
    return _conversaciones.values
        .where((c) => c.usuarioId == usuarioId)
        .toList()
      ..sort((a, b) => b.fechaUltimoMensaje.compareTo(a.fechaUltimoMensaje));
  }

  @override
  Future<Conversacion> obtenerOCrearConversacion({
    required String usuarioId,
    required String negocioId,
    required String negocioNombre,
  }) async {
    await _esperar();
    final existente = _conversaciones.values
        .where((c) => c.usuarioId == usuarioId && c.negocioId == negocioId)
        .firstOrNull;
    if (existente != null) return existente;

    final nueva = Conversacion(
      id: 'c_${_siguienteId++}',
      usuarioId: usuarioId,
      negocioId: negocioId,
      negocioNombre: negocioNombre,
      fechaUltimoMensaje: DateTime.now(),
    );
    _conversaciones[nueva.id] = nueva;
    _mensajes[nueva.id] = [];
    return nueva;
  }

  @override
  Stream<List<Mensaje>> escucharMensajes(String conversacionId) async* {
    // Primero lo que ya hay; después, cada cambio.
    yield List.unmodifiable(_mensajes[conversacionId] ?? const []);
    yield* _canal(conversacionId).stream;
  }

  @override
  Future<Mensaje> enviarMensaje({
    required String conversacionId,
    required String remitenteId,
    required String texto,
  }) async {
    await _esperar();
    final conversacion = _conversaciones[conversacionId];
    if (conversacion == null) {
      throw StateError('La conversación no existe');
    }
    final esPrimero = (_mensajes[conversacionId] ?? const []).isEmpty;
    final mensaje = _agregar(conversacionId, remitenteId, texto.trim());

    if (esPrimero) {
      Timer(esperaRespuesta, () {
        _agregar(
          conversacionId,
          conversacion.negocioId,
          '¡Hola! Gracias por escribir a ${conversacion.negocioNombre}. '
          'En un momento te respondemos.',
        );
      });
    }
    return mensaje;
  }

  Mensaje _agregar(String conversacionId, String remitenteId, String texto) {
    final mensaje = Mensaje(
      id: 'msg_${_siguienteId++}',
      conversacionId: conversacionId,
      remitenteId: remitenteId,
      texto: texto,
      fechaEnvio: DateTime.now(),
    );
    final lista = _mensajes.putIfAbsent(conversacionId, () => [])..add(mensaje);
    _conversaciones[conversacionId] = _conversaciones[conversacionId]!
        .copyWith(ultimoMensaje: texto, fechaUltimoMensaje: mensaje.fechaEnvio);
    _canal(conversacionId).add(List.unmodifiable(lista));
    return mensaje;
  }

  /// Cierra los Streams (lo llama Riverpod al desechar el provider).
  void cerrar() {
    for (final c in _canales.values) {
      c.close();
    }
  }
}
