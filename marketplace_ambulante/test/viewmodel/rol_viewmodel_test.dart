import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:marketplace_ambulante/core/router/app_router.dart';
import 'package:marketplace_ambulante/model/auth_repository_mock.dart';
import 'package:marketplace_ambulante/model/negocio.dart';
import 'package:marketplace_ambulante/model/negocio_repository_mock.dart';
import 'package:marketplace_ambulante/model/repository_providers.dart';
import 'package:marketplace_ambulante/model/usuario.dart';
import 'package:marketplace_ambulante/viewmodel/seleccion_rol_viewmodel.dart';
import 'package:marketplace_ambulante/viewmodel/sesion_viewmodel.dart';
import 'package:marketplace_ambulante/viewmodel/sign_in_viewmodel.dart';
import 'package:marketplace_ambulante/viewmodel/sign_up_viewmodel.dart';
import 'package:marketplace_ambulante/viewmodel/tipo_negocio_viewmodel.dart';

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer(
      overrides: [
        authRepositoryProvider
            .overrideWithValue(AuthRepositoryMock(latencia: Duration.zero)),
        negocioRepositoryProvider
            .overrideWithValue(NegocioRepositoryMock(latencia: Duration.zero)),
      ],
    );
  });

  tearDown(() => container.dispose());

  /// Crea una cuenta nueva e inicia sesión (queda sin rol).
  Future<void> entrarConCuentaNueva() async {
    await container
        .read(signUpViewModelProvider.notifier)
        .registrar(
          nombre: 'Ana',
          apellido: 'Pérez',
          telefono: '3001112233',
          email: 'nuevo@test.com',
          password: 'Clave123',
        );
    await container
        .read(signInViewModelProvider.notifier)
        .iniciarSesion(email: 'nuevo@test.com', password: 'Clave123');
  }

  group('¿Eres un?', () {
    test('sin sesión → error', () async {
      final u =
          await container.read(seleccionRolViewModelProvider.notifier).elegirUsuario();
      expect(u, isNull);
      expect(container.read(seleccionRolViewModelProvider).error, isNotNull);
    });

    test('elegir Usuario → rol guardado → Marketplace', () async {
      await entrarConCuentaNueva();
      final u =
          await container.read(seleccionRolViewModelProvider.notifier).elegirUsuario();
      expect(u?.rol, RolUsuario.usuario);
      expect(container.read(sesionProvider)?.rol, RolUsuario.usuario);
      expect(AppRoutes.segunUsuario(u!), AppRoutes.marketplace);

      // Al volver a iniciar sesión, el rol se conserva.
      final otraVez = await container
          .read(signInViewModelProvider.notifier)
          .iniciarSesion(email: 'nuevo@test.com', password: 'Clave123');
      expect(otraVez?.rol, RolUsuario.usuario);
    });

    test('cerrar sesión → sesión vacía', () async {
      await entrarConCuentaNueva();
      await container.read(seleccionRolViewModelProvider.notifier).cerrarSesion();
      expect(container.read(sesionProvider), isNull);
    });
  });

  group('Tipo de negocio', () {
    test('elegir Ambulante → crea negocio y rol negocio', () async {
      await entrarConCuentaNueva();
      final ok = await container
          .read(tipoNegocioViewModelProvider.notifier)
          .elegirTipo(TipoNegocio.ambulante);
      expect(ok, isTrue);

      final sesion = container.read(sesionProvider)!;
      expect(sesion.rol, RolUsuario.negocio);

      final negocio = await container
          .read(negocioRepositoryProvider)
          .obtenerPorPropietario(sesion.id);
      expect(negocio?.tipo, TipoNegocio.ambulante);
    });
  });
}
