import 'dart:convert';

import 'api_cliente.dart';
import 'api_json.dart';
import 'imagen_service.dart';
import 'modalidad_pago.dart';
import 'negocio.dart';
import 'negocio_repository.dart';

/// Negocios con la API real.
///
/// Las rutas /app/yo/... siempre trabajan con el negocio del usuario que
/// inició sesión (el servidor lo sabe por el token), así que
/// [propietarioId] no se envía.
class NegocioRepositoryApi implements NegocioRepository {
  NegocioRepositoryApi(this._api);

  final ApiCliente _api;

  /// El catálogo de formas de pago casi nunca cambia: se pide una sola vez.
  List<ModalidadPago>? _modalidades;

  static const _tiposImagen = {'image/jpeg', 'image/png', 'image/webp', 'image/gif'};

  @override
  Future<Negocio> crearNegocio({
    required String propietarioId,
    required TipoNegocio tipo,
  }) async {
    final datos = await _api.post('/app/yo/negocio', {'tipo': tipo.name});
    return negocioDesdeJson(datos as Json);
  }

  @override
  Future<Negocio?> obtenerPorPropietario(String propietarioId) async {
    final datos = await _api.get('/app/yo/negocio');
    return datos == null ? null : negocioDesdeJson(datos as Json);
  }

  @override
  Future<Negocio?> obtenerPorId(String negocioId) async {
    try {
      final datos = await _api.get('/app/negocios/$negocioId');
      return negocioDesdeJson(datos as Json);
    } on ApiException catch (e) {
      if (e.noEncontrado) return null; // no existe o está suspendido
      rethrow;
    }
  }

  @override
  Future<List<Negocio>> obtenerNegociosPublicados() async =>
      listaDesdeJson(await _api.get('/app/negocios'), negocioDesdeJson);

  @override
  Future<Negocio> actualizarNegocio(Negocio negocio) async {
    final datos = await _api.put('/app/yo/negocio', negocioAJson(negocio));
    return negocioDesdeJson(datos as Json);
  }

  /// Sube la foto a la API y devuelve su dirección (https://.../imagenes/...).
  @override
  Future<String> subirImagen(ImagenElegida imagen) async {
    final mime = _tiposImagen.contains(imagen.mime) ? imagen.mime : 'image/jpeg';
    final datos = await _api.post('/app/imagenes', {
      'mime': mime,
      'base64': base64Encode(imagen.bytes),
    }) as Json;
    return datos['url'] as String;
  }

  @override
  Future<List<ModalidadPago>> obtenerModalidadesPago() async =>
      _modalidades ??=
          listaDesdeJson(await _api.get('/app/modalidades'), modalidadDesdeJson);

  @override
  Future<Set<String>> obtenerModalidadesDelNegocio(String negocioId) async {
    final datos = await _api.get('/app/negocios/$negocioId/modalidades') as List;
    return {for (final id in datos) id.toString()};
  }

  @override
  Future<void> guardarModalidadesDelNegocio(
    String negocioId,
    Set<String> modalidadIds,
  ) =>
      _api.put('/app/yo/negocio/modalidades', {'ids': modalidadIds.toList()});
}
