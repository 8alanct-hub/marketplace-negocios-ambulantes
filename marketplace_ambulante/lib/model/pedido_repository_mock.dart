import 'mock_pedidos.dart';
import 'pedido.dart';
import 'pedido_repository.dart';

class PedidoRepositoryMock implements PedidoRepository {
  PedidoRepositoryMock({
    this.latencia = const Duration(milliseconds: 500),
    DateTime? ahora,
  }) : _pedidos = {
          for (final p in crearMockPedidos(ahora ?? DateTime.now())) p.id: p,
        };

  final Duration latencia;
  final Map<String, Pedido> _pedidos;
  int _siguienteId = 2001;

  Future<void> _esperar() => Future<void>.delayed(latencia);

  @override
  Future<List<Pedido>> obtenerPorNegocio(String negocioId) async {
    await _esperar();
    return _pedidos.values.where((p) => p.negocioId == negocioId).toList()
      ..sort((a, b) => b.fechaCreacion.compareTo(a.fechaCreacion));
  }

  @override
  Future<List<Pedido>> obtenerPorUsuario(String usuarioId) async {
    await _esperar();
    return _pedidos.values.where((p) => p.usuarioId == usuarioId).toList()
      ..sort((a, b) => b.fechaCreacion.compareTo(a.fechaCreacion));
  }

  @override
  Future<Pedido> crearPedido({
    required String usuarioId,
    required String clienteNombre,
    required String negocioId,
    required String negocioNombre,
    required String modalidadPagoId,
    required List<DetallePedido> detalles,
  }) async {
    await _esperar();
    if (detalles.isEmpty) {
      throw const PedidoException('Agrega al menos un producto.');
    }
    final ahora = DateTime.now();
    final pedido = Pedido(
      id: '${_siguienteId++}',
      usuarioId: usuarioId,
      clienteNombre: clienteNombre,
      negocioId: negocioId,
      negocioNombre: negocioNombre,
      modalidadPagoId: modalidadPagoId,
      estado: EstadoPedido.pendiente,
      detalles: detalles,
      fechaCreacion: ahora,
      fechaActualizacion: ahora,
    );
    _pedidos[pedido.id] = pedido;
    return pedido;
  }

  @override
  Future<Pedido> cancelarPorCliente(String pedidoId) async {
    await _esperar();
    final actual = _pedidos[pedidoId];
    if (actual == null) {
      throw const PedidoException('Este pedido ya no existe.');
    }
    if (!actual.estado.esNuevo) {
      throw const PedidoException(
        'El negocio ya respondió tu pedido. Escríbele por el chat si '
        'necesitas cambiar algo.',
      );
    }
    final cancelado = actual.copyWith(
      estado: EstadoPedido.cancelado,
      fechaActualizacion: DateTime.now(),
      motivo: 'Cancelado por el cliente',
    );
    _pedidos[pedidoId] = cancelado;
    return cancelado;
  }

  @override
  Future<Pedido> cambiarEstado(
    String pedidoId,
    EstadoPedido nuevo, {
    String? motivo,
  }) async {
    await _esperar();
    final actual = _pedidos[pedidoId];
    if (actual == null) {
      throw const PedidoException('Este pedido ya no existe.');
    }

    final esRechazo = nuevo == EstadoPedido.rechazado;
    final esCancelacion = nuevo == EstadoPedido.cancelado;
    if ((esRechazo || esCancelacion) && (motivo?.trim() ?? '').isEmpty) {
      throw const PedidoException('Indica el motivo.');
    }

    final valido = nuevo == actual.estado.siguiente ||
        (esRechazo && actual.estado.esNuevo) ||
        (esCancelacion && actual.estado.enCurso);
    if (!valido) {
      throw const PedidoException(
        'Este pedido ya cambió de estado. Actualiza la lista.',
      );
    }
    final actualizado = actual.copyWith(
      estado: nuevo,
      fechaActualizacion: DateTime.now(),
      motivo: motivo?.trim(),
    );
    _pedidos[pedidoId] = actualizado;
    return actualizado;
  }
}
