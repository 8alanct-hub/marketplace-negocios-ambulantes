import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

/// Error de la API con un mensaje listo para mostrar al usuario.
class ApiException implements Exception {
  const ApiException(this.mensaje, {this.codigo});

  final String mensaje;

  /// Código HTTP (401, 404, ...). null si no hubo respuesta del servidor.
  final int? codigo;

  bool get noEncontrado => codigo == 404;

  @override
  String toString() => mensaje;
}

/// Hace las peticiones HTTP a la API y guarda el token de la sesión.
///
/// Todos los repositorios "Api" usan este mismo cliente: así, cuando el
/// usuario inicia sesión, todas las peticiones llevan su token.
class ApiCliente {
  ApiCliente(this.urlBase, {http.Client? cliente})
      : _http = cliente ?? http.Client();

  /// Ej. https://marketplace-negocios-ambulantes.onrender.com/api
  final String urlBase;
  final http.Client _http;

  /// Token que devuelve /app/login (null = sin sesión).
  String? token;

  /// En el plan gratis de Render la API "se duerme" y la primera petición
  /// puede tardar hasta un minuto en responder.
  static const tiempoMaximo = Duration(seconds: 70);

  static const errorConexion =
      'No pudimos conectarnos. Revisa tu internet e intenta de nuevo.';

  Future<dynamic> get(String ruta) => _enviar('GET', ruta);

  Future<dynamic> post(String ruta, [Object? cuerpo]) =>
      _enviar('POST', ruta, cuerpo);

  Future<dynamic> put(String ruta, [Object? cuerpo]) =>
      _enviar('PUT', ruta, cuerpo);

  Future<dynamic> patch(String ruta, [Object? cuerpo]) =>
      _enviar('PATCH', ruta, cuerpo);

  Future<dynamic> delete(String ruta) => _enviar('DELETE', ruta);

  Future<dynamic> _enviar(String metodo, String ruta, [Object? cuerpo]) async {
    final peticion = http.Request(metodo, Uri.parse('$urlBase$ruta'));
    peticion.headers['Accept'] = 'application/json';
    if (token != null) peticion.headers['Authorization'] = 'Bearer $token';
    if (cuerpo != null) {
      peticion.headers['Content-Type'] = 'application/json; charset=utf-8';
      peticion.body = jsonEncode(cuerpo);
    }

    final http.Response respuesta;
    try {
      final enviada = await _http.send(peticion).timeout(tiempoMaximo);
      respuesta = await http.Response.fromStream(enviada).timeout(tiempoMaximo);
    } on TimeoutException {
      throw const ApiException(
        'El servidor está tardando en responder. Intenta de nuevo.',
      );
    } catch (_) {
      throw const ApiException(errorConexion);
    }

    final texto = utf8.decode(respuesta.bodyBytes);
    dynamic datos;
    if (texto.isNotEmpty) {
      try {
        datos = jsonDecode(texto);
      } on FormatException {
        datos = null;
      }
    }

    if (respuesta.statusCode >= 200 && respuesta.statusCode < 300) {
      return datos;
    }
    final mensaje = datos is Map && datos['mensaje'] is String
        ? datos['mensaje'] as String
        : 'Ocurrió un error en el servidor. Intenta de nuevo.';
    throw ApiException(mensaje, codigo: respuesta.statusCode);
  }

  void cerrar() => _http.close();
}
