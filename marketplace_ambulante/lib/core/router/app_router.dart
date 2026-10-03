import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../model/usuario.dart';
import '../../view/acerca_de_screen.dart';
import '../../view/chat_screen.dart';
import '../../view/configuracion_negocio_screen.dart';
import '../../view/confirmar_pedido_screen.dart';
import '../../view/inicio_usuario_screen.dart';
import '../../view/pagina_negocio_screen.dart';
import '../../view/panel_negocio_screen.dart';
import '../../view/seleccion_rol_screen.dart';
import '../../view/sign_in_screen.dart';
import '../../view/sign_up_screen.dart';
import '../../view/tipo_negocio_screen.dart';
import '../../viewmodel/sesion_viewmodel.dart';

abstract final class AppRoutes {
  static const registro = '/registro';
  static const iniciarSesion = '/iniciar-sesion';
  static const seleccionRol = '/seleccion-rol';
  static const tipoNegocio = '/negocio/tipo';
  static const configuracionNegocio = '/negocio/configuracion';
  static const marketplace = '/marketplace';
  static const panelNegocio = '/negocio/panel';

  /// Inicio del usuario abierto en la sección "Mis pedidos".
  static const misPedidos = '$marketplace?seccion=pedidos';
  static const acercaDe = '/acerca-de';

  /// Página pública de un negocio (la que ve el usuario).
  static String paginaNegocio(String negocioId) => '/negocios/$negocioId';

  /// "Forma de recibir el pedido" de ese negocio.
  static String confirmarPedido(String negocioId) =>
      '/negocios/$negocioId/pedido';

  static String chatConNegocio(String negocioId) => '/chat/$negocioId';

  /// Rutas que se pueden abrir sin haber iniciado sesión.
  static const publicas = {registro, iniciarSesion};

  /// A dónde va cada usuario después de iniciar sesión.
  static String segunUsuario(Usuario u) => switch (u.rol) {
        null => seleccionRol,
        RolUsuario.usuario => marketplace,
        RolUsuario.negocio => panelNegocio,
      };
}

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.registro,
    // Protección: sin sesión solo se puede estar en registro / inicio de sesión.
    redirect: (context, state) {
      final conSesion = ref.read(sesionProvider) != null;
      final esPublica = AppRoutes.publicas.contains(state.matchedLocation);
      if (!conSesion && !esPublica) return AppRoutes.iniciarSesion;
      return null; // sin cambios
    },
    routes: [
      GoRoute(
        path: AppRoutes.registro,
        builder: (context, state) => const SignUpScreen(),
      ),
      GoRoute(
        path: AppRoutes.iniciarSesion,
        // extra = correo que viene escrito desde "Crear cuenta".
        builder: (context, state) => SignInScreen(
          emailInicial: state.extra is String ? state.extra as String : null,
        ),
      ),
      GoRoute(
        path: AppRoutes.seleccionRol,
        builder: (context, state) => const SeleccionRolScreen(),
      ),
      GoRoute(
        path: AppRoutes.tipoNegocio,
        builder: (context, state) => const TipoNegocioScreen(),
      ),
      GoRoute(
        path: AppRoutes.configuracionNegocio,
        builder: (context, state) => const ConfiguracionNegocioScreen(),
      ),
      GoRoute(
        path: AppRoutes.marketplace,
        // ?seccion=pedidos|chats|perfil abre esa pestaña de la barra inferior.
        builder: (context, state) => InicioUsuarioScreen(
          seccionInicial: SeccionUsuario.values.firstWhere(
            (s) => s.name == state.uri.queryParameters['seccion'],
            orElse: () => SeccionUsuario.inicio,
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.panelNegocio,
        builder: (context, state) => const PanelNegocioScreen(),
      ),
      GoRoute(
        path: '/negocios/:id',
        builder: (context, state) =>
            PaginaNegocioScreen(negocioId: state.pathParameters['id']!),
        routes: [
          GoRoute(
            path: 'pedido',
            builder: (context, state) =>
                ConfirmarPedidoScreen(negocioId: state.pathParameters['id']!),
          ),
        ],
      ),
      GoRoute(
        path: '/chat/:negocioId',
        builder: (context, state) =>
            ChatScreen(negocioId: state.pathParameters['negocioId']!),
      ),
      GoRoute(
        path: AppRoutes.acercaDe,
        builder: (context, state) => const AcercaDeScreen(),
      ),
    ],
  );
});
