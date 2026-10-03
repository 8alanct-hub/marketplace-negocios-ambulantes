import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/router/app_router.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/formato.dart';
import '../model/pedido.dart';
import '../viewmodel/mis_pedidos_viewmodel.dart';
import '../viewmodel/resultado.dart';
import 'widgets/auth_widgets.dart';
import 'widgets/estado_widgets.dart';
import 'widgets/pedido_widgets.dart';

/// View: "Mis pedidos" (usuario).
///
/// - Estado de cada pedido
/// - "Chat" → Chat con el negocio
/// - "Cancelar pedido" solo mientras está pendiente
class MisPedidosScreen extends ConsumerWidget {
  const MisPedidosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(misPedidosViewModelProvider);
    final vm = ref.read(misPedidosViewModelProvider.notifier);

    Future<void> cancelar(Pedido p) async {
      final confirmar = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('¿Cancelar el pedido #${p.id}?'),
          content: Text('${p.negocioNombre} ya no lo preparará.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('No'),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: AppColors.error),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Sí, cancelar'),
            ),
          ],
        ),
      );
      if (confirmar != true) return;
      final r = await vm.cancelar(p);
      if (r is Fallo && context.mounted) mostrarMensaje(context, r.mensaje);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Mis pedidos')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorCarga(
          mensaje: error.toString(),
          onReintentar: () => ref.invalidate(misPedidosViewModelProvider),
        ),
        data: (s) => RefreshIndicator(
          onRefresh: vm.recargar,
          child: s.pedidos.isEmpty
              ? ListView(
                  children: const [
                    EstadoVacio(
                      icono: Icons.receipt_long_outlined,
                      mensaje: 'Aún no has hecho pedidos.\nEntra a un negocio '
                          'desde Inicio y elige tus productos.',
                    ),
                  ],
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: s.pedidos.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final p = s.pedidos[i];
                    return Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 600),
                        child: _TarjetaMiPedido(
                          pedido: p,
                          modalidad: s.nombreModalidad(p.modalidadPagoId),
                          procesando: s.pedidoEnProceso == p.id,
                          onChat: () => context
                              .push(AppRoutes.chatConNegocio(p.negocioId)),
                          onCancelar: () => cancelar(p),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }
}

class _TarjetaMiPedido extends StatelessWidget {
  const _TarjetaMiPedido({
    required this.pedido,
    required this.modalidad,
    required this.procesando,
    required this.onChat,
    required this.onCancelar,
  });

  final Pedido pedido;
  final String modalidad;
  final bool procesando;
  final VoidCallback onChat;
  final VoidCallback onCancelar;

  @override
  Widget build(BuildContext context) {
    final p = pedido;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.grisBorde),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  p.negocioNombre,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              ChipEstado(estado: p.estado),
            ],
          ),
          Text(
            'Pedido #${p.id} · ${Formato.haceCuanto(p.fechaCreacion)}',
            style: const TextStyle(fontSize: 12, color: AppColors.grisTexto),
          ),
          const SizedBox(height: 8),
          for (final d in p.detalles)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Expanded(child: Text('${d.cantidad} × ${d.nombreProducto}')),
                  Text(Formato.precio(d.subtotal)),
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
                Formato.precio(p.total),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          Text(
            'Forma de recibir: $modalidad',
            style: const TextStyle(fontSize: 12, color: AppColors.grisTexto),
          ),
          if (p.motivo != null)
            Text(
              'Motivo: ${p.motivo}',
              style: const TextStyle(fontSize: 12, color: AppColors.error),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onChat,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.negro,
                  ),
                  icon: const Icon(Icons.chat_bubble_outline, size: 18),
                  label: const Text('Chat'),
                ),
              ),
              if (p.estado.esNuevo) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: TextButton(
                    onPressed: procesando ? null : onCancelar,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.error,
                    ),
                    child: procesando
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Cancelar pedido'),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
