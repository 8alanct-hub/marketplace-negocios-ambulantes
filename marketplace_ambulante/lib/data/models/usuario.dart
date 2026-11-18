enum RolUsuario { usuario, negocio }

class Usuario {
  const Usuario({required this.id, required this.email, this.rol});

  final String id;
  final String email;

  /// null = cuenta recién creada que aún no eligió rol en "¿Eres un?".
  final RolUsuario? rol;

  Usuario copyWith({RolUsuario? rol}) =>
      Usuario(id: id, email: email, rol: rol ?? this.rol);
}
