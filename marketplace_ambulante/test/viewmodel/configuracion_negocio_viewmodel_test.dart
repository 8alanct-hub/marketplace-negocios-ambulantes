import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:marketplace_ambulante/model/auth_repository_mock.dart';
import 'package:marketplace_ambulante/model/imagen_service.dart';
import 'package:marketplace_ambulante/model/mock_usuarios.dart';
import 'package:marketplace_ambulante/model/negocio.dart';
import 'package:marketplace_ambulante/model/negocio_repository_mock.dart';
import 'package:marketplace_ambulante/model/producto_repository_mock.dart';
import 'package:marketplace_ambulante/model/repository_providers.dart';
import 'package:marketplace_ambulante/model/ubicacion_service.dart';
import 'package:marketplace_ambulante/viewmodel/configuracion_negocio_viewmodel.dart';
import 'package:marketplace_ambulante/viewmodel/resultado.dart';
import 'package:marketplace_ambulante/viewmodel/sign_in_viewmodel.dart';
import 'package:marketplace_ambulante/viewmodel/sign_up_viewmodel.dart';
import 'package:marketplace_ambulante/viewmodel/tipo_negocio_viewmodel.dart';

/// Cámara/galería falsa: siempre devuelve una imagen pequeña.
class _ImagenFalsa implements ImagenService {
  @override
  Future<ImagenElegida?> elegir(FuenteImagen fuente) async => ImagenElegida(
        bytes: Uint8List.fromList([1, 2, 3]),
        mime: 'image/png',
      );
}

/// GPS falso: devuelve una ubicación fija o lanza el error indicado.
class _GpsFalso implements UbicacionService {
  UbicacionException? error;

  @override
  Future<Coordenadas> obtenerUbicacionActual() async {
    if (error != null) throw error!;
    return const Coordenadas(4.6097, -74.0817);
  }

  @override
  Future<void> abrirAjustesApp() async {}

  @override
  Future<void> abrirAjustesUbicacion() async {}
}

