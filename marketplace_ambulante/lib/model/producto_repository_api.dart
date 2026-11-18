import '../services/api_service.dart';
import 'categoria.dart';
import 'producto.dart';
import 'producto_repository.dart';

class ProductoRepositoryApi implements ProductoRepository {
  ProductoRepositoryApi({required this.api});

  final ApiService api;

  // Convierte valores JSON a double de forma segura.
  double _convertirDouble(dynamic valor, String campo) {
    if (valor == null) {
      throw FormatException('El campo "$campo" no puede ser null');
    }

    if (valor is num) {
      return valor.toDouble();
    }

    final resultado = double.tryParse(valor.toString());

    if (resultado == null) {
      throw FormatException(
        'No se pudo convertir "$valor" a double en el campo "$campo"',
      );
    }

    return resultado;
  }

  // Convierte valores JSON a int de forma segura.
  int _convertirInt(dynamic valor, String campo) {
    if (valor == null) {
      return 0;
    }

    if (valor is int) {
      return valor;
    }

    if (valor is num) {
      return valor.toInt();
    }

    final resultado = int.tryParse(valor.toString());

    if (resultado != null) {
      return resultado;
    }

    // También admite cadenas como "5.0".
    final decimal = double.tryParse(valor.toString());

    if (decimal != null) {
      return decimal.toInt();
    }

    throw FormatException(
      'No se pudo convertir "$valor" a int en el campo "$campo"',
    );
  }

  // Convierte el JSON recibido del backend a un Producto.
  Producto _convertirProducto(Map<String, dynamic> json) {
    return Producto(
      id: json['id_producto'].toString(),
      negocioId: json['id_negocio'].toString(),
      categoriaId: json['id_categoria'].toString(),
      nombre: json['nombre'] as String,
      descripcion: json['descripcion'] as String? ?? '',
      precio: _convertirDouble(json['precio'], 'precio'),
      imagenUrl: json['imagen_url'] as String?,
      stock: _convertirInt(json['stock'], 'stock'),
      disponible: json['disponible'] as bool? ?? true,
    );
  }

  @override
  Future<List<Categoria>> obtenerCategorias() async {
    final response = await api.get('/categorias');

    final items = response['items'] as List<dynamic>;

    return items.map((item) {
      final json = item as Map<String, dynamic>;

      return Categoria(
        id: json['id_categoria'].toString(),
        nombre: json['nombre'] as String,
      );
    }).toList();
  }

  @override
  Future<List<Producto>> obtenerPorNegocio(String negocioId) async {
    final response = await api.get('/productos/mio', authenticated: true);

    final items = response['items'] as List<dynamic>;

    return items.map((item) {
      return _convertirProducto(item as Map<String, dynamic>);
    }).toList();
  }

  @override
  Future<Producto> guardarProducto(Producto producto) async {
    final body = {
      'id_categoria': int.parse(producto.categoriaId),
      'nombre': producto.nombre,
      'descripcion': producto.descripcion,
      'tipo': 'PRODUCTO',
      'precio': producto.precio,
      'imagen_url': producto.imagenUrl,
      'stock': producto.stock,
      'disponible': producto.disponible,
    };

    final Map<String, dynamic> response;

    if (producto.id.isEmpty) {
      response = await api.post('/productos', authenticated: true, body: body);
    } else {
      response = await api.patch(
        '/productos/${producto.id}',
        authenticated: true,
        body: body,
      );
    }

    return _convertirProducto(response);
  }

  @override
  Future<void> eliminarProducto(String productoId) async {
    await api.delete('/productos/$productoId', authenticated: true);
  }
}
