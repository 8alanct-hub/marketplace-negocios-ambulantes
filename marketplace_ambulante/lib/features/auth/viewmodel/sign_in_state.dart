/// Qué botón disparó la operación en curso (para mostrar el spinner
/// solo en ese botón).
enum SignInAccion { registrar, iniciarSesion }

class SignInState {
  const SignInState({this.accionEnCurso, this.error});

  /// null = no hay ninguna operación en curso.
  final SignInAccion? accionEnCurso;

  /// Mensaje de error de la última operación, si falló.
  final String? error;

  bool get cargando => accionEnCurso != null;
}
