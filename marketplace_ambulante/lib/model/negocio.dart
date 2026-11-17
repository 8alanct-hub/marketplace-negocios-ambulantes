/// Columna `tipo` de la tabla `negocios`.
/// Ambulante: vende en distintos lugares, sin local.
/// Fijo: atiende en un establecimiento físico.
enum TipoNegocio { ambulante, fijo }

extension TipoNegocioTexto on TipoNegocio {
  String get etiqueta => switch (this) {
        TipoNegocio.ambulante => 'Negocio ambulante',
        TipoNegocio.fijo => 'Negocio fijo',
      };
}

/// Columna `estado` de `negocios`. Lo cambia el administrador desde el
/// panel web: un negocio suspendido no aparece en el Marketplace.
enum EstadoNegocio { activo, suspendido }

extension EstadoNegocioTexto on EstadoNegocio {
  String get etiqueta => switch (this) {
        EstadoNegocio.activo => 'Activo',
        EstadoNegocio.suspendido => 'Suspendido',
      };
}

/// Tabla `negocios`.
class Negocio {
  const Negocio({
    required this.id,
    required this.propietarioId,
    required this.tipo,
    this.nombre = '',
    this.descripcion = '',
    this.telefono = '',
    this.direccion = '',
    this.latitud,
    this.longitud,
    this.ubicacionActualizada,
    this.logoUrl,
    this.bannerUrl,
    this.estado = EstadoNegocio.activo,
  });

  final String id;

  /// id del [Usuario] dueño del negocio (`id_usuario`).
  final String propietarioId;
  final TipoNegocio tipo;

  /// Columna `nombre_comercial`.
  final String nombre;
  final String descripcion;
  final String telefono;

  /// Solo se usa en negocios fijos (dirección del local).
  final String direccion;

  final double? latitud;
  final double? longitud;

  /// Cuándo se tomó la ubicación (útil para ambulantes).
  /// Sugerencia: agregar esta columna a `negocios`.
  final DateTime? ubicacionActualizada;

  final String? logoUrl;
  final String? bannerUrl;

  /// Solo lo cambia el administrador (no se envía al guardar).
  final EstadoNegocio estado;

  bool get suspendido => estado == EstadoNegocio.suspendido;

  bool get tieneUbicacion => latitud != null && longitud != null;

  Negocio copyWith({
    TipoNegocio? tipo,
    String? nombre,
    String? descripcion,
    String? telefono,
    String? direccion,
    double? latitud,
    double? longitud,
    DateTime? ubicacionActualizada,
    String? logoUrl,
    String? bannerUrl,
  }) =>
      Negocio(
        id: id,
        propietarioId: propietarioId,
        tipo: tipo ?? this.tipo,
        nombre: nombre ?? this.nombre,
        descripcion: descripcion ?? this.descripcion,
        telefono: telefono ?? this.telefono,
        direccion: direccion ?? this.direccion,
        latitud: latitud ?? this.latitud,
        longitud: longitud ?? this.longitud,
        ubicacionActualizada: ubicacionActualizada ?? this.ubicacionActualizada,
        logoUrl: logoUrl ?? this.logoUrl,
        bannerUrl: bannerUrl ?? this.bannerUrl,
        estado: estado,
      );
}
