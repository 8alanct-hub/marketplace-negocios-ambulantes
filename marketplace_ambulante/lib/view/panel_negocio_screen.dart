import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/router/app_router.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/formato.dart';
import '../model/negocio.dart';
import '../model/pedido.dart';
import '../viewmodel/panel_negocio_state.dart';
import '../viewmodel/panel_negocio_viewmodel.dart';
import '../viewmodel/resultado.dart';
import 'motivo_sheet.dart';
import 'widgets/estado_widgets.dart';
import 'widgets/permisos_widgets.dart';

/// View: "Panel del negocio".
///
/// - Barra inferior: Nuevos / En curso / Historial
/// - Nuevo     → Aceptar o Rechazar (con motivo)
/// - En curso  → En preparación → Listo → Entregado, o Cancelar (con motivo)
/// - Ambulante → botón "Actualizar" ubicación arriba
/// - ⚙          → Configuración de negocio
class PanelNegocioScreen extends ConsumerWidget {
  const PanelNegocioScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(panelNegocioViewModelProvider);

    return async.when(
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Mi negocio')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(
          title: const Text('Mi negocio'),
          actions: const [MenuCuenta()],
        ),
        body: ErrorCarga(
          mensaje: error.toString(),
          onReintentar: () => ref.invalidate(panelNegocioViewModelProvider),
          accionExtra: TextButton(
            onPressed: () => context.go(AppRoutes.tipoNegocio),
            child: const Text('Crear mi negocio'),
          ),
        ),
      ),
      data: (s) => _Panel(estado: s),
    );
  }
}

class _Panel extends ConsumerStatefulWidget {
  const _Panel({required this.estado});

  final PanelNegocioState estado;

  @override
  ConsumerState<_Panel> createState() => _PanelState();
}

class _PanelState extends ConsumerState<_Panel> {
  /// Sección elegida en la barra inferior (0 Nuevos, 1 En curso, 2 Historial).
  /// Es estado de la pantalla, no del negocio: por eso vive en la View.
  int _seccion = 0;

  PanelNegocioViewModel get _vm =>
      ref.read(panelNegocioViewModelProvider.notifier);

  Future<void> _procesar(Resultado r) async {
    if (!mounted) return;
    await procesarResultado(context, r, abrirAjustes: _vm.abrirAjustes);
  }

  Future<void> _rechazar(Pedido p) async {
    final motivo = await pedirMotivo(
      context,
      titulo: '¿Por qué rechazas el pedido #${p.id}?',
      textoBoton: 'Rechazar pedido',
    );
    if (motivo != null) await _procesar(await _vm.rechazar(p, motivo));
  }

  Future<void> _cancelar(Pedido p) async {
    final motivo = await pedirMotivo(
      context,
      titulo: '¿Por qué cancelas el pedido #${p.id}?',
      textoBoton: 'Cancelar pedido',
    );
    if (motivo != null) await _procesar(await _vm.cancelar(p, motivo));
  }

  Widget _lista(List<Pedido> pedidos, String vacio) {
    final estado = widget.estado;
    return RefreshIndicator(
      onRefresh: _vm.recargar,
      child: pedidos.isEmpty
          ? ListView(
              children: [
                EstadoVacio(icono: Icons.receipt_long_outlined, mensaje: vacio),
              ],
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: pedidos.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final p = pedidos[i];
                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: _TarjetaPedido(
                      pedido: p,
                      modalidad: estado.nombreModalidad(p.modalidadPagoId),
                      procesando: estado.pedidoEnProceso == p.id,
                      bloqueado: estado.pedidoEnProceso != null,
                      onAvanzar: () async => _procesar(await _vm.avanzar(p)),
                      onRechazar: () => _rechazar(p),
                      onCancelar: () => _cancelar(p),
                    ),
                  ),
                );
              },
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final estado = widget.estado;
    final negocio = estado.negocio;
    final nuevos = estado.nuevos.length;
    final enCurso = estado.enCurso.length;

