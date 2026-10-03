import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../model/producto.dart';

class ItemCarrito {
  const ItemCarrito(this.producto, this.cantidad);

  final Producto producto;
  final int cantidad;

  double get subtotal => producto.precio * cantidad;
}

/// Productos elegidos antes de hacer el pedido.
/// Un pedido es de UN solo negocio: el carrito guarda de cuál es.
class Carrito {
  const Carrito({this.negocioId, this.items = const {}});

  final String? negocioId;

  /// productoId → item
  final Map<String, ItemCarrito> items;

  bool get vacio => items.isEmpty;

  int get cantidadTotal => items.values.fold(0, (s, i) => s + i.cantidad);

  double get total => items.values.fold(0, (s, i) => s + i.subtotal);

  int cantidadDe(String productoId) => items[productoId]?.cantidad ?? 0;

  /// true si el carrito tiene productos de ese negocio.
  bool esDe(String negocioId) => !vacio && this.negocioId == negocioId;

  /// true si agregar algo de [negocioId] vaciaría lo que ya hay.
  bool esDeOtroNegocio(String negocioId) =>
      !vacio && this.negocioId != negocioId;
}

/// ViewModel del carrito (lo comparten la página del negocio y
/// "Forma de recibir el pedido").
class CarritoViewModel extends Notifier<Carrito> {
  @override
  Carrito build() => const Carrito();

  /// Suma 1. Si el carrito era de otro negocio, empieza uno nuevo.
  /// No pasa del stock ni agrega productos que no se pueden pedir.
  void agregar(Producto producto) {
    if (!producto.sePuedePedir) return;
    final base = state.negocioId == producto.negocioId
        ? state.items
        : const <String, ItemCarrito>{};
    final actual = base[producto.id]?.cantidad ?? 0;
    if (actual >= producto.stock) return;
    state = Carrito(
      negocioId: producto.negocioId,
      items: {...base, producto.id: ItemCarrito(producto, actual + 1)},
    );
  }

  /// Resta 1 (y lo quita si llega a 0).
  void quitar(Producto producto) {
    final actual = state.cantidadDe(producto.id);
    if (actual == 0) return;
    final items = {...state.items};
    if (actual == 1) {
      items.remove(producto.id);
    } else {
      items[producto.id] = ItemCarrito(producto, actual - 1);
    }
    state = Carrito(
      negocioId: items.isEmpty ? null : state.negocioId,
      items: items,
    );
  }

  void vaciar() => state = const Carrito();
}

final carritoProvider =
    NotifierProvider<CarritoViewModel, Carrito>(CarritoViewModel.new);
