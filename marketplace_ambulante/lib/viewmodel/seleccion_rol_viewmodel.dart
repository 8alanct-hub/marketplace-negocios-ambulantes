import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../model/auth_repository.dart';
import '../model/repository_providers.dart';
import '../model/usuario.dart';
import 'estado_formulario.dart';
import 'sesion_viewmodel.dart';

const errorSinSesion = 'Tu sesión expiró. Inicia sesión de nuevo.';

/// ViewModel de "¿Eres un?".
///
/// Elegir "Negocio" no guarda nada aquí: solo navega a "Tipo de negocio".
/// El rol negocio se guarda cuando se elige el tipo (así, si el usuario
/// vuelve atrás, su cuenta sigue sin rol).
class SeleccionRolViewModel extends Notifier<EstadoFormulario> {
  @override
  EstadoFormulario build() => const EstadoFormulario();

  /// Guarda el rol "usuario". Devuelve el usuario actualizado o null si falló.
  Future<Usuario?> elegirUsuario() async {
    if (state.cargando) return null;
    final sesion = ref.read(sesionProvider);
    if (sesion == null) {
      state = const EstadoFormulario(error: errorSinSesion);
      return null;
    }
    state = const EstadoFormulario(cargando: true);
    try {
      final usuario = await ref
          .read(authRepositoryProvider)
          .actualizarRol(usuarioId: sesion.id, rol: RolUsuario.usuario);
      ref.read(sesionProvider.notifier).actualizar(usuario);
      state = const EstadoFormulario();
      return usuario;
    } on AuthException catch (e) {
      state = EstadoFormulario(error: e.mensaje);
    } catch (_) {
      state = const EstadoFormulario(error: errorGenerico);
    }
    return null;
  }

  Future<void> cerrarSesion() async {
    if (state.cargando) return;
    state = const EstadoFormulario(cargando: true);
    try {
      await ref.read(authRepositoryProvider).cerrarSesion();
    } finally {
      // Aunque falle el servidor, localmente la sesión se cierra.
      ref.read(sesionProvider.notifier).cerrar();
      state = const EstadoFormulario();
    }
  }
}

final seleccionRolViewModelProvider =
    NotifierProvider<SeleccionRolViewModel, EstadoFormulario>(
  SeleccionRolViewModel.new,
);
