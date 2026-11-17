import 'dart:async';

import 'api_cliente.dart';
import 'api_json.dart';
import 'chat.dart';
import 'chat_repository.dart';

/// Chat con la API real.
///
/// Mientras un chat está abierto, la app pregunta cada [intervalo] si hay
/// mensajes nuevos ("polling"). Es sencillo y suficiente para este proyecto;
/// más adelante se podría cambiar por WebSockets sin tocar las pantallas.
class ChatRepositoryApi implements ChatRepository {
  ChatRepositoryApi(this._api, {this.intervalo = const Duration(seconds: 3)});

  final ApiCliente _api;
  final Duration intervalo;

  /// conversacionId → función que busca mensajes nuevos ya mismo
  /// (se usa al enviar, para que el mensaje aparezca sin esperar).
  final Map<String, Future<void> Function()> _refrescar = {};

  @override
  Future<List<Conversacion>> obtenerConversaciones(String usuarioId) async =>
      listaDesdeJson(
        await _api.get('/app/yo/conversaciones'),
        conversacionDesdeJson,
      );

  @override
  Future<Conversacion> obtenerOCrearConversacion({
    required String usuarioId,
    required String negocioId,
    required String negocioNombre,
  }) async {
    final datos = await _api.post('/app/conversaciones', {'negocioId': negocioId});
    return conversacionDesdeJson(datos as Json);
  }

  @override
  Stream<List<Mensaje>> escucharMensajes(String conversacionId) {
    final mensajes = <Mensaje>[];
    var primeraCarga = true;
    var consultando = false;
    Timer? timer;
    late final StreamController<List<Mensaje>> canal;

    Future<void> consultar() async {
      if (consultando || canal.isClosed) return;
      consultando = true;
      try {
        // Solo se piden los mensajes posteriores al último que ya tenemos.
        final despues = mensajes.isEmpty ? '' : '?despues=${mensajes.last.id}';
        final nuevos = listaDesdeJson(
          await _api.get('/app/conversaciones/$conversacionId/mensajes$despues'),
          mensajeDesdeJson,
        );
        if (canal.isClosed) return;
        if (primeraCarga || nuevos.isNotEmpty) {
          primeraCarga = false;
          mensajes.addAll(nuevos);
          canal.add(List.unmodifiable(mensajes));
        }
      } catch (e) {
        // Si falla la primera carga, la pantalla muestra el error.
        // Si falla después, se reintenta en la siguiente vuelta.
        if (primeraCarga && !canal.isClosed) canal.addError(e);
      } finally {
        consultando = false;
      }
    }

    canal = StreamController<List<Mensaje>>(
      onListen: () {
        _refrescar[conversacionId] = consultar;
        consultar();
        timer = Timer.periodic(intervalo, (_) => consultar());
      },
      onCancel: () {
        timer?.cancel();
        _refrescar.remove(conversacionId);
        return canal.close();
      },
    );
    return canal.stream;
  }

  @override
  Future<Mensaje> enviarMensaje({
    required String conversacionId,
    required String remitenteId,
    required String texto,
  }) async {
    final datos = await _api.post(
      '/app/conversaciones/$conversacionId/mensajes',
      {'texto': texto.trim()},
    );
    // Que aparezca en la pantalla sin esperar la siguiente vuelta.
    unawaited(_refrescar[conversacionId]?.call());
    return mensajeDesdeJson(datos as Json);
  }
}
