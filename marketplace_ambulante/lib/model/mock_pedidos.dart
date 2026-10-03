import 'pedido.dart';

/// Pedidos de prueba para "Nouveau Beauty Salon" (n_1).
/// Las fechas son relativas a [ahora] para que siempre se vean recientes.
List<Pedido> crearMockPedidos(DateTime ahora) {
  Pedido pedido(
    String id,
    String cliente,
    EstadoPedido estado,
    Duration hace,
    List<DetallePedido> detalles, {
    String usuarioId = 'u_1',
    String modalidad = 'm_1',
    String? motivo,
  }) {
    final fecha = ahora.subtract(hace);
    return Pedido(
      id: id,
      usuarioId: usuarioId,
      clienteNombre: cliente,
      negocioId: 'n_1',
      negocioNombre: 'Nouveau Beauty Salon',
      modalidadPagoId: modalidad,
      estado: estado,
      detalles: detalles,
      fechaCreacion: fecha,
      fechaActualizacion: fecha,
      motivo: motivo,
    );
  }

  const manicure = DetallePedido(
    productoId: 'p_1',
    nombreProducto: 'Manicure tradicional',
    cantidad: 1,
    precioUnitario: 25000,
  );
  const pedicure = DetallePedido(
    productoId: 'p_2',
    nombreProducto: 'Pedicure spa',
    cantidad: 1,
    precioUnitario: 35000,
  );

  return [
    pedido('1001', 'Carla Gómez', EstadoPedido.pendiente,
        const Duration(minutes: 5), [manicure]),
    pedido('1002', 'Laura Díaz', EstadoPedido.pendiente,
        const Duration(minutes: 20), [pedicure, manicure],
        usuarioId: 'u_7', modalidad: 'm_2'),
    pedido('1003', 'Marta Ríos', EstadoPedido.aceptado,
        const Duration(hours: 1), [pedicure], usuarioId: 'u_8'),
    pedido('1004', 'Carla Gómez', EstadoPedido.listo,
        const Duration(hours: 2), [manicure]),
    pedido(
      '1005',
      'Sofía León',
      EstadoPedido.entregado,
      const Duration(days: 1),
      [
        const DetallePedido(
          productoId: 'p_1',
          nombreProducto: 'Manicure tradicional',
          cantidad: 2,
          precioUnitario: 25000,
        ),
      ],
      usuarioId: 'u_9',
    ),
    pedido('1006', 'Pedro Gil', EstadoPedido.rechazado,
        const Duration(days: 2), [pedicure],
        usuarioId: 'u_10', motivo: 'No puedo atenderlo en este momento'),
  ];
}
