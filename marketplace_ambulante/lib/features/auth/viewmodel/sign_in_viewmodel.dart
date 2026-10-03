import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/usuario.dart';
import '../../../data/providers/providers.dart';
import '../../../data/repositories/auth_repository.dart';
import 'sign_in_state.dart';

class SignInViewModel extends Notifier<SignInState> {
  @override
  SignInState build() => const SignInState();

  AuthRepository get _repo => ref.read(authRepositoryProvider);

  /// Botón "Continuar": crea una cuenta nueva.
  Future<Usuario?> registrar(String email) =>
      _ejecutar(SignInAccion.registrar, () => _repo.registrar(email.trim()));

  /// Botón "Iniciar sesión": entra con una cuenta existente.
  Future<Usuario?> iniciarSesion(String email) => _ejecutar(
        SignInAccion.iniciarSesion,
        () => _repo.iniciarSesion(email.trim()),
      );

  void limpiarError() {
    if (state.error != null) state = const SignInState();
  }

  /// Devuelve el usuario si todo salió bien, o null si falló
  /// (el error queda en [SignInState.error]).
  Future<Usuario?> _ejecutar(
    SignInAccion accion,
    Future<Usuario> Function() operacion,
  ) async {
    if (state.cargando) return null; // evita doble toque
    state = SignInState(accionEnCurso: accion);
    try {
      final usuario = await operacion();
      ref.read(sesionProvider.notifier).iniciar(usuario);
      state = const SignInState();
      return usuario;
    } on AuthException catch (e) {
      state = SignInState(error: e.mensaje);
    } catch (_) {
      state = const SignInState(
        error: 'Ocurrió un error inesperado. Intenta de nuevo.',
      );
    }
    return null;
  }
}

final signInViewModelProvider =
    NotifierProvider<SignInViewModel, SignInState>(SignInViewModel.new);
