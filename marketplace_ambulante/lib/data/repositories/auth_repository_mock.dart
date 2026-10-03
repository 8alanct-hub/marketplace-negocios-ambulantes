import '../mock/mock_usuarios.dart';
import '../models/usuario.dart';
import 'auth_repository.dart';

class AuthRepositoryMock implements AuthRepository {
  AuthRepositoryMock({this.latencia = const Duration(milliseconds: 800)});

  /// Simula el tiempo de respuesta de un servidor.
  final Duration latencia;

  final Map<String, Usuario> _usuarios = {
    for (final u in mockUsuarios) u.email: u,
  };

  String _normalizar(String email) => email.trim().toLowerCase();

  @override
  Future<Usuario> registrar(String email) async {
    await Future<void>.delayed(latencia);
    final key = _normalizar(email);
    if (_usuarios.containsKey(key)) {
      throw const AuthException(
        'Este correo ya tiene una cuenta. Usa "Iniciar sesión".',
      );
    }
    final nuevo = Usuario(id: 'u_${_usuarios.length + 1}', email: key);
    _usuarios[key] = nuevo;
    return nuevo;
  }

  @override
  Future<Usuario> iniciarSesion(String email) async {
    await Future<void>.delayed(latencia);
    final usuario = _usuarios[_normalizar(email)];
    if (usuario == null) {
      throw const AuthException(
        'No encontramos una cuenta con este correo. Crea una con "Continuar".',
      );
    }
    return usuario;
  }

  @override
  Future<void> cerrarSesion() => Future<void>.delayed(latencia);
}
