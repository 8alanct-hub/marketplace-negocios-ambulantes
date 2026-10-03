import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_repository.dart';
import 'auth_repository_mock.dart';
import 'chat_repository.dart';
import 'chat_repository_mock.dart';
import 'imagen_service.dart';
import 'negocio_repository.dart';
import 'negocio_repository_mock.dart';
import 'pedido_repository.dart';
import 'pedido_repository_mock.dart';
import 'producto_repository.dart';
import 'producto_repository_mock.dart';
import 'ubicacion_service.dart';

/// Único lugar donde se decide qué implementación se usa.
/// Para conectar el backend real: devolver AuthRepositoryApi() aquí.
final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepositoryMock(),
);

final negocioRepositoryProvider = Provider<NegocioRepository>(
  (ref) => NegocioRepositoryMock(),
);

final productoRepositoryProvider = Provider<ProductoRepository>(
  (ref) => ProductoRepositoryMock(),
);

final pedidoRepositoryProvider = Provider<PedidoRepository>(
  (ref) => PedidoRepositoryMock(),
);

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
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
