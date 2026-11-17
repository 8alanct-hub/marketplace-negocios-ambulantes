import 'api_cliente.dart';
import 'api_json.dart';
import 'auth_repository.dart';
import 'usuario.dart';

/// Cuentas con la API real (rutas /app/registro, /app/login, /app/yo/rol).
class AuthRepositoryApi implements AuthRepository {
  AuthRepositoryApi(this._api);

  final ApiCliente _api;

  /// Convierte los errores de la API en [AuthException] (mismo mensaje).
  Future<T> _intentar<T>(Future<T> Function() accion) async {
    try {
      return await accion();
    } on ApiException catch (e) {
      throw AuthException(e.mensaje);
    }
  }

  @override
  Future<void> registrar({
    required String nombre,
    required String apellido,
    required String telefono,
    required String email,
    required String password,
  }) =>
      _intentar(() => _api.post('/app/registro', {
            'nombre': nombre,
            'apellido': apellido,
            'telefono': telefono,
            'correo': email,
            'clave': password,
          }));

  @override
  Future<Usuario> iniciarSesion({
    required String email,
    required String password,
  }) =>
      _intentar(() async {
        final datos = await _api.post('/app/login', {
          'correo': email,
          'clave': password,
        }) as Json;
        // Desde aquí, todas las peticiones llevan el token de esta sesión.
        _api.token = datos['token'] as String;
        return usuarioDesdeJson(datos['usuario'] as Json);
      });

  /// El servidor sabe quién es por el token; [usuarioId] no se envía.
  @override
  Future<Usuario> actualizarRol({
    required String usuarioId,
    required RolUsuario rol,
  }) =>
      _intentar(() async {
        final datos = await _api.patch('/app/yo/rol', {'rol': rol.name});
        return usuarioDesdeJson(datos as Json);
      });

  @override
  Future<void> cerrarSesion() async => _api.token = null;
}