void main() {
  late ProviderContainer container;
  late _GpsFalso gps;
  late NegocioRepositoryMock negocios;

  setUp(() {
    gps = _GpsFalso();
    negocios = NegocioRepositoryMock(latencia: Duration.zero);
    container = ProviderContainer(
      overrides: [
        authRepositoryProvider
            .overrideWithValue(AuthRepositoryMock(latencia: Duration.zero)),
        negocioRepositoryProvider.overrideWithValue(negocios),
        productoRepositoryProvider
            .overrideWithValue(ProductoRepositoryMock(latencia: Duration.zero)),
        imagenServiceProvider.overrideWithValue(_ImagenFalsa()),
        ubicacionServiceProvider.overrideWithValue(gps),
      ],
    );
  });

  tearDown(() => container.dispose());

  ConfiguracionNegocioViewModel vm() =>
      container.read(configuracionNegocioViewModelProvider.notifier);

  Future<void> entrarComo(String email, String password) => container
      .read(signInViewModelProvider.notifier)
      .iniciarSesion(email: email, password: password);

  test('carga los datos del negocio de prueba', () async {
    await entrarComo('negocio@test.com', mockPassword);
    final s = await container.read(configuracionNegocioViewModelProvider.future);

    expect(s.negocio.nombre, 'Nouveau Beauty Salon');
    expect(s.modalidades, hasLength(2));
    expect(s.modalidadesElegidas, {'m_1'});
    expect(s.productos, hasLength(2));
    expect(s.categorias, isNotEmpty);
  });

  test('no deja guardar sin formas de pago', () async {
    await entrarComo('negocio@test.com', mockPassword);
    await container.read(configuracionNegocioViewModelProvider.future);

    vm().alternarModalidad('m_1'); // la desmarca
    final r = await vm().guardar(
      nombre: 'Salón Nora',
      descripcion: '',
      telefono: '3109876543',
      direccion: 'Calle 1',
    );
    expect(r, isA<Fallo>());
  });

  test('ubicación + portada + guardar → queda guardado', () async {
    await entrarComo('negocio@test.com', mockPassword);
    await container.read(configuracionNegocioViewModelProvider.future);

    expect(await vm().actualizarUbicacion(), isA<Exito>());
    expect(await vm().elegirPortada(FuenteImagen.galeria), isA<Exito>());
    vm().alternarModalidad('m_2'); // agrega contraentrega

    final r = await vm().guardar(
      nombre: 'Salón Nora',
      descripcion: 'Uñas y pestañas',
      telefono: '3109876543',
      direccion: 'Calle 1 # 2-3',
    );
    expect(r, isA<Exito>());

    final guardado = await negocios.obtenerPorPropietario('u_2');
    expect(guardado?.nombre, 'Salón Nora');
    expect(guardado?.latitud, 4.6097);
    expect(guardado?.bannerUrl, startsWith('data:image/png'));
    expect(await negocios.obtenerModalidadesDelNegocio('n_1'), {'m_1', 'm_2'});
  });

  test('permiso de ubicación bloqueado → pide abrir ajustes de la app', () async {
    await entrarComo('negocio@test.com', mockPassword);
    await container.read(configuracionNegocioViewModelProvider.future);

    gps.error = const UbicacionException(
      MotivoUbicacion.permisoBloqueado,
      'bloqueado',
    );
    final r = await vm().actualizarUbicacion();
    expect(r, isA<RequiereAjustes>());
    expect((r as RequiereAjustes).destino, AjustesDestino.app);
    expect(
      container.read(configuracionNegocioViewModelProvider).value?.ubicando,
      isFalse,
    );
  });

  test('agregar producto lo suma a la lista', () async {
    await entrarComo('negocio@test.com', mockPassword);
    await container.read(configuracionNegocioViewModelProvider.future);

    final r = await vm().guardarProducto(
      nombre: 'Uñas acrílicas',
      descripcion: '',
      categoriaId: 'c_3',
      precio: 60000,
      stock: 5,
      disponible: true,
    );
    expect(r, isA<Exito>());
    final s = container.read(configuracionNegocioViewModelProvider).value!;
    expect(s.productos.map((p) => p.nombre), contains('Uñas acrílicas'));
  });

  test('negocio ambulante nuevo: sin ubicación no deja guardar', () async {
    await container.read(signUpViewModelProvider.notifier).registrar(
          nombre: 'Luis',
          apellido: 'Mora',
          telefono: '3015556677',
          email: 'luis@test.com',
          password: 'Clave123',
        );
    await entrarComo('luis@test.com', 'Clave123');
    await container
        .read(tipoNegocioViewModelProvider.notifier)
        .elegirTipo(TipoNegocio.ambulante);

    final s = await container.read(configuracionNegocioViewModelProvider.future);
    expect(s.negocio.tipo, TipoNegocio.ambulante);
    expect(s.negocio.telefono, '3015556677'); // se propone el del usuario

    vm().alternarModalidad('m_2');
    final r = await vm().guardar(
      nombre: 'Arepas Luis',
      descripcion: '',
      telefono: '3015556677',
      direccion: '',
    );
    expect(r, isA<Fallo>());
  });

  test('cambiar de fijo a ambulante y guardar', () async {
    await entrarComo('negocio@test.com', mockPassword);
    await container.read(configuracionNegocioViewModelProvider.future);

    vm().cambiarTipo(TipoNegocio.ambulante);
    final s = container.read(configuracionNegocioViewModelProvider).value!;
    expect(s.negocio.tipo, TipoNegocio.ambulante);
    expect(s.negocioGuardado.tipo, TipoNegocio.fijo); // aún no se guarda

    final r = await vm().guardar(
      nombre: s.negocio.nombre,
      descripcion: s.negocio.descripcion,
      telefono: s.negocio.telefono,
      direccion: '',
    );
    expect(r, isA<Exito>());
    final guardado = await negocios.obtenerPorPropietario('u_2');
    expect(guardado?.tipo, TipoNegocio.ambulante);
    expect(guardado?.direccion, ''); // el ambulante no tiene dirección
  });

  test('detecta cambios sin guardar', () async {
    await entrarComo('negocio@test.com', mockPassword);
    final s = await container.read(configuracionNegocioViewModelProvider.future);
    final n = s.negocio;

    bool hayCambios({String? nombre}) => container
        .read(configuracionNegocioViewModelProvider)
        .value!
        .hayCambios(
          nombre: nombre ?? n.nombre,
          descripcion: n.descripcion,
          telefono: n.telefono,
          direccion: n.direccion,
        );

    expect(hayCambios(), isFalse); // recién cargado
    expect(hayCambios(nombre: 'Otro nombre'), isTrue); // cambió un texto

    vm().alternarModalidad('m_2');
    expect(hayCambios(), isTrue); // cambió una forma de pago
    vm().alternarModalidad('m_2');
    expect(hayCambios(), isFalse); // volvió a como estaba

    vm().cambiarTipo(TipoNegocio.ambulante);
    expect(hayCambios(), isTrue); // cambió el tipo

    final r = await vm().guardar(
      nombre: n.nombre,
      descripcion: n.descripcion,
      telefono: n.telefono,
      direccion: n.direccion,
    );
    expect(r, isA<Exito>());
    expect(hayCambios(), isFalse); // después de guardar ya no hay cambios
  });
}
