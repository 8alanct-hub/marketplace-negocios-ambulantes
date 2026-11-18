import '../models/usuario.dart';

/// Cuentas de prueba para "Iniciar sesión" mientras no hay backend.
const mockUsuarios = <Usuario>[
  Usuario(id: 'u_1', email: 'cliente@test.com', rol: RolUsuario.usuario),
  Usuario(id: 'u_2', email: 'negocio@test.com', rol: RolUsuario.negocio),
];
