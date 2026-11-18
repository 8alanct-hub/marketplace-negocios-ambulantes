import 'package:marketplace_ambulante/services/api_service.dart';

import 'auth_repository.dart';
import 'usuario.dart';

class AuthRepositoryApi implements AuthRepository {
  AuthRepositoryApi({required this.api});

  final ApiService api;

  Usuario _convertirUsuario(Map<String, dynamic> json) {
    final rolJson = json['rol'] as String?;

    final RolUsuario? rol;

    switch (rolJson) {
      case 'USUARIO':
        rol = RolUsuario.usuario;
        break;
      case 'NEGOCIO':
        rol = RolUsuario.negocio;
        break;
      case null:
        rol = null;
        break;
      default:
        throw const AuthException(
          'Esta cuenta tiene un rol que todavía no está habilitado '
          'en esta versión de la aplicación.',
        );
    }

    return Usuario(
      id: json['id_usuario'].toString(),
      nombre: json['nombre'] as String,
      apellido: json['apellido'] as String,
      telefono: json['telefono'] as String? ?? '',
      email: json['correo'] as String,
      rol: rol,
    );
  }

  Never _convertirError(ApiException error) {
    throw AuthException(error.message);
  }

  @override
  Future<void> registrar({
    required String nombre,
    required String apellido,
    required String telefono,
    required String email,
    required String password,
  }) async {
    try {
      await api.post(
        '/auth/register',
        body: {
          'nombre': nombre,
          'apellido': apellido,
          'telefono': telefono.isEmpty ? null : telefono,
          'correo': email.trim().toLowerCase(),
          'password': password,
        },
      );
    } on ApiException catch (e) {
      _convertirError(e);
    }
  }

  @override
  Future<Usuario> iniciarSesion({
    required String email,
    required String password,
  }) async {
    try {
      final response = await api.post(
        '/auth/login',
        body: {'correo': email.trim().toLowerCase(), 'password': password},
      );

      final token = response['access_token'] as String;
      final userJson = response['user'] as Map<String, dynamic>;

      await api.guardarToken(token);

      return _convertirUsuario(userJson);
    } on ApiException catch (e) {
      _convertirError(e);
    }
  }

  @override
  Future<Usuario> actualizarRol({
    required String usuarioId,
    required RolUsuario rol,
  }) async {
    try {
      final token = await api.obtenerToken();

      if (token == null || token.isEmpty) {
        throw const AuthException('Tu sesión expiró. Inicia sesión de nuevo.');
      }

      final response = await api.patch(
        '/auth/role',
        authenticated: true,
        body: {'rol': rol == RolUsuario.usuario ? 'USUARIO' : 'NEGOCIO'},
      );

      final usuario = _convertirUsuario(response);

      if (usuario.id != usuarioId) {
        throw const AuthException(
          'La cuenta autenticada no coincide con el usuario actual.',
        );
      }

      return usuario;
    } on ApiException catch (e) {
      _convertirError(e);
    }
  }

  @override
  Future<void> cerrarSesion() async {
    await api.eliminarToken();
  }
}
