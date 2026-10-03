import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../model/negocio.dart';
import '../model/pedido.dart';
import '../model/pedido_repository.dart';
import '../model/repository_providers.dart';
import 'carrito_viewmodel.dart';
import 'estado_formulario.dart';
import 'mis_pedidos_viewmodel.dart';
import 'seleccion_rol_viewmodel.dart' show errorSinSesion;
import 'sesion_viewmodel.dart';

/// ViewModel de "Forma de recibir el pedido": crea el pedido.
class ConfirmarPedidoViewModel extends Notifier<EstadoFormulario> {
  @override
  EstadoFormulario build() => const EstadoFormulario();

  /// Crea el pedido con lo que hay en el carrito. Devuelve el pedido creado,
  /// o null si falló (el mensaje queda en [EstadoFormulario.error]).
  Future<Pedido?> confirmar({
    required Negocio negocio,
    required String modalidadPagoId,
  }) async {
    if (state.cargando) return null;
    final sesion = ref.read(sesionProvider);
    if (sesion == null) {
      state = const EstadoFormulario(error: errorSinSesion);
      return null;
    }
    final carrito = ref.read(carritoProvider);
    if (!carrito.esDe(negocio.id)) {
      state = const EstadoFormulario(error: 'Tu pedido está vacío.');
      return null;
    }

    state = const EstadoFormulario(cargando: true);
    try {
      final pedido = await ref.read(pedidoRepositoryProvider).crearPedido(
            usuarioId: sesion.id,
            clienteNombre: sesion.nombreCompleto,
            negocioId: negocio.id,
            negocioNombre: negocio.nombre,
            modalidadPagoId: modalidadPagoId,
            detalles: [
              for (final item in carrito.items.values)
                DetallePedido(
                  productoId: item.producto.id,
                  nombreProducto: item.producto.nombre,
                  cantidad: item.cantidad,
                  precioUnitario: item.producto.precio,
                ),
            ],
          );
      ref.read(carritoProvider.notifier).vaciar();
      // "Mis pedidos" debe mostrar el nuevo.
      ref.invalidate(misPedidosViewModelProvider);
      state = const EstadoFormulario();
      return pedido;
    } on PedidoException catch (e) {
      state = EstadoFormulario(error: e.mensaje);
    } catch (_) {
      state = const EstadoFormulario(error: errorGenerico);
    }
    return null;
  }

  void limpiarError() {
    if (state.error != null) state = const EstadoFormulario();
  }
}

final confirmarPedidoViewModelProvider =
    NotifierProvider<ConfirmarPedidoViewModel, EstadoFormulario>(
  ConfirmarPedidoViewModel.new,
);
