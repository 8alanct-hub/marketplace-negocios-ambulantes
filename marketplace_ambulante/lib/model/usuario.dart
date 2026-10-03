enum RolUsuario { usuario, negocio }

/// Tabla `usuarios`. La contraseña nunca llega a la app: solo la guarda
/// el servidor (password_hash).
class Usuario {
  const Usuario({
    required this.id,
    required this.nombre,
    required this.apellido,
    required this.telefono,
    required this.email,
    this.rol,
  });

  final String id;
  final String nombre;
  final String apellido;
  final String telefono;

  /// Columna `correo`.
  final String email;

  /// null = cuenta recién creada que aún no eligió rol en "¿Eres un?".
  final RolUsuario? rol;

  String get nombreCompleto => '$nombre $apellido';

  Usuario copyWith({RolUsuario? rol}) => Usuario(
        id: id,
        nombre: nombre,
        apellido: apellido,
        telefono: telefono,
        email: email,
        rol: rol ?? this.rol,
      );
}
