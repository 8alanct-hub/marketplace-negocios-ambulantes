import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../services/api_service.dart';
import 'auth_repository.dart';
import 'auth_repository_api.dart';
import 'chat_repository.dart';
import 'chat_repository_mock.dart';
import 'imagen_service.dart';
import 'negocio_repository.dart';
import 'negocio_repository_api.dart';
import 'negocio_repository_mock.dart';
import 'pedido_repository.dart';
import 'pedido_repository_mock.dart';
import 'producto_repository.dart';
import 'producto_repository_api.dart';
import 'ubicacion_service.dart';

final secureStorageProvider = Provider<FlutterSecureStorage>(
  (ref) => const FlutterSecureStorage(),
);

final apiServiceProvider = Provider<ApiService>((ref) {
  final api = ApiService(storage: ref.watch(secureStorageProvider));

  ref.onDispose(api.close);

  return api;
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryApi(api: ref.watch(apiServiceProvider));
});

final negocioRepositoryProvider = Provider<NegocioRepository>((ref) {
  return NegocioRepositoryApi(
    api: ref.watch(apiServiceProvider),
    fallback: NegocioRepositoryMock(),
  );
});

final productoRepositoryProvider = Provider<ProductoRepository>((ref) {
  return ProductoRepositoryApi(api: ref.watch(apiServiceProvider));
});

final pedidoRepositoryProvider = Provider<PedidoRepository>(
  (ref) => PedidoRepositoryMock(),
);

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  final repo = ChatRepositoryMock();
  ref.onDispose(repo.cerrar);
  return repo;
});

final imagenServiceProvider = Provider<ImagenService>(
  (ref) => ImagenServicePicker(),
);

final ubicacionServiceProvider = Provider<UbicacionService>(
  (ref) => UbicacionServiceGps(),
);
