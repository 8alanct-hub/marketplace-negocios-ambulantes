import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/constants/app_constants.dart';
import '../core/router/app_router.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/distancia.dart';
import '../core/utils/formato.dart';
import '../model/negocio.dart';
import '../viewmodel/marketplace_state.dart';
import '../viewmodel/marketplace_viewmodel.dart';
import 'widgets/estado_widgets.dart';
import 'widgets/permisos_widgets.dart';
import 'widgets/seleccion_widgets.dart';

/// View: "Marketplace" del usuario.
///
/// - Buscador por nombre o descripción
/// - Negocios ordenados por cercanía (si hay ubicación)
/// - "Ver" → Página del negocio
class MarketplaceScreen extends ConsumerWidget {
  const MarketplaceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(marketplaceViewModelProvider);

    return Scaffold(
      appBar: AppBar(title: const Text(AppConstants.nombreApp)),
      body: async.when(
        loading: () => const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 12),
              Text(
                'Buscando negocios cerca de ti…',
                style: TextStyle(color: AppColors.grisTexto),
              ),
            ],
          ),
        ),
        error: (error, _) => ErrorCarga(
          mensaje: 'No pudimos cargar los negocios.',
          onReintentar: () => ref.invalidate(marketplaceViewModelProvider),
        ),
        data: (s) => _Contenido(estado: s),
      ),
    );
  }
}

class _Contenido extends ConsumerWidget {
  const _Contenido({required this.estado});

  final MarketplaceState estado;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vm = ref.read(marketplaceViewModelProvider.notifier);
    final visibles = estado.visibles;

    return RefreshIndicator(
      onRefresh: vm.recargar,
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            sliver: SliverToBoxAdapter(
              child: TextField(
                onChanged: vm.buscar,
                textInputAction: TextInputAction.search,
                decoration: const InputDecoration(
                  hintText: 'Buscar negocios',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
            ),
          ),
          if (estado.avisoUbicacion != null)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              sliver: SliverToBoxAdapter(
                child: _AvisoUbicacion(
                  mensaje: estado.avisoUbicacion!,
                  ubicando: estado.ubicando,
                  onActivar: () async {
                    final r = await vm.reintentarUbicacion();
                    if (!context.mounted) return;
                    await procesarResultado(
                      context,
                      r,
                      abrirAjustes: vm.abrirAjustes,
                    );
                  },
                ),
              ),
            ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
            sliver: SliverToBoxAdapter(
              child: Text(
                estado.conUbicacion ? 'Negocios más cercanos' : 'Negocios',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          if (visibles.isEmpty)
            SliverToBoxAdapter(
              child: EstadoVacio(
                icono: Icons.storefront_outlined,
                mensaje: estado.busqueda.isEmpty
                    ? 'Todavía no hay negocios publicados.'
                    : 'No encontramos negocios con "${estado.busqueda}".',
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              sliver: SliverGrid.builder(
                // 2 columnas en el celular; más en pantallas anchas.
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 240,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.72,
                ),
                itemCount: visibles.length,
                itemBuilder: (context, i) => _TarjetaNegocio(
                  cercano: visibles[i],
                  onVer: () => context
                      .push(AppRoutes.paginaNegocio(visibles[i].negocio.id)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AvisoUbicacion extends StatelessWidget {
  const _AvisoUbicacion({
    required this.mensaje,
    required this.ubicando,
    required this.onActivar,
  });

  final String mensaje;
  final bool ubicando;
  final VoidCallback onActivar;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
      decoration: BoxDecoration(
        color: AppColors.grisFondo,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.location_off_outlined),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$mensaje\nSin tu ubicación no podemos ordenar por cercanía.',
              style: const TextStyle(fontSize: 12),
            ),
          ),
          TextButton(
            onPressed: ubicando ? null : onActivar,
            style: TextButton.styleFrom(foregroundColor: AppColors.negro),
            child: ubicando
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Activar'),
          ),
        ],
      ),
    );
  }
}

class _TarjetaNegocio extends StatelessWidget {
  const _TarjetaNegocio({required this.cercano, required this.onVer});

  final NegocioCercano cercano;
  final VoidCallback onVer;

  @override
  Widget build(BuildContext context) {
    final n = cercano.negocio;
    final esAmbulante = n.tipo == TipoNegocio.ambulante;

    // Ej: "a 350 m · ubicación hace 15 min"
    final datos = [
      if (cercano.distanciaMetros != null)
        Distancia.texto(cercano.distanciaMetros!),
      if (esAmbulante && n.ubicacionActualizada != null)
        'ubicación ${Formato.haceCuanto(n.ubicacionActualizada!)}',
    ].join(' · ');

    return InkWell(
      onTap: onVer,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: double.infinity,
                // En la lista se muestra el LOGO (perfil) del negocio.
                // La portada (banner) se ve al entrar a su página.
                child: n.logoUrl != null
                    ? ImagenDesdeUrl(url: n.logoUrl!)
                    : ColoredBox(
                        color: AppColors.grisFondo,
                        child: Center(
                          child: esAmbulante
                              ? const IconoAsset(
                                  IconosApp.carritoAmbulante,
                                  size: 40,
                                )
                              : const Icon(
                                  Icons.storefront_outlined,
                                  size: 40,
                                  color: AppColors.grisTexto,
                                ),
                        ),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            esAmbulante ? 'Ambulante' : 'Local fijo',
            style: const TextStyle(fontSize: 11, color: AppColors.grisTexto),
          ),
          Text(
            n.nombre,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          if (datos.isNotEmpty)
            Text(
              datos,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: AppColors.grisTexto),
            ),
          const SizedBox(height: 2),
          const Row(
            children: [
              Text('Ver', style: TextStyle(fontWeight: FontWeight.w600)),
              Icon(Icons.chevron_right, size: 18),
            ],
          ),
        ],
      ),
    );
  }
}
