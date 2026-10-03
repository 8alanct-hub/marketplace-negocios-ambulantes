import 'imagen_service.dart';
import 'modalidad_pago.dart';
import 'negocio.dart';

/// Contrato para los datos de los negocios.
abstract interface class NegocioRepository {
  /// Crea el negocio de [propietarioId]. Si ya tenía uno, actualiza su tipo.
  Future<Negocio> crearNegocio({
    required String propietarioId,
    required TipoNegocio tipo,
  });

  /// Negocio del usuario, o null si todavía no tiene.
  Future<Negocio?> obtenerPorPropietario(String propietarioId);

  Future<Negocio?> obtenerPorId(String negocioId);

  /// Negocios visibles en el Marketplace (con nombre y ubicación).
  Future<List<Negocio>> obtenerNegociosPublicados();

  /// Guarda todos los datos del negocio y devuelve la versión guardada.
  Future<Negocio> actualizarNegocio(Negocio negocio);

  /// Sube una imagen (portada, logo o producto) y devuelve su URL.
  Future<String> subirImagen(ImagenElegida imagen);

  /// Catálogo de formas de pago (tabla `modalidades_pago`).
  Future<List<ModalidadPago>> obtenerModalidadesPago();

  /// ids de las formas de pago que acepta el negocio.
  Future<Set<String>> obtenerModalidadesDelNegocio(String negocioId);

  Future<void> guardarModalidadesDelNegocio(
    String negocioId,
    Set<String> modalidadIds,
  );
}
