import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../model/auth_repository.dart';
import '../model/repository_providers.dart';
import '../model/usuario.dart';
import 'estado_formulario.dart';
import 'sesion_viewmodel.dart';

/// ViewModel de "Iniciar sesión".
class SignInViewModel extends Notifier<EstadoFormulario> {
  @override
  EstadoFormulario build() => const EstadoFormulario();

  /// Devuelve el usuario si entró, o null si falló
  /// (el mensaje queda en [EstadoFormulario.error]).
  Future<Usuario?> iniciarSesion({
    required String email,
    required String password,
  }) async {
    if (state.cargando) return null; // evita doble toque
    state = const EstadoFormulario(cargando: true);
    try {
      final usuario = await ref
          .read(authRepositoryProvider)
          .iniciarSesion(email: email.trim(), password: password);
      ref.read(sesionProvider.notifier).iniciar(usuario);
      state = const EstadoFormulario();
      return usuario;
    } on AuthException catch (e) {
      state = EstadoFormulario(error: e.mensaje);
    } catch (_) {
      state = const EstadoFormulario(error: errorGenerico);
    }
    return null;
  }

  void limpiarError() {
    if (state.error != null) state = const EstadoFormulario();
  }
}

final signInViewModelProvider =
    NotifierProvider<SignInViewModel, EstadoFormulario>(SignInViewModel.new);