    final secciones = [
      _lista(
        estado.nuevos,
        'No tienes pedidos nuevos.\nAquí aparecerán cuando un cliente te '
        'haga un pedido.',
      ),
      _lista(estado.enCurso, 'No tienes pedidos en curso.'),
      _lista(estado.historial, 'Aún no hay pedidos terminados.'),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(negocio.nombre.isEmpty ? 'Mi negocio' : negocio.nombre),
        actions: [
          IconButton(
            tooltip: 'Configurar negocio',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push(AppRoutes.configuracionNegocio),
          ),
          const MenuCuenta(),
        ],
      ),
      body: Column(
        children: [
          if (negocio.tipo == TipoNegocio.ambulante)
            _BannerUbicacion(
              negocio: negocio,
              ubicando: estado.ubicando,
              onActualizar: () async =>
                  _procesar(await _vm.actualizarUbicacion()),
            ),
          // IndexedStack conserva el scroll de cada sección al cambiar.
          Expanded(child: IndexedStack(index: _seccion, children: secciones)),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _seccion,
        onDestinationSelected: (i) => setState(() => _seccion = i),
        destinations: [
          NavigationDestination(
            icon: Badge(
              isLabelVisible: nuevos > 0,
              label: Text('$nuevos'),
              child: const Icon(Icons.notifications_none),
            ),
            selectedIcon: Badge(
              isLabelVisible: nuevos > 0,
              label: Text('$nuevos'),
              child: const Icon(Icons.notifications),
            ),
            label: 'Nuevos',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: enCurso > 0,
              label: Text('$enCurso'),
              backgroundColor: AppColors.grisTexto,
              child: const Icon(Icons.pending_actions_outlined),
            ),
            selectedIcon: Badge(
              isLabelVisible: enCurso > 0,
              label: Text('$enCurso'),
              backgroundColor: AppColors.grisTexto,
              child: const Icon(Icons.pending_actions),
            ),
            label: 'En curso',
          ),
          const NavigationDestination(
            icon: Icon(Icons.history),
            label: 'Historial',
          ),
        ],
      ),
    );
  }
}

/// Recordatorio para ambulantes: mantener la ubicación al día.
class _BannerUbicacion extends StatelessWidget {
  const _BannerUbicacion({
    required this.negocio,
    required this.ubicando,
    required this.onActualizar,
  });

  final Negocio negocio;
  final bool ubicando;
  final VoidCallback onActualizar;

  @override
  Widget build(BuildContext context) {
    final cuando = negocio.ubicacionActualizada;
    return Material(
      color: AppColors.grisFondo,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
        child: Row(
          children: [
            const Icon(Icons.location_on_outlined, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                cuando == null
                    ? 'Los clientes aún no ven dónde estás'
                    : 'Tu ubicación se actualizó ${Formato.haceCuanto(cuando)}',
                style: const TextStyle(fontSize: 13),
              ),
            ),
            TextButton.icon(
              onPressed: ubicando ? null : onActualizar,
              style: TextButton.styleFrom(foregroundColor: AppColors.negro),
              icon: ubicando
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.my_location, size: 18),
              label: const Text('Actualizar'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Texto del botón principal según el estado actual del pedido.
String? _textoAvanzar(EstadoPedido estado) => switch (estado) {
      EstadoPedido.pendiente => 'Aceptar',
      EstadoPedido.aceptado => 'Empezar a preparar',
      EstadoPedido.enPreparacion => 'Marcar como listo',
      EstadoPedido.listo => 'Marcar entregado',
      _ => null,
    };

class _TarjetaPedido extends StatelessWidget {
  const _TarjetaPedido({
    required this.pedido,
    required this.modalidad,
    required this.procesando,
    required this.bloqueado,
    required this.onAvanzar,
    required this.onRechazar,
    required this.onCancelar,
  });

  final Pedido pedido;
  final String modalidad;
  final bool procesando;

  /// Otro pedido se está actualizando: botones deshabilitados.
  final bool bloqueado;
  final VoidCallback onAvanzar;
  final VoidCallback onRechazar;
  final VoidCallback onCancelar;

  @override
  Widget build(BuildContext context) {
    final textoAvanzar = _textoAvanzar(pedido.estado);
    final esNuevo = pedido.estado.esNuevo;

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
                  'Pedido #${pedido.id}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              _ChipEstado(estado: pedido.estado),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            '${pedido.clienteNombre} · '
            '${Formato.haceCuanto(pedido.fechaCreacion)}',
            style: const TextStyle(fontSize: 12, color: AppColors.grisTexto),
          ),
          const SizedBox(height: 12),
          for (final d in pedido.detalles)
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
                Formato.precio(pedido.total),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Pago: $modalidad',
            style: const TextStyle(fontSize: 12, color: AppColors.grisTexto),
          ),
          if (pedido.motivo != null) ...[
            const SizedBox(height: 4),
            Text(
              'Motivo: ${pedido.motivo}',
              style: const TextStyle(fontSize: 12, color: AppColors.error),
            ),
          ],
          if (textoAvanzar != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                // Nuevo → "Rechazar"; en curso → "Cancelar". Ambos piden motivo.
                Expanded(
                  child: OutlinedButton(
                    onPressed:
                        bloqueado ? null : (esNuevo ? onRechazar : onCancelar),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      minimumSize: const Size.fromHeight(44),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      )
                    ),
                    child: Text(esNuevo ? 'Rechazar' : 'Cancelar'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    onPressed: bloqueado ? null : onAvanzar,
                    child: procesando
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.grisTexto,
                            ),
                          )
                        : Text(textoAvanzar),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ChipEstado extends StatelessWidget {
  const _ChipEstado({required this.estado});
  final EstadoPedido estado;

  @override
  Widget build(BuildContext context) {
    // Colores con significado: amarillo = espera, azul = en curso,
    // verde = listo/entregado, rojo = rechazado/cancelado.
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
