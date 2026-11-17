import 'api_cliente.dart';
import 'api_json.dart';
import 'categoria.dart';
import 'producto.dart';
import 'producto_repository.dart';

/// Productos y categorías con la API real.
class ProductoRepositoryApi implements ProductoRepository {
  ProductoRepositoryApi(this._api);

  final ApiCliente _api;

  /// Las categorías casi nunca cambian: se piden una sola vez.
  List<Categoria>? _categorias;

  @override
  Future<List<Categoria>> obtenerCategorias() async => _categorias ??=
      listaDesdeJson(await _api.get('/app/categorias'), categoriaDesdeJson);

  @override
  Future<List<Producto>> obtenerPorNegocio(String negocioId) async =>
      listaDesdeJson(
        await _api.get('/app/negocios/$negocioId/productos'),
        productoDesdeJson,
      );

  @override
  Future<Producto> guardarProducto(Producto producto) async {
    final cuerpo = productoAJson(producto);
    final datos = producto.id.isEmpty
        ? await _api.post('/app/productos', cuerpo)
        : await _api.put('/app/productos/${producto.id}', cuerpo);
    return productoDesdeJson(datos as Json);
  }

  @override
  Future<void> eliminarProducto(String productoId) =>
      _api.delete('/app/productos/$productoId');
}
