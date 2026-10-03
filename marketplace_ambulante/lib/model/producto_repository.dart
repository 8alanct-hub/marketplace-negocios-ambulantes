import 'categoria.dart';
import 'producto.dart';

/// Contrato para los productos y sus categorías.
abstract interface class ProductoRepository {
  Future<List<Categoria>> obtenerCategorias();

  Future<List<Producto>> obtenerPorNegocio(String negocioId);

  /// Crea el producto si su id está vacío; si no, lo actualiza.
  Future<Producto> guardarProducto(Producto producto);

  Future<void> eliminarProducto(String productoId);
}
