import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/router/app_router.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/formato.dart';
import '../model/modalidad_pago.dart';
import '../viewmodel/carrito_viewmodel.dart';
import '../viewmodel/confirmar_pedido_viewmodel.dart';
import '../viewmodel/estado_formulario.dart';
import '../viewmodel/pagina_negocio_viewmodel.dart';
import 'widgets/auth_widgets.dart';
import 'widgets/estado_widgets.dart';

/// View: "Forma de recibir el pedido".
///
/// - Resumen del pedido
/// - Elegir: Pago en el negocio / Contraentrega (las que acepte el negocio)
/// - "Confirmar pedido" → Mis pedidos
class ConfirmarPedidoScreen extends ConsumerStatefulWidget {
  const ConfirmarPedidoScreen({super.key, required this.negocioId});

  final String negocioId;

  @override
  ConsumerState<ConfirmarPedidoScreen> createState() =>
      _ConfirmarPedidoScreenState();
}

class _ConfirmarPedidoScreenState extends ConsumerState<ConfirmarPedidoScreen> {
  /// Forma elegida (estado de la pantalla, por eso vive en la View).
  String? _modalidadId;

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(paginaNegocioProvider(widget.negocioId));
    final carrito = ref.watch(carritoProvider);
    final estado = ref.watch(confirmarPedidoViewModelProvider);

    ref.listen<EstadoFormulario>(confirmarPedidoViewModelProvider, (a, b) {
      if (b.error != null && b.error != a?.error) {
        mostrarMensaje(context, b.error!);
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Forma de recibir el pedido')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorCarga(
          mensaje: error.toString(),
          onReintentar: () =>
              ref.invalidate(paginaNegocioProvider(widget.negocioId)),
        ),
        data: (datos) {
          if (!carrito.esDe(widget.negocioId)) {
            return const EstadoVacio(
              icono: Icons.shopping_basket_outlined,
              mensaje: 'Tu pedido está vacío. Vuelve y agrega productos.',
            );
          }
          // Si el negocio acepta una sola forma, queda elegida.
          final elegida = _modalidadId ??
              (datos.modalidades.length == 1
                  ? datos.modalidades.first.id
                  : null);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _Resumen(negocio: datos.negocio.nombre, carrito: carrito),
                      const SizedBox(height: 24),
                      const Text(
                        '¿Cómo quieres recibirlo?',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      for (final m in datos.modalidades)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _OpcionModalidad(
                            modalidad: m,
                            elegida: elegida == m.id,
                            detalle: _detalle(m, datos),
                            onTap: estado.cargando
                                ? null
                                : () => setState(() => _modalidadId = m.id),
                          ),
                        ),
                      const SizedBox(height: 4),
                      const Text(
                        'La app no procesa pagos ni hace domicilios: le pagas '
                        'directamente al negocio y cualquier entrega se '
                        'coordina por el chat.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.grisTexto,
                        ),
                      ),
                      const SizedBox(height: 24),
                      BotonPrincipal(
                        texto: 'Confirmar pedido',
                        cargando: estado.cargando,
                        onPressed: () => _confirmar(datos, elegida),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Para "Pago en el negocio" de un local fijo, muestra la dirección.
  String? _detalle(ModalidadPago m, PaginaNegocioDatos datos) {
    final direccion = datos.negocio.direccion;
    if (m.nombre == 'Pago en el negocio' && direccion.isNotEmpty) {
      return 'Dirección: $direccion';
    }
    return null;
  }

  Future<void> _confirmar(PaginaNegocioDatos datos, String? modalidadId) async {
    if (modalidadId == null) {
      mostrarMensaje(context, 'Elige cómo quieres recibir tu pedido.');
      return;
    }
    final pedido = await ref
        .read(confirmarPedidoViewModelProvider.notifier)
        .confirmar(negocio: datos.negocio, modalidadPagoId: modalidadId);
    if (pedido == null || !mounted) return;
    mostrarMensaje(
      context,
      'Pedido #${pedido.id} enviado a ${datos.negocio.nombre}. '
      'Te avisaremos cuando responda.',
    );
    // A "Mis pedidos" (reemplaza la pila: no se vuelve a esta pantalla).
    context.go(AppRoutes.misPedidos);
  }
}

class _Resumen extends StatelessWidget {
  const _Resumen({required this.negocio, required this.carrito});

  final String negocio;
  final Carrito carrito;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.grisBorde),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Tu pedido en $negocio',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          for (final item in carrito.items.values)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text('${item.cantidad} × ${item.producto.nombre}'),
                  ),
                  Text(Formato.precio(item.subtotal)),
                ],
              ),
            ),
          const Divider(height: 16),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Total',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              Text(
                Formato.precio(carrito.total),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OpcionModalidad extends StatelessWidget {
  const _OpcionModalidad({
    required this.modalidad,
    required this.elegida,
    required this.detalle,
    required this.onTap,
  });

  final ModalidadPago modalidad;
  final bool elegida;
  final String? detalle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final esContraentrega = modalidad.nombre == 'Contraentrega';
    return Material(
      color: elegida ? AppColors.grisFondo : AppColors.blanco,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: elegida ? AppColors.negro : AppColors.grisBorde,
          width: elegida ? 1.5 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Contraentrega = pagas al recibir lo que acordaste por el chat.
              // (Sin moto: la app no tiene domicilios propios.)
              Icon(
                esContraentrega
                    ? Icons.handshake_outlined
                    : Icons.storefront_outlined,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      modalidad.nombre,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      modalidad.descripcion,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.grisTexto,
                      ),
                    ),
                    if (detalle != null)
                      Text(detalle!, style: const TextStyle(fontSize: 12)),
                  ],
                ),
              ),
              Icon(
                elegida ? Icons.check_circle : Icons.radio_button_unchecked,
                color: elegida ? AppColors.negro : AppColors.grisTexto,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
