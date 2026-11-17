import 'api_cliente.dart';
import 'api_json.dart';
import 'pedido.dart';
import 'pedido_repository.dart';

/// Pedidos con la API real.
///
/// La API revisa todo (stock, forma de pago, cambios de estado válidos) y
/// toma los precios de la base de datos, no de la app.
class PedidoRepositoryApi implements PedidoRepository {
  PedidoRepositoryApi(this._api);

  final ApiCliente _api;

  /// Convierte los errores de la API en [PedidoException] (mismo mensaje).
  Future<Pedido> _pedido(Future<dynamic> Function() accion) async {
    try {
      return pedidoDesdeJson(await accion() as Json);
    } on ApiException catch (e) {
      throw PedidoException(e.mensaje);
    }
  }

  /// El servidor devuelve los pedidos del negocio del usuario con sesión.
  @override
  Future<List<Pedido>> obtenerPorNegocio(String negocioId) async =>
      listaDesdeJson(await _api.get('/app/yo/negocio/pedidos'), pedidoDesdeJson);

  @override
  Future<List<Pedido>> obtenerPorUsuario(String usuarioId) async =>
      listaDesdeJson(await _api.get('/app/yo/pedidos'), pedidoDesdeJson);

  @override
  Future<Pedido> crearPedido({
    required String usuarioId,
    required String clienteNombre,
    required String negocioId,
    required String negocioNombre,
    required String modalidadPagoId,
    required List<DetallePedido> detalles,
  }) =>
      _pedido(() => _api.post('/app/pedidos', {
            'negocioId': negocioId,
            'modalidadPagoId': modalidadPagoId,
            'detalles': [
              for (final d in detalles)
                {'productoId': d.productoId, 'cantidad': d.cantidad},
            ],
          }));

  @override
  Future<Pedido> cancelarPorCliente(String pedidoId) =>
      _pedido(() => _api.post('/app/pedidos/$pedidoId/cancelar'));

  @override
  Future<Pedido> cambiarEstado(
    String pedidoId,
    EstadoPedido nuevo, {
    String? motivo,
  }) =>
      _pedido(() => _api.patch('/app/pedidos/$pedidoId/estado', {
            'estado': estadoPedidoAApi(nuevo),
            'motivo': motivo,
          }));
}
