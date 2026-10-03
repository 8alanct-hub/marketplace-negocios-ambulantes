import 'categoria.dart';
import 'mock_catalogos.dart';
import 'producto.dart';
import 'producto_repository.dart';

class ProductoRepositoryMock implements ProductoRepository {
  ProductoRepositoryMock({this.latencia = const Duration(milliseconds: 500)});

  final Duration latencia;

  final Map<String, Producto> _productos = {
    for (final p in mockProductos) p.id: p,
  };
  int _siguienteId = mockProductos.length + 1;

  Future<void> _esperar() => Future<void>.delayed(latencia);

  @override
  Future<List<Categoria>> obtenerCategorias() async {
    await _esperar();
    return mockCategorias;
  }

  @override
  Future<List<Producto>> obtenerPorNegocio(String negocioId) async {
    await _esperar();
    return _productos.values.where((p) => p.negocioId == negocioId).toList();
  }

  @override
  Future<Producto> guardarProducto(Producto producto) async {
    await _esperar();
    final guardado = producto.id.isEmpty
        ? producto.copyWith(id: 'p_${_siguienteId++}')
        : producto;
    _productos[guardado.id] = guardado;
    return guardado;
  }

  @override
  Future<void> eliminarProducto(String productoId) async {
    await _esperar();
    _productos.remove(productoId);
  }
}
