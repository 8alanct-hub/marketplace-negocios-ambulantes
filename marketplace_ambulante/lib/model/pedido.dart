/// Estados de un pedido (columna `estado` de `pedidos`).
///
/// Flujo normal:  pendiente → aceptado → enPreparacion → listo → entregado
/// Desvíos (siempre con motivo):
///                pendiente → rechazado  (el negocio no lo acepta)
///                en curso  → cancelado  (el negocio lo cancela después)
enum EstadoPedido {
  pendiente,
  aceptado,
  enPreparacion,
  listo,
  entregado,
  rechazado,
  cancelado,
}

extension EstadoPedidoInfo on EstadoPedido {
  String get etiqueta => switch (this) {
        EstadoPedido.pendiente => 'Pendiente',
        EstadoPedido.aceptado => 'Aceptado',
        EstadoPedido.enPreparacion => 'En preparación',
        EstadoPedido.listo => 'Listo para entregar',
        EstadoPedido.entregado => 'Entregado',
        EstadoPedido.rechazado => 'Rechazado',
        EstadoPedido.cancelado => 'Cancelado',
      };

  /// Estado al que pasa cuando el negocio lo avanza (null = ya no avanza).
  EstadoPedido? get siguiente => switch (this) {
        EstadoPedido.pendiente => EstadoPedido.aceptado,
        EstadoPedido.aceptado => EstadoPedido.enPreparacion,
        EstadoPedido.enPreparacion => EstadoPedido.listo,
        EstadoPedido.listo => EstadoPedido.entregado,
        _ => null,
      };

  bool get esNuevo => this == EstadoPedido.pendiente;

  bool get enCurso =>
      this == EstadoPedido.aceptado ||
      this == EstadoPedido.enPreparacion ||
      this == EstadoPedido.listo;

  bool get terminado => !esNuevo && !enCurso;
}

/// Motivos sugeridos para rechazar o cancelar un pedido.
/// La View agrega la opción "Otro" para escribir uno propio.
const motivosCancelacion = <String>[
  'Producto o servicio agotado',
  'No puedo atenderlo en este momento',
  'El cliente no responde',
  'Problema con la entrega o el pago',
];

/// Tabla `detalle_pedido`.
class DetallePedido {
  const DetallePedido({
    required this.productoId,
    required this.nombreProducto,
    required this.cantidad,
    required this.precioUnitario,
  });

  final String productoId;

  /// Nombre del producto al momento del pedido (para mostrarlo aunque
  /// después el negocio lo cambie).
  final String nombreProducto;
  final int cantidad;
  final double precioUnitario;

  double get subtotal => cantidad * precioUnitario;
}

/// Tabla `pedidos`.
class Pedido {
  const Pedido({
    required this.id,
    required this.usuarioId,
    required this.clienteNombre,
    required this.negocioId,
    required this.negocioNombre,
    required this.modalidadPagoId,
    required this.estado,
    required this.detalles,
    required this.fechaCreacion,
    required this.fechaActualizacion,
    this.motivo,
  });

  final String id;
  final String usuarioId;

  /// Nombre del cliente (en el backend real vendría unido desde `usuarios`).
  final String clienteNombre;
  final String negocioId;

  /// Nombre del negocio (en el backend real vendría unido desde `negocios`).
  final String negocioNombre;
  final String modalidadPagoId;
  final EstadoPedido estado;
  final List<DetallePedido> detalles;
  final DateTime fechaCreacion;
  final DateTime fechaActualizacion;

  /// Por qué se rechazó o canceló (null en los demás estados).
  /// Sugerencia: agregar la columna `motivo_cancelacion` a `pedidos`.
  final String? motivo;

  double get total => detalles.fold(0, (suma, d) => suma + d.subtotal);

  Pedido copyWith({
    EstadoPedido? estado,
    DateTime? fechaActualizacion,
    String? motivo,
  }) =>
      Pedido(
        id: id,
        usuarioId: usuarioId,
        clienteNombre: clienteNombre,
        negocioId: negocioId,
        negocioNombre: negocioNombre,
        modalidadPagoId: modalidadPagoId,
        estado: estado ?? this.estado,
        detalles: detalles,
        fechaCreacion: fechaCreacion,
        fechaActualizacion: fechaActualizacion ?? this.fechaActualizacion,
        motivo: motivo ?? this.motivo,
      );
}
