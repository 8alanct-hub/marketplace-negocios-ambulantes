import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/router/app_router.dart';
import '../viewmodel/estado_formulario.dart';
import '../viewmodel/seleccion_rol_viewmodel.dart';
import 'widgets/auth_widgets.dart';
import 'widgets/seleccion_widgets.dart';

/// View: "¿Eres un?" (aparece cuando la cuenta todavía no tiene rol).
///
/// - Usuario        → guarda el rol → Marketplace
/// - Negocio        → Tipo de negocio (el rol se guarda allá)
/// - Cerrar sesión  → Iniciar sesión
class SeleccionRolScreen extends ConsumerWidget {
  const SeleccionRolScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(seleccionRolViewModelProvider);
    final vm = ref.read(seleccionRolViewModelProvider.notifier);

    ref.listen<EstadoFormulario>(seleccionRolViewModelProvider, (prev, next) {
      if (next.error != null && next.error != prev?.error) {
        mostrarMensaje(context, next.error!);
      }
    });

    Future<void> elegirUsuario() async {
      final usuario = await vm.elegirUsuario();
      if (usuario != null && context.mounted) {
        context.go(AppRoutes.segunUsuario(usuario));
      }
    }

    Future<void> cerrarSesion() async {
      await vm.cerrarSesion();
      if (context.mounted) context.go(AppRoutes.iniciarSesion);
    }

    return PantallaSeleccion(
      titulo: '¿Eres un?',
      subtitulo: 'Elige la opción que mejor te represente para continuar',
      cargando: state.cargando,
      opciones: [
        OpcionCard(
          icono: const Icon(Icons.person_outline),
          titulo: 'Usuario',
          descripcion: 'Explora negocios cercanos y haz tus pedidos',
          onTap: state.cargando ? null : elegirUsuario,
        ),
        OpcionCard(
          icono: const Icon(Icons.storefront_outlined),
          titulo: 'Negocio',
          descripcion: 'Publica tus productos y recibe pedidos',
          // push (no go) para que "Volver" regrese a esta pantalla.
          onTap: state.cargando
              ? null
              : () => context.push(AppRoutes.tipoNegocio),
        ),
      ],
      textoBotonInferior: 'Cerrar sesión',
      onBotonInferior: cerrarSesion,
    );
  }
}
