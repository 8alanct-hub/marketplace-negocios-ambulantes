import '../model/negocio.dart';
import '../model/pedido.dart';

/// Estado del "Panel del negocio".
class PanelNegocioState {
  const PanelNegocioState({
    required this.negocio,
    required this.pedidos,
    required this.nombresModalidad,
    this.pedidoEnProceso,
    this.ubicando = false,
  });

  final Negocio negocio;

  /// Todos los pedidos, los más recientes primero.
  final List<Pedido> pedidos;

  /// id de modalidad → nombre ("Contraentrega", ...).
  final Map<String, String> nombresModalidad;

  /// id del pedido que se está actualizando (para mostrar su spinner).
  final String? pedidoEnProceso;
  final bool ubicando;

  List<Pedido> get nuevos =>
      pedidos.where((p) => p.estado.esNuevo).toList();
  List<Pedido> get enCurso =>
      pedidos.where((p) => p.estado.enCurso).toList();
  List<Pedido> get historial =>
      pedidos.where((p) => p.estado.terminado).toList();

  String nombreModalidad(String id) => nombresModalidad[id] ?? '—';

  PanelNegocioState copyWith({
    Negocio? negocio,
    List<Pedido>? pedidos,
    String? pedidoEnProceso,
    bool limpiarPedidoEnProceso = false,
    bool? ubicando,
  }) =>
      PanelNegocioState(
        negocio: negocio ?? this.negocio,
        pedidos: pedidos ?? this.pedidos,
        nombresModalidad: nombresModalidad,
        pedidoEnProceso: limpiarPedidoEnProceso
            ? null
            : pedidoEnProceso ?? this.pedidoEnProceso,
        ubicando: ubicando ?? this.ubicando,
      );
}
