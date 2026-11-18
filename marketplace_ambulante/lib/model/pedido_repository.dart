import 'pedido.dart';

class PedidoException implements Exception {
  const PedidoException(this.mensaje);
  final String mensaje;

  @override
  String toString() => mensaje;
}

/// Contrato para los pedidos.
abstract interface class PedidoRepository {
  /// Pedidos que recibió el negocio (los más recientes primero).
  Future<List<Pedido>> obtenerPorNegocio(String negocioId);

  /// Pedidos que hizo el usuario (los más recientes primero).
  Future<List<Pedido>> obtenerPorUsuario(String usuarioId);

  /// Crea un pedido nuevo (queda "pendiente" hasta que el negocio responda).
  Future<Pedido> crearPedido({
    required String usuarioId,
    required String clienteNombre,
    required String negocioId,
    required String negocioNombre,
    required String modalidadPagoId,
    required List<DetallePedido> detalles,
  });

  /// El cliente cancela su pedido. Solo mientras siga "pendiente".
  Future<Pedido> cancelarPorCliente(String pedidoId);

  /// Cambia el estado. Para `rechazado` y `cancelado` el [motivo] es
  /// obligatorio. Lanza [PedidoException] si el cambio no es válido
  /// (por ejemplo, si el pedido ya había cambiado).
  Future<Pedido> cambiarEstado(
    String pedidoId,
    EstadoPedido nuevo, {
    String? motivo,
  });
}
