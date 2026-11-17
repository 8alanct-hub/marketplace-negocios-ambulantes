import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/api_config.dart';
import 'api_cliente.dart';
import 'auth_repository.dart';
import 'auth_repository_api.dart';
import 'auth_repository_mock.dart';
import 'chat_repository.dart';
import 'chat_repository_api.dart';
import 'chat_repository_mock.dart';
import 'imagen_service.dart';
import 'negocio_repository.dart';
import 'negocio_repository_api.dart';
import 'negocio_repository_mock.dart';
import 'pedido_repository.dart';
import 'pedido_repository_api.dart';
import 'pedido_repository_mock.dart';
import 'producto_repository.dart';
import 'producto_repository_api.dart';
import 'producto_repository_mock.dart';
import 'ubicacion_service.dart';

/// Único lugar donde se decide qué implementación se usa.
///
/// Por defecto: la API real (base de datos en Supabase).
/// Con `flutter run --dart-define=USAR_MOCKS=true`: los datos de prueba en
/// memoria de antes (sirve para trabajar sin internet).
/// En los tests se reemplazan con `overrideWithValue(...Mock())`.
const _usarMocks = ApiConfig.usarMocks;

/// Cliente HTTP compartido: guarda el token de la sesión.
final apiClienteProvider = Provider<ApiCliente>((ref) {
  final cliente = ApiCliente(ApiConfig.url);
  ref.onDispose(cliente.cerrar);
  return cliente;
});

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => _usarMocks
      ? AuthRepositoryMock()
      : AuthRepositoryApi(ref.watch(apiClienteProvider)),
);

final negocioRepositoryProvider = Provider<NegocioRepository>(
  (ref) => _usarMocks
      ? NegocioRepositoryMock()
      : NegocioRepositoryApi(ref.watch(apiClienteProvider)),
);

final productoRepositoryProvider = Provider<ProductoRepository>(
  (ref) => _usarMocks
      ? ProductoRepositoryMock()
      : ProductoRepositoryApi(ref.watch(apiClienteProvider)),
);

final pedidoRepositoryProvider = Provider<PedidoRepository>(
  (ref) => _usarMocks
      ? PedidoRepositoryMock()
      : PedidoRepositoryApi(ref.watch(apiClienteProvider)),
);

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  if (!_usarMocks) return ChatRepositoryApi(ref.watch(apiClienteProvider));
  final repo = ChatRepositoryMock();
  ref.onDispose(repo.cerrar);
  return repo;
});

/// Servicios del dispositivo (cámara/galería y GPS). En los tests se
/// reemplazan por versiones falsas.
final imagenServiceProvider = Provider<ImagenService>(
  (ref) => ImagenServicePicker(),
);

final ubicacionServiceProvider = Provider<UbicacionService>(
  (ref) => UbicacionServiceGps(),
);
