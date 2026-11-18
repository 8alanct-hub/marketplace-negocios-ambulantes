import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../core/config/api_config.dart';

class ApiException implements Exception {
  const ApiException(this.message, this.statusCode);

  final String message;
  final int statusCode;

  @override
  String toString() => message;
}

class ApiService {
  ApiService({required this._storage, http.Client? client})
    : _client = client ?? http.Client();

  final FlutterSecureStorage _storage;
  final http.Client _client;

  static const String _tokenKey = 'access_token';

  // ============================================================
  // GET
  // ============================================================

  Future<Map<String, dynamic>> get(String path, {bool authenticated = false}) {
    return _send('GET', path, authenticated: authenticated);
  }

  // ============================================================
  // POST
  // ============================================================

  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
    bool authenticated = false,
  }) {
    return _send('POST', path, body: body, authenticated: authenticated);
  }

  // ============================================================
  // PATCH
  // ============================================================

  Future<Map<String, dynamic>> patch(
    String path, {
    Map<String, dynamic>? body,
    bool authenticated = false,
  }) {
    return _send('PATCH', path, body: body, authenticated: authenticated);
  }

  // ============================================================
  // PUT
  // ============================================================

  Future<Map<String, dynamic>> put(
    String path, {
    Map<String, dynamic>? body,
    bool authenticated = false,
  }) {
    return _send('PUT', path, body: body, authenticated: authenticated);
  }

  Future<Map<String, dynamic>> delete(
    String path, {
    bool authenticated = false,
  }) {
    return _send('DELETE', path, authenticated: authenticated);
  }
  // ============================================================
  // SUBIR IMAGEN (MULTIPART)
  // ============================================================

  Future<Map<String, dynamic>> subirImagen({
    required String tipo,
    required Uint8List bytes,
    required String mime,
  }) async {
    if (tipo != 'logo' && tipo != 'banner') {
      throw const ApiException(
        'El tipo de imagen debe ser logo o banner.',
        400,
      );
    }

    final token = await _storage.read(key: _tokenKey);

    if (token == null || token.isEmpty) {
      throw const ApiException(
        'No hay una sesión activa. Inicia sesión nuevamente.',
        401,
      );
    }

    final extension = switch (mime.toLowerCase()) {
      'image/jpeg' => 'jpg',
      'image/png' => 'png',
      'image/webp' => 'webp',
      _ => throw const ApiException('Formato de imagen no permitido.', 415),
    };

    final uri = Uri.parse('${ApiConfig.baseUrl}/negocios/mio/imagenes/$tipo');

    final request = http.MultipartRequest('POST', uri);

    request.headers['Accept'] = 'application/json';
    request.headers['Authorization'] = 'Bearer $token';

    request.files.add(
      http.MultipartFile.fromBytes(
        'archivo',
        bytes,
        filename: 'imagen.$extension',
      ),
    );

    try {
      final streamedResponse = await _client
          .send(request)
          .timeout(ApiConfig.timeout);

      final response = await http.Response.fromStream(streamedResponse);

      final dynamic decoded = response.body.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(utf8.decode(response.bodyBytes));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final detail = decoded is Map<String, dynamic>
            ? decoded['detail']
            : null;

        throw ApiException(
          detail is String ? detail : 'No se pudo subir la imagen.',
          response.statusCode,
        );
      }

      if (decoded is! Map<String, dynamic>) {
        throw const ApiException(
          'El servidor devolvió una respuesta inválida.',
          0,
        );
      }

      return decoded;
    } on ApiException {
      rethrow;
    } on http.ClientException {
      throw const ApiException('No se pudo conectar con el servidor.', 0);
    } on FormatException {
      throw const ApiException(
        'El servidor devolvió una respuesta inválida.',
        0,
      );
    } on TimeoutException {
      throw const ApiException(
        'La subida de la imagen excedió el tiempo de espera.',
        0,
      );
    }
  }

  Future<Map<String, dynamic>> subirImagenProducto({
    required String idProducto,
    required Uint8List bytes,
    required String mime,
  }) async {
    if (idProducto.isEmpty) {
      throw const ApiException(
        'El producto no tiene un identificador válido.',
        400,
      );
    }

    final token = await _storage.read(key: _tokenKey);

    if (token == null || token.isEmpty) {
      throw const ApiException(
        'No hay una sesión activa. Inicia sesión nuevamente.',
        401,
      );
    }

    final extension = switch (mime.toLowerCase()) {
      'image/jpeg' => 'jpg',
      'image/png' => 'png',
      'image/webp' => 'webp',
      _ => throw const ApiException('Formato de imagen no permitido.', 415),
    };

    final uri = Uri.parse('${ApiConfig.baseUrl}/productos/$idProducto/imagen');

    final request = http.MultipartRequest('POST', uri);

    request.headers['Accept'] = 'application/json';
    request.headers['Authorization'] = 'Bearer $token';

    request.files.add(
      http.MultipartFile.fromBytes(
        'archivo',
        bytes,
        filename: 'imagen.$extension',
      ),
    );

    try {
      final streamedResponse = await _client
          .send(request)
          .timeout(ApiConfig.timeout);

      final response = await http.Response.fromStream(streamedResponse);

      final dynamic decoded = response.body.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(utf8.decode(response.bodyBytes));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final detail = decoded is Map<String, dynamic>
            ? decoded['detail']
            : null;

        throw ApiException(
          detail is String
              ? detail
              : 'No se pudo subir la imagen del producto.',
          response.statusCode,
        );
      }

      if (decoded is! Map<String, dynamic>) {
        throw const ApiException(
          'El servidor devolvió una respuesta inválida.',
          0,
        );
      }

      return decoded;
    } on ApiException {
      rethrow;
    } on http.ClientException {
      throw const ApiException('No se pudo conectar con el servidor.', 0);
    } on FormatException {
      throw const ApiException(
        'El servidor devolvió una respuesta inválida.',
        0,
      );
    } on TimeoutException {
      throw const ApiException(
        'La subida de la imagen excedió el tiempo de espera.',
        0,
      );
    }
  }

  // ============================================================
  // PETICIONES HTTP GENERALES
  // ============================================================

  Future<Map<String, dynamic>> _send(
    String method,
    String path, {
    Map<String, dynamic>? body,
    bool authenticated = false,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$path');

    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

    if (authenticated) {
      final token = await _storage.read(key: _tokenKey);

      if (token == null || token.isEmpty) {
        throw const ApiException(
          'No hay una sesión activa. Inicia sesión nuevamente.',
          401,
        );
      }

      headers['Authorization'] = 'Bearer $token';
    }

    try {
      late http.Response response;

      switch (method) {
        case 'GET':
          response = await _client
              .get(uri, headers: headers)
              .timeout(ApiConfig.timeout);
          break;

        case 'POST':
          response = await _client
              .post(uri, headers: headers, body: jsonEncode(body ?? {}))
              .timeout(ApiConfig.timeout);
          break;

        case 'PATCH':
          response = await _client
              .patch(uri, headers: headers, body: jsonEncode(body ?? {}))
              .timeout(ApiConfig.timeout);
          break;

        case 'PUT':
          response = await _client
              .put(uri, headers: headers, body: jsonEncode(body ?? {}))
              .timeout(ApiConfig.timeout);
          break;

        case 'DELETE':
          response = await _client
              .delete(uri, headers: headers)
              .timeout(ApiConfig.timeout);
          break;

        default:
          throw const ApiException('Método HTTP no soportado.', 0);
      }

      final dynamic decoded = response.body.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(utf8.decode(response.bodyBytes));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final detail = decoded is Map<String, dynamic>
            ? decoded['detail']
            : null;

        throw ApiException(
          detail is String ? detail : 'Error de comunicación con el servidor.',
          response.statusCode,
        );
      }

      if (decoded == null) {
        return <String, dynamic>{};
      }

      if (decoded is! Map<String, dynamic>) {
        throw const ApiException(
          'El servidor devolvió una respuesta inválida.',
          0,
        );
      }

      return decoded;
    } on ApiException {
      rethrow;
    } on http.ClientException {
      throw const ApiException('No se pudo conectar con el servidor.', 0);
    } on FormatException {
      throw const ApiException(
        'El servidor devolvió una respuesta inválida.',
        0,
      );
    }
  }

  // ============================================================
  // GESTIÓN DEL TOKEN
  // ============================================================

  Future<void> guardarToken(String token) {
    return _storage.write(key: _tokenKey, value: token);
  }

  Future<void> eliminarToken() {
    return _storage.delete(key: _tokenKey);
  }

  Future<String?> obtenerToken() {
    return _storage.read(key: _tokenKey);
  }

  // ============================================================
  // CERRAR CLIENTE HTTP
  // ============================================================

  void close() {
    _client.close();
  }
}
