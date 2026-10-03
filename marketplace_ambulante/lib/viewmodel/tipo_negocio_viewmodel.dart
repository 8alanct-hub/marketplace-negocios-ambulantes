import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../model/auth_repository.dart';
import '../model/negocio.dart';
import '../model/repository_providers.dart';
import '../model/usuario.dart';
import 'estado_formulario.dart';
import 'seleccion_rol_viewmodel.dart' show errorSinSesion;
import 'sesion_viewmodel.dart';

/// ViewModel de "¿Qué tipo de negocio?".
class TipoNegocioViewModel extends Notifier<EstadoFormulario> {
  @override
  EstadoFormulario build() => const EstadoFormulario();

  /// Crea el negocio con el [tipo] elegido y guarda el rol "negocio".
  /// Devuelve true si todo salió bien.
  Future<bool> elegirTipo(TipoNegocio tipo) async {
    if (state.cargando) return false;
    final sesion = ref.read(sesionProvider);
    if (sesion == null) {
      state = const EstadoFormulario(error: errorSinSesion);
      return false;
    }
    state = const EstadoFormulario(cargando: true);
    try {
      await ref
          .read(negocioRepositoryProvider)
          .crearNegocio(propietarioId: sesion.id, tipo: tipo);
      final usuario = await ref
          .read(authRepositoryProvider)
          .actualizarRol(usuarioId: sesion.id, rol: RolUsuario.negocio);
      ref.read(sesionProvider.notifier).actualizar(usuario);
      state = const EstadoFormulario();
      return true;
    } on AuthException catch (e) {
      state = EstadoFormulario(error: e.mensaje);
    } catch (_) {
      state = const EstadoFormulario(error: errorGenerico);
    }
    return false;
  }
}

final tipoNegocioViewModelProvider =
    NotifierProvider<TipoNegocioViewModel, EstadoFormulario>(
  TipoNegocioViewModel.new,
);
