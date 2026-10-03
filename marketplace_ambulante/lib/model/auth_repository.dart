import 'usuario.dart';

/// Error con un mensaje listo para mostrar al usuario.
class AuthException implements Exception {
  const AuthException(this.mensaje);
  final String mensaje;

  @override
  String toString() => mensaje;
}

/// Contrato de autenticación (qué se puede hacer, no cómo).
/// Hoy lo implementa [AuthRepositoryMock]; con backend se crea
/// otra implementación (la API real) sin tocar Views ni ViewModels.
abstract interface class AuthRepository {
  /// Crea una cuenta. NO inicia sesión: después hay que llamar a [iniciarSesion].
  /// La contraseña viaja al servidor, que es quien la cifra (password_hash).
  Future<void> registrar({
    required String nombre,
    required String apellido,
    required String telefono,
    required String email,
    required String password,
  });

  /// Inicia sesión con una cuenta existente.
  Future<Usuario> iniciarSesion({
    required String email,
    required String password,
  });

  /// Guarda el rol elegido en "¿Eres un?" y devuelve el usuario actualizado.
  Future<Usuario> actualizarRol({
    required String usuarioId,
    required RolUsuario rol,
  });

  Future<void> cerrarSesion();
}
