import 'imagen_service.dart';
import 'modalidad_pago.dart';
import 'negocio.dart';

/// Contrato para los datos de los negocios.
abstract interface class NegocioRepository {
  Future<Negocio> crearNegocio({
    required String propietarioId,
    required TipoNegocio tipo,
  });

  Future<Negocio?> obtenerPorPropietario(String propietarioId);

  Future<Negocio?> obtenerPorId(String negocioId);

  Future<List<Negocio>> obtenerNegociosPublicados();

  Future<Negocio> actualizarNegocio(Negocio negocio);

  /// Sube imágenes de productos mediante el mecanismo disponible.
  Future<String> subirImagen(ImagenElegida imagen);

  /// Sube el logo o banner del negocio.
  Future<String> subirImagenNegocio({
    required ImagenElegida imagen,
    required String tipo,
  });

  Future<List<ModalidadPago>> obtenerModalidadesPago();

  Future<Set<String>> obtenerModalidadesDelNegocio(String negocioId);

  Future<void> guardarModalidadesDelNegocio(
    String negocioId,
    Set<String> modalidadIds,
  );
}
