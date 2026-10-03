import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/usuario.dart';
import '../repositories/auth_repository.dart';
import '../repositories/auth_repository_mock.dart';

/// Único punto donde se decide qué implementación se usa.
/// Para conectar el backend: devolver AuthRepositoryApi() aquí.
final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepositoryMock(),
);

/// Sesión actual de la app (null = nadie ha iniciado sesión).
class SesionNotifier extends Notifier<Usuario?> {
  @override
  Usuario? build() => null;

  void iniciar(Usuario usuario) => state = usuario;

  void actualizar(Usuario usuario) => state = usuario;

  void cerrar() => state = null;
}

final sesionProvider =
    NotifierProvider<SesionNotifier, Usuario?>(SesionNotifier.new);
