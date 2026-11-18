/// Tabla `modalidades_pago`. La app no procesa pagos: solo registra
/// cómo acepta pagar cada negocio (tabla `negocio_modalidad_pago`).
class ModalidadPago {
  const ModalidadPago({
    required this.id,
    required this.nombre,
    required this.descripcion,
  });

  final String id;
  final String nombre;
  final String descripcion;
}
