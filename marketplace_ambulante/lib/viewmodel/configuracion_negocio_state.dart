import '../model/categoria.dart';
import '../model/imagen_service.dart';
import '../model/modalidad_pago.dart';
import '../model/negocio.dart';
import '../model/producto.dart';

/// Estado de "Configuración de negocio".
///
/// Los textos (nombre, descripción, teléfono, dirección) viven en los
/// campos de la View y se envían al guardar. Aquí está todo lo demás.
class ConfiguracionNegocioState {
  const ConfiguracionNegocioState({
    required this.negocio,
    required this.negocioGuardado,
    required this.modalidades,
    required this.modalidadesElegidas,
    required this.modalidadesGuardadas,
    required this.categorias,
    required this.productos,
    this.portadaNueva,
    this.logoNuevo,
    this.guardando = false,
    this.ubicando = false,
  });

  /// Versión que se está editando: incluye el tipo y la ubicación aunque
  /// todavía no se hayan guardado.
  final Negocio negocio;

  /// Versión guardada (para saber si hay cambios sin guardar).
  final Negocio negocioGuardado;

  /// Todas las formas de pago que existen.
  final List<ModalidadPago> modalidades;

  /// ids de las formas de pago marcadas.
  final Set<String> modalidadesElegidas;
  final Set<String> modalidadesGuardadas;

  final List<Categoria> categorias;

  /// Los productos se guardan al momento (no esperan a "Guardar cambios").
  final List<Producto> productos;

  /// Fotos elegidas que se subirán al presionar "Guardar cambios".
  final ImagenElegida? portadaNueva;
  final ImagenElegida? logoNuevo;

  final bool guardando;
  final bool ubicando;

  bool get ocupado => guardando || ubicando;

  /// true si algo cambió desde la última vez que se guardó.
  /// Los textos se pasan desde la View porque viven en sus campos.
  /// (Los productos no cuentan: se guardan al momento.)
  bool hayCambios({
    required String nombre,
    required String descripcion,
    required String telefono,
    required String direccion,
  }) {
    final g = negocioGuardado;
    final mismasModalidades =
        modalidadesElegidas.length == modalidadesGuardadas.length &&
            modalidadesElegidas.containsAll(modalidadesGuardadas);
    return portadaNueva != null ||
        logoNuevo != null ||
        negocio.tipo != g.tipo ||
        negocio.latitud != g.latitud ||
        negocio.longitud != g.longitud ||
        !mismasModalidades ||
        nombre.trim() != g.nombre ||
        descripcion.trim() != g.descripcion ||
        telefono.trim() != g.telefono ||
        (negocio.tipo == TipoNegocio.fijo && direccion.trim() != g.direccion);
  }

  ConfiguracionNegocioState copyWith({
    Negocio? negocio,
    Negocio? negocioGuardado,
    Set<String>? modalidadesElegidas,
    Set<String>? modalidadesGuardadas,
    List<Producto>? productos,
    ImagenElegida? portadaNueva,
    ImagenElegida? logoNuevo,
    bool? guardando,
    bool? ubicando,
    bool limpiarImagenesNuevas = false,
  }) =>
      ConfiguracionNegocioState(
        negocio: negocio ?? this.negocio,
        negocioGuardado: negocioGuardado ?? this.negocioGuardado,
        modalidades: modalidades,
        modalidadesElegidas: modalidadesElegidas ?? this.modalidadesElegidas,
        modalidadesGuardadas:
            modalidadesGuardadas ?? this.modalidadesGuardadas,
        categorias: categorias,
        productos: productos ?? this.productos,
        portadaNueva:
            limpiarImagenesNuevas ? null : portadaNueva ?? this.portadaNueva,
        logoNuevo: limpiarImagenesNuevas ? null : logoNuevo ?? this.logoNuevo,
        guardando: guardando ?? this.guardando,
        ubicando: ubicando ?? this.ubicando,
      );
}
