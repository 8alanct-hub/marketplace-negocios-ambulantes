import '../services/api_service.dart';
import 'imagen_service.dart';
import 'modalidad_pago.dart';
import 'negocio.dart';
import 'negocio_repository.dart';

class NegocioRepositoryApi implements NegocioRepository {
  NegocioRepositoryApi({required this.api, required this.fallback});

  final ApiService api;
  final NegocioRepository fallback;

  double? _convertirDecimal(dynamic valor) {
    if (valor == null) return null;
    if (valor is num) return valor.toDouble();
    if (valor is String) return double.tryParse(valor);
    throw const FormatException('Coordenada inválida.');
  }

  // ----------------------------------------------------------
  // Conversión JSON
  // ----------------------------------------------------------

  Negocio _convertirNegocio(Map<String, dynamic> json) {
    final tipo = switch (json['tipo'] as String) {
      'AMBULANTE' => TipoNegocio.ambulante,
      'FIJO' => TipoNegocio.fijo,
      _ => throw const FormatException('Tipo de negocio desconocido.'),
    };

    return Negocio(
      id: json['id_negocio'].toString(),
      propietarioId: json['id_usuario'].toString(),
      tipo: tipo,
      nombre: json['nombre_comercial'] as String? ?? '',
      descripcion: json['descripcion'] as String? ?? '',
      telefono: json['telefono'] as String? ?? '',
      direccion: json['direccion'] as String? ?? '',
      latitud: _convertirDecimal(json['latitud']),
      longitud: _convertirDecimal(json['longitud']),
      ubicacionActualizada: json['ubicacion_actualizada'] == null
          ? null
          : DateTime.parse(json['ubicacion_actualizada'] as String),
      logoUrl: json['logo_url'] as String?,
      bannerUrl: json['banner_url'] as String?,
    );
  }

  // ----------------------------------------------------------
  // Negocios
  // ----------------------------------------------------------

  @override
  Future<Negocio> crearNegocio({
    required String propietarioId,
    required TipoNegocio tipo,
  }) async {
    final response = await api.post(
      '/negocios',
      authenticated: true,
      body: {'tipo': tipo == TipoNegocio.ambulante ? 'AMBULANTE' : 'FIJO'},
    );

    return _convertirNegocio(response);
  }

  @override
  Future<Negocio?> obtenerPorPropietario(String propietarioId) async {
    final response = await api.get('/negocios/mio', authenticated: true);

    if (response.isEmpty) return null;

    return _convertirNegocio(response);
  }

  @override
  Future<Negocio?> obtenerPorId(String negocioId) {
    return fallback.obtenerPorId(negocioId);
  }

  @override
  Future<List<Negocio>> obtenerNegociosPublicados() {
    return fallback.obtenerNegociosPublicados();
  }

  @override
  Future<Negocio> actualizarNegocio(Negocio negocio) async {
    final response = await api.patch(
      '/negocios/mio',
      authenticated: true,
      body: {
        'nombre_comercial': negocio.nombre,
        'descripcion': negocio.descripcion,
        'telefono': negocio.telefono,
        'direccion': negocio.direccion,
        'tipo': negocio.tipo == TipoNegocio.ambulante ? 'AMBULANTE' : 'FIJO',
        'latitud': negocio.latitud,
        'longitud': negocio.longitud,
      },
    );

    return _convertirNegocio(response);
  }

  // ----------------------------------------------------------
  // Imágenes
  // ----------------------------------------------------------

  /// Las imágenes de productos siguen usando el repositorio mock.
  @override
  Future<String> subirImagen(ImagenElegida imagen) {
    return fallback.subirImagen(imagen);
  }

  /// Logo y banner se suben realmente al backend.
  @override
  Future<String> subirImagenNegocio({
    required ImagenElegida imagen,
    required String tipo,
  }) async {
    final response = await api.subirImagen(
      tipo: tipo,
      bytes: imagen.bytes,
      mime: imagen.mime,
    );

    final url = response['url'];

    if (url is! String || url.isEmpty) {
      throw const FormatException(
        'El servidor no devolvió una URL de imagen válida.',
      );
    }

    return url;
  }

  // ----------------------------------------------------------
  // Modalidades de pago
  // ----------------------------------------------------------

  @override
  Future<List<ModalidadPago>> obtenerModalidadesPago() async {
    final response = await api.get('/modalidades-pago');
    final items = response['items'] as List<dynamic>;

    return items.map((item) {
      final json = item as Map<String, dynamic>;

      return ModalidadPago(
        id: json['id'].toString(),
        nombre: json['nombre'] as String,
        descripcion: json['descripcion'] as String? ?? '',
      );
    }).toList();
  }

  @override
  Future<Set<String>> obtenerModalidadesDelNegocio(String negocioId) async {
    final response = await api.get(
      '/negocios/mio/modalidades-pago',
      authenticated: true,
    );

    final ids = response['modalidad_ids'] as List<dynamic>;

    return ids.map((id) => id.toString()).toSet();
  }

  @override
  Future<void> guardarModalidadesDelNegocio(
    String negocioId,
    Set<String> modalidadIds,
  ) async {
    await api.put(
      '/negocios/mio/modalidades-pago',
      authenticated: true,
      body: {'modalidad_ids': modalidadIds.toList()},
    );
  }
}
