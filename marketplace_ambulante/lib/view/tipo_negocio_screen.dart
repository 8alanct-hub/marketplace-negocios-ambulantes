import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/router/app_router.dart';
import '../model/negocio.dart';
import '../viewmodel/estado_formulario.dart';
import '../viewmodel/tipo_negocio_viewmodel.dart';
import 'widgets/auth_widgets.dart';
import 'widgets/seleccion_widgets.dart';

/// View: "¿Qué tipo de negocio?".
///
/// - Ambulante / Fijo → crea el negocio, guarda el rol → Configuración de negocio
/// - Volver           → ¿Eres un?
class TipoNegocioScreen extends ConsumerWidget {
  const TipoNegocioScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(tipoNegocioViewModelProvider);

    ref.listen<EstadoFormulario>(tipoNegocioViewModelProvider, (prev, next) {
      if (next.error != null && next.error != prev?.error) {
        mostrarMensaje(context, next.error!);
      }
    });

    Future<void> elegir(TipoNegocio tipo) async {
      final ok =
          await ref.read(tipoNegocioViewModelProvider.notifier).elegirTipo(tipo);
      if (ok && context.mounted) context.go(AppRoutes.configuracionNegocio);
    }

    void volver() {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go(AppRoutes.seleccionRol);
      }
    }

    return PantallaSeleccion(
      titulo: '¿Qué tipo de negocio?',
      subtitulo: 'Elige la opción que mejor te represente para continuar',
      cargando: state.cargando,
      opciones: [
        OpcionCard(
          icono: const IconoAsset(IconosApp.carritoAmbulante),
          titulo: 'Ambulante',
          descripcion: 'Vendes en distintos lugares, sin un local fijo',
          onTap: state.cargando ? null : () => elegir(TipoNegocio.ambulante),
        ),
        OpcionCard(
          icono: const Icon(Icons.store_mall_directory_outlined),
          titulo: 'Fijo',
          descripcion: 'Atiendes en un local o establecimiento',
          onTap: state.cargando ? null : () => elegir(TipoNegocio.fijo),
        ),
      ],
      textoBotonInferior: 'Volver',
      onBotonInferior: volver,
    );
  }
}
