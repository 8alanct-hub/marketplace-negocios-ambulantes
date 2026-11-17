// Conversión entre el JSON de la API y los modelos de la app.
// (Ver api/API_APP.md para el formato de cada respuesta.)
import 'categoria.dart';
import 'chat.dart';
import 'modalidad_pago.dart';
import 'negocio.dart';
import 'pedido.dart';
import 'producto.dart';
import 'usuario.dart';

typedef Json = Map<String, dynamic>;

String _texto(Object? v) => v == null ? '' : v.toString();

double? _decimal(Object? v) => v == null ? null : (v as num).toDouble();

DateTime? _fecha(Object? v) =>
    v == null ? null : DateTime.parse(v as String).toLocal();

/// Busca el valor del enum por su nombre ('fijo' → TipoNegocio.fijo).
T _enumDe<T extends Enum>(List<T> valores, Object? nombre, T porDefecto) =>
    valores.where((v) => v.name == nombre).firstOrNull ?? porDefecto;

// ------------------------------------------------------------- Usuario

Usuario usuarioDesdeJson(Json j) => Usuario(
      id: _texto(j['id']),
      nombre: _texto(j['nombre']),
      apellido: _texto(j['apellido']),
      telefono: _texto(j['telefono']),
      email: _texto(j['correo']),
      rol: j['rol'] == null
          ? null
          : RolUsuario.values.where((r) => r.name == j['rol']).firstOrNull,
    );

// ------------------------------------------------------------- Negocio

Negocio negocioDesdeJson(Json j) => Negocio(
      id: _texto(j['id']),
      propietarioId: _texto(j['propietarioId']),
      tipo: _enumDe(TipoNegocio.values, j['tipo'], TipoNegocio.fijo),
      nombre: _texto(j['nombre']),
      descripcion: _texto(j['descripcion']),
      telefono: _texto(j['telefono']),
      direccion: _texto(j['direccion']),
      latitud: _decimal(j['latitud']),
      longitud: _decimal(j['longitud']),
      ubicacionActualizada: _fecha(j['ubicacionActualizada']),
      logoUrl: j['logoUrl'] as String?,
      bannerUrl: j['bannerUrl'] as String?,
      estado: _enumDe(EstadoNegocio.values, j['estado'], EstadoNegocio.activo),
    );

/// Lo que se envía al guardar "Configuración de negocio".
Json negocioAJson(Negocio n) => {
      'tipo': n.tipo.name,
      'nombre': n.nombre,
      'descripcion': n.descripcion,
      'telefono': n.telefono,
      'direccion': n.direccion,
      'latitud': n.latitud,
      'longitud': n.longitud,
      'ubicacionActualizada': n.ubicacionActualizada?.toUtc().toIso8601String(),
      'logoUrl': n.logoUrl,
      'bannerUrl': n.bannerUrl,
    };

// ------------------------------------------------------------ Catálogos

ModalidadPago modalidadDesdeJson(Json j) => ModalidadPago(
      id: _texto(j['id']),
      nombre: _texto(j['nombre']),
      descripcion: _texto(j['descripcion']),
    );

Categoria categoriaDesdeJson(Json j) =>
    Categoria(id: _texto(j['id']), nombre: _texto(j['nombre']));

// ------------------------------------------------------------ Productos

Producto productoDesdeJson(Json j) => Producto(
      id: _texto(j['id']),
      negocioId: _texto(j['negocioId']),
      categoriaId: _texto(j['categoriaId']),
      nombre: _texto(j['nombre']),
      descripcion: _texto(j['descripcion']),
      precio: _decimal(j['precio']) ?? 0,
      imagenUrl: j['imagenUrl'] as String?,
      stock: (j['stock'] as num?)?.toInt() ?? 0,
      disponible: j['disponible'] as bool? ?? true,
    );

Json productoAJson(Producto p) => {
      'categoriaId': p.categoriaId.isEmpty ? null : p.categoriaId,
      'nombre': p.nombre,
      'descripcion': p.descripcion,
      'precio': p.precio,
      'imagenUrl': p.imagenUrl,
      'stock': p.stock,
      'disponible': p.disponible,
    };

// -------------------------------------------------------------- Pedidos

/// En la base el estado se escribe 'en_preparacion'; en la app, enPreparacion.
const _estadosBd = <EstadoPedido, String>{
  EstadoPedido.pendiente: 'pendiente',
  EstadoPedido.aceptado: 'aceptado',
  EstadoPedido.enPreparacion: 'en_preparacion',
  EstadoPedido.listo: 'listo',
  EstadoPedido.entregado: 'entregado',
  EstadoPedido.rechazado: 'rechazado',
  EstadoPedido.cancelado: 'cancelado',
};

String estadoPedidoAApi(EstadoPedido e) => _estadosBd[e]!;

EstadoPedido estadoPedidoDesdeApi(Object? valor) =>
    _estadosBd.entries.where((e) => e.value == valor).firstOrNull?.key ??
    EstadoPedido.pendiente;

Pedido pedidoDesdeJson(Json j) {
  final creado = _fecha(j['fechaCreacion']) ?? DateTime.now();
  return Pedido(
    id: _texto(j['id']),
    usuarioId: _texto(j['usuarioId']),
    clienteNombre: _texto(j['clienteNombre']),
    negocioId: _texto(j['negocioId']),
    negocioNombre: _texto(j['negocioNombre']),
    modalidadPagoId: _texto(j['modalidadPagoId']),
    estado: estadoPedidoDesdeApi(j['estado']),
    detalles: [
      for (final d in (j['detalles'] as List? ?? const []))
        DetallePedido(
          productoId: _texto((d as Json)['productoId']),
          nombreProducto: _texto(d['nombreProducto']),
          cantidad: (d['cantidad'] as num).toInt(),
          precioUnitario: _decimal(d['precioUnitario']) ?? 0,
        ),
    ],
    fechaCreacion: creado,
    fechaActualizacion: _fecha(j['fechaActualizacion']) ?? creado,
    motivo: j['motivo'] as String?,
  );
}

// ----------------------------------------------------------------- Chat

Conversacion conversacionDesdeJson(Json j) => Conversacion(
      id: _texto(j['id']),
      usuarioId: _texto(j['usuarioId']),
      negocioId: _texto(j['negocioId']),
      negocioNombre: _texto(j['negocioNombre']),
      fechaUltimoMensaje: _fecha(j['fechaUltimoMensaje']) ?? DateTime.now(),
      ultimoMensaje: j['ultimoMensaje'] as String?,
    );

Mensaje mensajeDesdeJson(Json j) => Mensaje(
      id: _texto(j['id']),
      conversacionId: _texto(j['conversacionId']),
      remitenteId: _texto(j['remitenteId']),
      texto: _texto(j['texto']),
      fechaEnvio: _fecha(j['fechaEnvio']) ?? DateTime.now(),
      leido: j['leido'] as bool? ?? false,
    );

/// Convierte una lista JSON con la función [convertir].
List<T> listaDesdeJson<T>(Object? datos, T Function(Json) convertir) => [
      for (final item in (datos as List? ?? const [])) convertir(item as Json),
    ];
