import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../model/usuario.dart';

/// Usuario con sesión iniciada (null = nadie ha iniciado sesión).
/// Lo comparten todas las pantallas.
class SesionViewModel extends Notifier<Usuario?> {
  @override
  Usuario? build() => null;

  void iniciar(Usuario usuario) => state = usuario;

  void actualizar(Usuario usuario) => state = usuario;

  void cerrar() => state = null;
}

final sesionProvider =
    NotifierProvider<SesionViewModel, Usuario?>(SesionViewModel.new);
