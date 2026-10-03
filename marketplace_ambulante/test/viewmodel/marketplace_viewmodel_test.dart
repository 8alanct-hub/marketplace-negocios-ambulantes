import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:marketplace_ambulante/model/negocio_repository_mock.dart';
import 'package:marketplace_ambulante/model/repository_providers.dart';
import 'package:marketplace_ambulante/model/ubicacion_service.dart';
import 'package:marketplace_ambulante/viewmodel/marketplace_viewmodel.dart';
import 'package:marketplace_ambulante/viewmodel/resultado.dart';

/// GPS falso. Por defecto el usuario está en el Centro de Cartagena.
class _GpsFalso implements UbicacionService {
  UbicacionException? error;
  Coordenadas ubicacion = const Coordenadas(10.4236, -75.5478);

  @override
  Future<Coordenadas> obtenerUbicacionActual() async {
    if (error != null) throw error!;
    return ubicacion;
  }

  @override
  Future<void> abrirAjustesApp() async {}

  @override
  Future<void> abrirAjustesUbicacion() async {}
}

void main() {
  late ProviderContainer container;
  late _GpsFalso gps;

  setUp(() {
    gps = _GpsFalso();
    container = ProviderContainer(
      overrides: [
        negocioRepositoryProvider
            .overrideWithValue(NegocioRepositoryMock(latencia: Duration.zero)),
        ubicacionServiceProvider.overrideWithValue(gps),
      ],
    );
  });

  tearDown(() => container.dispose());

  MarketplaceViewModel vm() =>
      container.read(marketplaceViewModelProvider.notifier);

  test('ordena los negocios del más cercano al más lejano', () async {
    final s = await container.read(marketplaceViewModelProvider.future);

    expect(s.conUbicacion, isTrue);
    expect(s.avisoUbicacion, isNull);
    final distancias = s.negocios.map((n) => n.distanciaMetros!).toList();
    expect(distancias, orderedEquals([...distancias]..sort()));
    // Desde el Centro, lo más cercano es el salón en Getsemaní.
    expect(s.negocios.first.negocio.nombre, 'Nouveau Beauty Salon');
    // Bocagrande es lo más lejano de los de prueba.
    expect(s.negocios.last.negocio.nombre, 'Frutas Doña Rosa');
  });

  test('la búsqueda ignora mayúsculas y tildes', () async {
    await container.read(marketplaceViewModelProvider.future);

    vm().buscar('PANADERIA');
    final s = container.read(marketplaceViewModelProvider).value!;
    expect(s.visibles.map((n) => n.negocio.nombre), ['Panadería El Trigal']);

    vm().buscar('arepas de huevo'); // busca también en la descripción
    expect(
      container.read(marketplaceViewModelProvider).value!.visibles,
      hasLength(1),
    );
  });

  test('sin permiso de ubicación muestra los negocios y un aviso', () async {
    gps.error = const UbicacionException(
      MotivoUbicacion.permisoDenegado,
      'Necesitamos tu ubicación',
    );
    final s = await container.read(marketplaceViewModelProvider.future);

    expect(s.negocios, isNotEmpty);
    expect(s.conUbicacion, isFalse);
    expect(s.avisoUbicacion, 'Necesitamos tu ubicación');
    expect(s.negocios.every((n) => n.distanciaMetros == null), isTrue);
  });

  test('al activar la ubicación después, se ordena y se quita el aviso',
      () async {
    gps.error = const UbicacionException(
      MotivoUbicacion.permisoDenegado,
      'Necesitamos tu ubicación',
    );
    await container.read(marketplaceViewModelProvider.future);

    gps.error = null;
    expect(await vm().reintentarUbicacion(), isA<Exito>());
    final s = container.read(marketplaceViewModelProvider).value!;
    expect(s.avisoUbicacion, isNull);
    expect(s.negocios.first.distanciaMetros, isNotNull);
  });

  test('permiso bloqueado → pide abrir ajustes', () async {
    gps.error = const UbicacionException(
      MotivoUbicacion.permisoBloqueado,
      'bloqueado',
    );
    await container.read(marketplaceViewModelProvider.future);

    final r = await vm().reintentarUbicacion();
    expect(r, isA<RequiereAjustes>());
  });
}
