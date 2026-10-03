import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../model/auth_repository.dart';
import '../model/repository_providers.dart';
import 'estado_formulario.dart';

/// ViewModel de "Crear cuenta".
class SignUpViewModel extends Notifier<EstadoFormulario> {
  @override
  EstadoFormulario build() => const EstadoFormulario();

  /// Devuelve true si la cuenta se creó. Si falla, el mensaje
  /// queda en [EstadoFormulario.error].
  Future<bool> registrar({
    required String nombre,
    required String apellido,
    required String telefono,
    required String email,
    required String password,
  }) async {
    if (state.cargando) return false; // evita doble toque
    state = const EstadoFormulario(cargando: true);
    try {
      await ref
          .read(authRepositoryProvider)
          .registrar(
            nombre: nombre.trim(),
            apellido: apellido.trim(),
            telefono: telefono.trim(),
            email: email.trim(),
            password: password,
          );
      state = const EstadoFormulario();
      return true;
    } on AuthException catch (e) {
      state = EstadoFormulario(error: e.mensaje);
    } catch (_) {
      state = const EstadoFormulario(error: errorGenerico);
    }
    return false;
  }

  void limpiarError() {
    if (state.error != null) state = const EstadoFormulario();
  }
}

final signUpViewModelProvider =
    NotifierProvider<SignUpViewModel, EstadoFormulario>(SignUpViewModel.new);
