import '../models/usuario.dart';

/// Error de negocio con un mensaje listo para mostrar al usuario.
class AuthException implements Exception {
  const AuthException(this.mensaje);
  final String mensaje;

  @override
  String toString() => mensaje;
}

/// Contrato de autenticación. Hoy lo implementa [AuthRepositoryMock];
/// cuando exista backend se crea otra implementación sin tocar la UI.
abstract interface class AuthRepository {
  /// Crea una cuenta nueva (sin rol todavía).
  Future<Usuario> registrar(String email);

  /// Inicia sesión con una cuenta existente.
  Future<Usuario> iniciarSesion(String email);

  Future<void> cerrarSesion();
}
