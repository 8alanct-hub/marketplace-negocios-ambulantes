import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:marketplace_ambulante/model/auth_repository_mock.dart';
import 'package:marketplace_ambulante/model/imagen_service.dart';
import 'package:marketplace_ambulante/model/mock_usuarios.dart';
import 'package:marketplace_ambulante/model/negocio_repository_mock.dart';
import 'package:marketplace_ambulante/model/producto_repository_mock.dart';
import 'package:marketplace_ambulante/model/repository_providers.dart';
import 'package:marketplace_ambulante/model/ubicacion_service.dart';
import 'package:marketplace_ambulante/viewmodel/configuracion_negocio_viewmodel.dart';
import 'package:marketplace_ambulante/viewmodel/marketplace_viewmodel.dart';
import 'package:marketplace_ambulante/viewmodel/resultado.dart';
import 'package:marketplace_ambulante/viewmodel/sesion_viewmodel.dart';
import 'package:marketplace_ambulante/viewmodel/sign_in_viewmodel.dart';

class _ImagenFalsa implements ImagenService {
  @override
  Future<ImagenElegida?> elegir(FuenteImagen fuente) async =>
      ImagenElegida(bytes: Uint8List.fromList([9, 9, 9]), mime: 'image/png');
}

class _GpsFalso implements UbicacionService {
  @override
  Future<Coordenadas> obtenerUbicacionActual() async =>
      const Coordenadas(10.4236, -75.5478);
  @override
  Future<void> abrirAjustesApp() async {}
  @override
  Future<void> abrirAjustesUbicacion() async {}
}

/// Reproduce el caso reportado: el negocio sube su logo y el cliente
/// debe verlo en "Negocios más cercanos".
void main() {
  test('el logo que guarda el negocio aparece en el Marketplace del cliente',
      () async {
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider
            .overrideWithValue(AuthRepositoryMock(latencia: Duration.zero)),
        negocioRepositoryProvider
            .overrideWithValue(NegocioRepositoryMock(latencia: Duration.zero)),
        productoRepositoryProvider
            .overrideWithValue(ProductoRepositoryMock(latencia: Duration.zero)),
        imagenServiceProvider.overrideWithValue(_ImagenFalsa()),
        ubicacionServiceProvider.overrideWithValue(_GpsFalso()),
      ],
    );
    addTearDown(container.dispose);
    Future<void> entrar(String email) => container
        .read(signInViewModelProvider.notifier)
        .iniciarSesion(email: email, password: mockPassword);
    String? logoDelSalon() => container
        .read(marketplaceViewModelProvider)
        .value
        ?.negocios
        .firstWhere((n) => n.negocio.id == 'n_1')
        .negocio
        .logoUrl;

    // 1. El cliente abre el Marketplace ANTES (así queda en memoria).
    await entrar('cliente@test.com');
    await container.read(marketplaceViewModelProvider.future);
    expect(logoDelSalon(), isNull);
    container.read(sesionProvider.notifier).cerrar();

    // 2. El negocio sube su logo y guarda.
    await entrar('negocio@test.com');
    final s =
        await container.read(configuracionNegocioViewModelProvider.future);
    final config = container.read(configuracionNegocioViewModelProvider.notifier);
    expect(await config.elegirLogo(FuenteImagen.galeria), isA<Exito>());
    expect(
      await config.guardar(
        nombre: s.negocio.nombre,
        descripcion: s.negocio.descripcion,
        telefono: s.negocio.telefono,
        direccion: s.negocio.direccion,
      ),
      isA<Exito>(),
    );
    container.read(sesionProvider.notifier).cerrar();

    // 3. El cliente vuelve a entrar: el Marketplace se recarga con el logo.
    await entrar('cliente@test.com');
    await container.read(marketplaceViewModelProvider.future);
    expect(logoDelSalon(), startsWith('data:image/png'));
  });
}
