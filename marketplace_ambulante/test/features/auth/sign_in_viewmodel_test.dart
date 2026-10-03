import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:marketplace_ambulante/core/router/app_router.dart';
import 'package:marketplace_ambulante/data/models/usuario.dart';
import 'package:marketplace_ambulante/data/providers/providers.dart';
import 'package:marketplace_ambulante/data/repositories/auth_repository_mock.dart';
import 'package:marketplace_ambulante/features/auth/viewmodel/sign_in_viewmodel.dart';

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer(
      overrides: [
        // Sin latencia para que los tests sean rápidos.
        authRepositoryProvider
            .overrideWithValue(AuthRepositoryMock(latencia: Duration.zero)),
      ],
    );
  });

  tearDown(() => container.dispose());

  SignInViewModel vm() => container.read(signInViewModelProvider.notifier);

  test('registrar correo nuevo → sin rol → va a ¿Eres un?', () async {
    final u = await vm().registrar('nuevo@test.com');
    expect(u, isNotNull);
    expect(u!.rol, isNull);
    expect(AppRoutes.segunUsuario(u), AppRoutes.seleccionRol);
    expect(container.read(sesionProvider)?.email, 'nuevo@test.com');
  });

  test('registrar correo existente → error', () async {
    final u = await vm().registrar('cliente@test.com');
    expect(u, isNull);
    expect(container.read(signInViewModelProvider).error, isNotNull);
  });

  test('iniciar sesión como negocio → panel del negocio', () async {
    final u = await vm().iniciarSesion('  NEGOCIO@test.com ');
    expect(u?.rol, RolUsuario.negocio);
    expect(AppRoutes.segunUsuario(u!), AppRoutes.panelNegocio);
  });

  test('iniciar sesión con correo inexistente → error', () async {
    final u = await vm().iniciarSesion('nadie@test.com');
    expect(u, isNull);
    expect(container.read(signInViewModelProvider).error, isNotNull);
  });
}
