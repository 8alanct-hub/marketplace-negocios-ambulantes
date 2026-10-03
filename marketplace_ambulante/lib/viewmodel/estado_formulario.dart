const errorGenerico = 'Ocurrió un error inesperado. Intenta de nuevo.';

/// Estado común de los formularios (crear cuenta, iniciar sesión...).
class EstadoFormulario {
  const EstadoFormulario({this.cargando = false, this.error});

  /// true mientras se espera la respuesta (se muestra el spinner).
  final bool cargando;

  /// Mensaje de error de la última operación, si falló.
  final String? error;
}
