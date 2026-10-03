import 'categoria.dart';
import 'modalidad_pago.dart';
import 'producto.dart';

/// Datos de prueba de catálogos mientras no hay backend.

const mockModalidadesPago = <ModalidadPago>[
  ModalidadPago(
    id: 'm_1',
    nombre: 'Pago en el negocio',
    descripcion: 'El cliente paga en persona cuando recoge su pedido',
  ),
  ModalidadPago(
    id: 'm_2',
    nombre: 'Contraentrega',
    descripcion: 'El cliente paga al recibir; la entrega se acuerda por el chat',
  ),
];

const mockCategorias = <Categoria>[
  Categoria(id: 'c_1', nombre: 'Comida'),
  Categoria(id: 'c_2', nombre: 'Bebidas'),
  Categoria(id: 'c_3', nombre: 'Belleza y cuidado'),
  Categoria(id: 'c_4', nombre: 'Ropa y accesorios'),
  Categoria(id: 'c_5', nombre: 'Artesanías'),
  Categoria(id: 'c_6', nombre: 'Servicios'),
  Categoria(id: 'c_7', nombre: 'Otros'),
];

/// Productos del negocio de prueba "Nouveau Beauty Salon" (n_1).
const mockProductos = <Producto>[
  Producto(
    id: 'p_1',
    negocioId: 'n_1',
    categoriaId: 'c_3',
    nombre: 'Manicure tradicional',
    descripcion: 'Limado, cutícula y esmaltado',
    precio: 25000,
    stock: 10,
  ),
  Producto(
    id: 'p_2',
    negocioId: 'n_1',
    categoriaId: 'c_3',
    nombre: 'Pedicure spa',
    descripcion: 'Exfoliación, hidratación y esmaltado',
    precio: 35000,
    stock: 6,
  ),
  // Arepas La Esquina (n_2)
  Producto(
    id: 'p_3',
    negocioId: 'n_2',
    categoriaId: 'c_1',
    nombre: 'Arepa de huevo',
    descripcion: 'Con huevo y carne molida',
    precio: 5000,
    stock: 30,
  ),
  Producto(
    id: 'p_4',
    negocioId: 'n_2',
    categoriaId: 'c_1',
    nombre: 'Arepa de queso',
    precio: 4000,
    stock: 25,
  ),
  Producto(
    id: 'p_5',
    negocioId: 'n_2',
    categoriaId: 'c_2',
    nombre: 'Jugo de corozo',
    precio: 3000,
    stock: 0, // agotado: se ve pero no se puede pedir
  ),
  // Frutas Doña Rosa (n_3)
  Producto(
    id: 'p_6',
    negocioId: 'n_3',
    categoriaId: 'c_1',
    nombre: 'Salpicón',
    descripcion: 'Frutas picadas con jugo de patilla',
    precio: 6000,
    stock: 15,
  ),
  Producto(
    id: 'p_7',
    negocioId: 'n_3',
    categoriaId: 'c_1',
    nombre: 'Mango biche con sal',
    precio: 3500,
    stock: 20,
  ),
  // Panadería El Trigal (n_4)
  Producto(
    id: 'p_8',
    negocioId: 'n_4',
    categoriaId: 'c_1',
    nombre: 'Pan de bono',
    precio: 2500,
    stock: 40,
  ),
  Producto(
    id: 'p_9',
    negocioId: 'n_4',
    categoriaId: 'c_2',
    nombre: 'Café tinto',
    precio: 2000,
    stock: 50,
    disponible: false, // el negocio lo ocultó por ahora
  ),
  // Artesanías Mompox (n_5)
  Producto(
    id: 'p_10',
    negocioId: 'n_5',
    categoriaId: 'c_5',
    nombre: 'Aretes en filigrana',
    descripcion: 'Plata, hechos a mano',
    precio: 85000,
    stock: 4,
  ),
  Producto(
    id: 'p_11',
    negocioId: 'n_5',
    categoriaId: 'c_4',
    nombre: 'Sombrero vueltiao',
    precio: 120000,
    stock: 2,
  ),
];

/// Formas de pago habilitadas por negocio (negocioId → ids de modalidad).
const mockModalidadesPorNegocio = <String, Set<String>>{
  'n_1': {'m_1'},
  'n_2': {'m_2'},
  'n_3': {'m_1', 'm_2'},
  'n_4': {'m_1'},
  'n_5': {'m_1', 'm_2'},
};
