import 'package:flutter/material.dart';

import '../../model/pedido.dart';

/// Etiqueta de color con el estado del pedido.
/// Amarillo = espera, azul = en curso, verde = listo/entregado,
/// rojo = rechazado/cancelado.
class ChipEstado extends StatelessWidget {
  const ChipEstado({super.key, required this.estado});

  final EstadoPedido estado;

  @override
  Widget build(BuildContext context) {
    final (fondo, texto) = switch (estado) {
      EstadoPedido.pendiente => (
          const Color(0xFFFFF4D6),
          const Color(0xFF8A6100),
        ),
      EstadoPedido.aceptado || EstadoPedido.enPreparacion => (
          const Color(0xFFE3EEFF),
          const Color(0xFF1D4E9E),
        ),
      EstadoPedido.listo || EstadoPedido.entregado => (
          const Color(0xFFE3F5E8),
          const Color(0xFF1E6B37),
        ),
      EstadoPedido.rechazado || EstadoPedido.cancelado => (
          const Color(0xFFFDE7E7),
          const Color(0xFFA32020),
        ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: fondo,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        estado.etiqueta,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: texto,
        ),
      ),
    );
  }
}
