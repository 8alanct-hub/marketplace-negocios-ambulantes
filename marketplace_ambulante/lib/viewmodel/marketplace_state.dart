import '../core/utils/formato.dart';
import '../model/negocio.dart';
import '../model/ubicacion_service.dart';

/// Un negocio con su distancia al usuario (null si no hay ubicación).
class NegocioCercano {
  const NegocioCercano(this.negocio, this.distanciaMetros);

  final Negocio negocio;
  final double? distanciaMetros;
}

/// Estado del "Marketplace" del usuario.
class MarketplaceState {
  const MarketplaceState({
    required this.negocios,
    this.ubicacionUsuario,
    this.avisoUbicacion,
    this.busqueda = '',
    this.ubicando = false,
  });

  /// Ordenados del más cercano al más lejano.
  final List<NegocioCercano> negocios;

  final Coordenadas? ubicacionUsuario;

  /// Mensaje si no se pudo obtener la ubicación (se muestra un aviso).
  final String? avisoUbicacion;

  final String busqueda;
  final bool ubicando;

  bool get conUbicacion => ubicacionUsuario != null;

  /// Negocios que coinciden con la búsqueda (nombre o descripción).
  List<NegocioCercano> get visibles {
    final q = Formato.normalizar(busqueda);
    if (q.isEmpty) return negocios;
    return negocios.where((n) {
      final texto =
          Formato.normalizar('${n.negocio.nombre} ${n.negocio.descripcion}');
      return texto.contains(q);
    }).toList();
  }

  MarketplaceState copyWith({
    List<NegocioCercano>? negocios,
    Coordenadas? ubicacionUsuario,
    String? avisoUbicacion,
    bool limpiarAviso = false,
    String? busqueda,
    bool? ubicando,
  }) =>
      MarketplaceState(
        negocios: negocios ?? this.negocios,
        ubicacionUsuario: ubicacionUsuario ?? this.ubicacionUsuario,
        avisoUbicacion:
            limpiarAviso ? null : avisoUbicacion ?? this.avisoUbicacion,
        busqueda: busqueda ?? this.busqueda,
        ubicando: ubicando ?? this.ubicando,
      );
}
