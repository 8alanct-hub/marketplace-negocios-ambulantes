import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:marketplace_ambulante/core/router/app_router.dart';
import 'package:marketplace_ambulante/model/auth_repository_mock.dart';
import 'package:marketplace_ambulante/model/mock_usuarios.dart';
import 'package:marketplace_ambulante/model/repository_providers.dart';
import 'package:marketplace_ambulante/model/usuario.dart';
import 'package:marketplace_ambulante/viewmodel/sesion_viewmodel.dart';
import 'package:marketplace_ambulante/viewmodel/sign_in_viewmodel.dart';
import 'package:marketplace_ambulante/viewmodel/sign_up_viewmodel.dart';

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

  SignUpViewModel signUp() => container.read(signUpViewModelProvider.notifier);
  SignInViewModel signIn() => container.read(signInViewModelProvider.notifier);

  group('Crear cuenta', () {
    test('correo nuevo → se crea pero NO inicia sesión', () async {
      final ok = await signUp().registrar(
        nombre: 'Ana',
        apellido: 'Pérez',
        telefono: '3001112233',
        email: 'nuevo@test.com',
        password: 'Clave123',
      );
      expect(ok, isTrue);
      expect(container.read(sesionProvider), isNull);
    });

    test('correo existente → error', () async {
      final ok = await signUp().registrar(
        nombre: 'Ana',
        apellido: 'Pérez',
        telefono: '3001112233',
        email: 'cliente@test.com',
        password: 'Clave123',
      );
      expect(ok, isFalse);
      expect(container.read(signUpViewModelProvider).error, isNotNull);
    });
  });

  group('Iniciar sesión', () {
    test('cuenta recién creada → sin rol → va a ¿Eres un?', () async {
      await signUp().registrar(
        nombre: 'Ana',
        apellido: 'Pérez',
        telefono: '3001112233',
        email: 'nuevo@test.com',
        password: 'Clave123',
      );
      final u = await signIn()
          .iniciarSesion(email: 'nuevo@test.com', password: 'Clave123');
      expect(u?.rol, isNull);
      expect(AppRoutes.segunUsuario(u!), AppRoutes.seleccionRol);
      expect(container.read(sesionProvider)?.email, 'nuevo@test.com');
      expect(container.read(sesionProvider)?.nombreCompleto, 'Ana Pérez');
    });

    test('negocio con contraseña correcta → panel del negocio', () async {
      final u = await signIn()
          .iniciarSesion(email: '  NEGOCIO@test.com ', password: mockPassword);
      expect(u?.rol, RolUsuario.negocio);
      expect(AppRoutes.segunUsuario(u!), AppRoutes.panelNegocio);
    });

    test('contraseña incorrecta → error y sin sesión', () async {
      final u = await signIn()
          .iniciarSesion(email: 'cliente@test.com', password: 'otra1234');
      expect(u, isNull);
      expect(container.read(signInViewModelProvider).error,
          'Correo o contraseña incorrectos.');
      expect(container.read(sesionProvider), isNull);
    });

    test('correo inexistente → mismo mensaje de error', () async {
      final u = await signIn()
          .iniciarSesion(email: 'nadie@test.com', password: mockPassword);
      expect(u, isNull);
      expect(container.read(signInViewModelProvider).error,
          'Correo o contraseña incorrectos.');
    });
  });
}
