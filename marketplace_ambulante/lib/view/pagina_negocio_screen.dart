import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/router/app_router.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/distancia.dart';
import '../core/utils/formato.dart';
import '../model/negocio.dart';
import '../model/producto.dart';
import '../viewmodel/carrito_viewmodel.dart';
import '../viewmodel/pagina_negocio_viewmodel.dart';
import 'widgets/estado_widgets.dart';
import 'widgets/permisos_widgets.dart';
import 'widgets/seleccion_widgets.dart';

/// View: "Página del negocio" vista por el usuario.
///
/// - Productos con − / + para elegir cantidades
/// - "Chat con el negocio" → Chat
/// - "Hacer pedido" (abajo) → Forma de recibir el pedido
class PaginaNegocioScreen extends ConsumerWidget {
  const PaginaNegocioScreen({super.key, required this.negocioId});

  final String negocioId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(paginaNegocioProvider(negocioId));
    final carrito = ref.watch(carritoProvider);

    return Scaffold(
      body: async.when(
        loading: () => Scaffold(
          appBar: AppBar(),
          body: const Center(child: CircularProgressIndicator()),
        ),
        error: (error, _) => Scaffold(
          appBar: AppBar(),
          body: ErrorCarga(
            mensaje: error.toString(),
            onReintentar: () =>
                ref.invalidate(paginaNegocioProvider(negocioId)),
          ),
        ),
        data: (datos) => _Contenido(datos: datos),
      ),
      bottomNavigationBar: carrito.esDe(negocioId)
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Center(
                  heightFactor: 1,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: FilledButton(
                      onPressed: () =>
                          context.push(AppRoutes.confirmarPedido(negocioId)),
                      child: Text(
                        'Hacer pedido · ${carrito.cantidadTotal} '
                        '${carrito.cantidadTotal == 1 ? 'producto' : 'productos'}'
                        ' · ${Formato.precio(carrito.total)}',
                      ),
                    ),
                  ),
                ),
              ),
            )
          : null,
    );
  }
}

class _Contenido extends ConsumerWidget {
  const _Contenido({required this.datos});

  final PaginaNegocioDatos datos;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final n = datos.negocio;
    final esFijo = n.tipo == TipoNegocio.fijo;
    final carrito = ref.watch(carritoProvider);
    final vm = ref.read(carritoProvider.notifier);

    Future<void> agregar(Producto p) async {
      // Un pedido es de un solo negocio: avisar antes de vaciar el otro.
      if (carrito.esDeOtroNegocio(n.id)) {
        final empezar = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('¿Empezar un pedido nuevo?'),
            content: const Text(
              'Tienes productos de otro negocio en tu pedido. Si agregas '
              'este, se quitarán.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Empezar nuevo'),
              ),
            ],
          ),
        );
        if (empezar != true) return;
      }
      vm.agregar(p);
    }

    final datosUbicacion = [
      if (datos.distanciaMetros != null) Distancia.texto(datos.distanciaMetros!),
      if (esFijo && n.direccion.isNotEmpty) n.direccion,
      if (!esFijo && n.ubicacionActualizada != null)
        'ubicación actualizada ${Formato.haceCuanto(n.ubicacionActualizada!)}',
    ].join(' · ');

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          expandedHeight: 200,
          title: Text(n.nombre),
          flexibleSpace: FlexibleSpaceBar(
            background: n.bannerUrl != null
                ? ImagenDesdeUrl(url: n.bannerUrl!)
                : ColoredBox(
                    color: AppColors.grisFondo,
                    child: Center(
                      child: esFijo
                          ? const Icon(
                              Icons.storefront_outlined,
                              size: 56,
                              color: AppColors.grisTexto,
                            )
                          : const IconoAsset(
                              IconosApp.carritoAmbulante,
                              size: 56,
                            ),
                    ),
                  ),
          ),
        ),
        SliverToBoxAdapter(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      esFijo ? 'LOCAL FIJO' : 'AMBULANTE',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                        color: AppColors.grisTexto,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      n.nombre,
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    if (n.descripcion.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(n.descripcion),
                    ],
                    if (datosUbicacion.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.location_on_outlined, size: 18),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              datosUbicacion,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.grisTexto,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final m in datos.modalidades)
                          Chip(
                            avatar: const Icon(Icons.payments_outlined, size: 16),
                            label: Text(m.nombre),
                            visualDensity: VisualDensity.compact,
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () =>
                          context.push(AppRoutes.chatConNegocio(n.id)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.negro,
                        minimumSize: const Size.fromHeight(44),
                      ),
                      icon: const Icon(Icons.chat_bubble_outline, size: 18),
                      label: const Text('Chat con el negocio'),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Productos del negocio',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (datos.productos.isEmpty)
                      const EstadoVacio(
                        icono: Icons.inventory_2_outlined,
                        mensaje: 'Este negocio todavía no tiene productos.',
                      )
                    else
                      for (final p in datos.productos)
                        _FilaProducto(
                          producto: p,
                          categoria: datos.nombresCategoria[p.categoriaId],
                          cantidad: carrito.negocioId == n.id
                              ? carrito.cantidadDe(p.id)
                              : 0,
                          onAgregar: () => agregar(p),
                          onQuitar: () => vm.quitar(p),
                        ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _FilaProducto extends StatelessWidget {
  const _FilaProducto({
    required this.producto,
    required this.categoria,
    required this.cantidad,
    required this.onAgregar,
    required this.onQuitar,
  });

  final Producto producto;
  final String? categoria;
  final int cantidad;
  final VoidCallback onAgregar;
  final VoidCallback onQuitar;

  @override
  Widget build(BuildContext context) {
    final p = producto;
    final Widget accion;
    if (!p.sePuedePedir) {
      accion = Text(
        p.agotado ? 'Agotado' : 'No disponible',
        style: const TextStyle(fontSize: 12, color: AppColors.error),
      );
    } else if (cantidad == 0) {
      accion = OutlinedButton(
        onPressed: onAgregar,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.negro,
          visualDensity: VisualDensity.compact,
        ),
        child: const Text('Agregar'),
      );
    } else {
      accion = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'Quitar uno',
            onPressed: onQuitar,
            icon: const Icon(Icons.remove_circle_outline),
          ),
          Text(
            '$cantidad',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          IconButton(
            tooltip: 'Agregar uno',
            // No deja pedir más de lo que hay.
            onPressed: cantidad >= p.stock ? null : onAgregar,
            icon: const Icon(Icons.add_circle_outline),
          ),
        ],
      );
    }

    return Opacity(
      opacity: p.sePuedePedir ? 1 : 0.55,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 64,
                height: 64,
                child: p.imagenUrl != null
                    ? ImagenDesdeUrl(url: p.imagenUrl!)
                    : const ColoredBox(
                        color: AppColors.grisFondo,
                        child: Icon(
                          Icons.image_outlined,
                          color: AppColors.grisTexto,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.nombre,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  if (p.descripcion.isNotEmpty)
                    Text(
                      p.descripcion,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.grisTexto,
                      ),
                    ),
                  const SizedBox(height: 2),
                  Text(
                    '${Formato.precio(p.precio)}'
                    '${categoria != null ? ' · $categoria' : ''}',
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ),
            accion,
          ],
        ),
      ),
    );
  }
}
