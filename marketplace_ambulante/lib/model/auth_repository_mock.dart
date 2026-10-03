import 'auth_repository.dart';
import 'mock_usuarios.dart';
import 'usuario.dart';

class AuthRepositoryMock implements AuthRepository {
  AuthRepositoryMock({this.latencia = const Duration(milliseconds: 800)});

  /// Simula el tiempo de respuesta de un servidor.
  final Duration latencia;

  final Map<String, Usuario> _usuarios = {
    for (final u in mockUsuarios) u.email: u,
  };

  /// Solo en el mock la contraseña se guarda en texto plano.
  /// El backend real la guarda cifrada (password_hash).
  final Map<String, String> _passwords = {
    for (final u in mockUsuarios) u.email: mockPassword,
  };

  String _normalizar(String email) => email.trim().toLowerCase();

  @override
  Future<void> registrar({
    required String nombre,
    required String apellido,
    required String telefono,
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(latencia);
    final key = _normalizar(email);
    if (_usuarios.containsKey(key)) {
      throw const AuthException('Este correo ya tiene una cuenta.');
    }
    _usuarios[key] = Usuario(
      id: 'u_${_usuarios.length + 1}',
      nombre: nombre.trim(),
      apellido: apellido.trim(),
      telefono: telefono.trim(),
      email: key,
    );
    _passwords[key] = password;
  }

  @override
  Future<Usuario> iniciarSesion({
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(latencia);
    final key = _normalizar(email);
    final usuario = _usuarios[key];
    // Mismo mensaje para "no existe" y "contraseña mala": así no se revela
    // qué correos están registrados.
    if (usuario == null || _passwords[key] != password) {
      throw const AuthException('Correo o contraseña incorrectos.');
    }
    return usuario;
  }

  @override
  Future<Usuario> actualizarRol({
    required String usuarioId,
    required RolUsuario rol,
  }) async {
    await Future<void>.delayed(latencia);
    final entrada = _usuarios.entries
        .where((e) => e.value.id == usuarioId)
        .firstOrNull;
    if (entrada == null) {
      throw const AuthException('No encontramos tu cuenta. Inicia sesión de nuevo.');
    }
    final actualizado = entrada.value.copyWith(rol: rol);
    _usuarios[entrada.key] = actualizado;
    return actualizado;
  }

  @override
  Future<void> cerrarSesion() => Future<void>.delayed(latencia);
}
