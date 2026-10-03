/// Tabla `productos`.
class Producto {
  const Producto({
    required this.id,
    required this.negocioId,
    required this.categoriaId,
    required this.nombre,
    required this.precio,
    this.descripcion = '',
    this.imagenUrl,
    this.stock = 0,
    this.disponible = true,
  });

  /// Vacío ('') = producto nuevo que aún no se ha guardado.
  final String id;
  final String negocioId;
  final String categoriaId;
  final String nombre;
  final String descripcion;
  final double precio;
  final String? imagenUrl;
  final int stock;

  /// El negocio puede ocultarlo aunque tenga stock.
  final bool disponible;

  bool get agotado => stock <= 0;

  /// Se puede pedir solo si está disponible y tiene stock.
  bool get sePuedePedir => disponible && !agotado;

  Producto copyWith({String? id}) => Producto(
        id: id ?? this.id,
        negocioId: negocioId,
        categoriaId: categoriaId,
        nombre: nombre,
        precio: precio,
        descripcion: descripcion,
        imagenUrl: imagenUrl,
        stock: stock,
        disponible: disponible,
      );
}
