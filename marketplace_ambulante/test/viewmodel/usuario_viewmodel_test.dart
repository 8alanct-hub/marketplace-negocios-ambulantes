import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:marketplace_ambulante/model/auth_repository_mock.dart';
import 'package:marketplace_ambulante/model/chat_repository_mock.dart';
import 'package:marketplace_ambulante/model/mock_catalogos.dart';
import 'package:marketplace_ambulante/model/mock_usuarios.dart';
import 'package:marketplace_ambulante/model/negocio_repository_mock.dart';
import 'package:marketplace_ambulante/model/pedido.dart';
import 'package:marketplace_ambulante/model/pedido_repository_mock.dart';
import 'package:marketplace_ambulante/model/producto.dart';
import 'package:marketplace_ambulante/model/producto_repository_mock.dart';
import 'package:marketplace_ambulante/model/repository_providers.dart';
import 'package:marketplace_ambulante/viewmodel/carrito_viewmodel.dart';
import 'package:marketplace_ambulante/viewmodel/chat_viewmodel.dart';
import 'package:marketplace_ambulante/viewmodel/confirmar_pedido_viewmodel.dart';
import 'package:marketplace_ambulante/viewmodel/mis_pedidos_viewmodel.dart';
import 'package:marketplace_ambulante/viewmodel/resultado.dart';
import 'package:marketplace_ambulante/viewmodel/sign_in_viewmodel.dart';

Producto _producto(String id) => mockProductos.firstWhere((p) => p.id == id);

void main() {
  late ProviderContainer container;
  late NegocioRepositoryMock negocios;

  setUp(() {
    negocios = NegocioRepositoryMock(latencia: Duration.zero);
    container = ProviderContainer(
      overrides: [
        authRepositoryProvider
            .overrideWithValue(AuthRepositoryMock(latencia: Duration.zero)),
        negocioRepositoryProvider.overrideWithValue(negocios),
        productoRepositoryProvider
            .overrideWithValue(ProductoRepositoryMock(latencia: Duration.zero)),
        pedidoRepositoryProvider
            .overrideWithValue(PedidoRepositoryMock(latencia: Duration.zero)),
        chatRepositoryProvider.overrideWithValue(
          ChatRepositoryMock(
            latencia: Duration.zero,
            esperaRespuesta: const Duration(milliseconds: 10),
          ),
        ),
      ],
    );
  });

  tearDown(() => container.dispose());

  CarritoViewModel carrito() => container.read(carritoProvider.notifier);
  Carrito estadoCarrito() => container.read(carritoProvider);

  Future<void> entrarComoCliente() => container
      .read(signInViewModelProvider.notifier)
      .iniciarSesion(email: 'cliente@test.com', password: mockPassword);

  group('Carrito', () {
    test('suma, resta y calcula el total', () {
      final arepa = _producto('p_3'); // $5.000
      final queso = _producto('p_4'); // $4.000
      carrito()
        ..agregar(arepa)
        ..agregar(arepa)
        ..agregar(queso);

      expect(estadoCarrito().cantidadTotal, 3);
      expect(estadoCarrito().total, 14000);

      carrito().quitar(arepa);
      expect(estadoCarrito().cantidadDe('p_3'), 1);
      carrito()
        ..quitar(arepa)
        ..quitar(queso);
      expect(estadoCarrito().vacio, isTrue);
      expect(estadoCarrito().negocioId, isNull);
    });

    test('no agrega agotados, ni no disponibles, ni más que el stock', () {
      carrito().agregar(_producto('p_5')); // agotado
      carrito().agregar(_producto('p_9')); // no disponible
      expect(estadoCarrito().vacio, isTrue);

      final sombrero = _producto('p_11'); // stock 2
      for (var i = 0; i < 5; i++) {
        carrito().agregar(sombrero);
      }
      expect(estadoCarrito().cantidadDe('p_11'), 2);
    });

    test('un pedido es de un solo negocio', () {
      carrito().agregar(_producto('p_3')); // Arepas (n_2)
      expect(estadoCarrito().esDeOtroNegocio('n_4'), isTrue);

      carrito().agregar(_producto('p_8')); // Panadería (n_4)
      expect(estadoCarrito().negocioId, 'n_4');
      expect(estadoCarrito().cantidadDe('p_3'), 0);
    });
  });

  group('Pedido del usuario', () {
    test('confirmar crea el pedido pendiente y vacía el carrito', () async {
      await entrarComoCliente();
      carrito()
        ..agregar(_producto('p_3'))
        ..agregar(_producto('p_3'));
      final arepas = (await negocios.obtenerPorId('n_2'))!;

      final pedido = await container
          .read(confirmarPedidoViewModelProvider.notifier)
          .confirmar(negocio: arepas, modalidadPagoId: 'm_2');

      expect(pedido, isNotNull);
      expect(pedido!.estado, EstadoPedido.pendiente);
      expect(pedido.total, 10000);
      expect(pedido.negocioNombre, 'Arepas La Esquina');
      expect(pedido.clienteNombre, 'Carla Gómez');
      expect(estadoCarrito().vacio, isTrue);

      final mis = await container.read(misPedidosViewModelProvider.future);
      expect(mis.pedidos.first.id, pedido.id); // el más reciente primero
    });

    test('con el carrito vacío no se crea el pedido', () async {
      await entrarComoCliente();
      final arepas = (await negocios.obtenerPorId('n_2'))!;

      final pedido = await container
          .read(confirmarPedidoViewModelProvider.notifier)
          .confirmar(negocio: arepas, modalidadPagoId: 'm_2');
      expect(pedido, isNull);
      expect(container.read(confirmarPedidoViewModelProvider).error, isNotNull);
    });

    test('el cliente cancela un pedido pendiente, pero no uno en curso',
        () async {
      await entrarComoCliente();
      final s = await container.read(misPedidosViewModelProvider.future);
      final vm = container.read(misPedidosViewModelProvider.notifier);

      final pendiente = s.pedidos.firstWhere((p) => p.estado.esNuevo);
      expect(await vm.cancelar(pendiente), isA<Exito>());
      final despues = container.read(misPedidosViewModelProvider).value!;
      final cancelado = despues.pedidos.firstWhere((p) => p.id == pendiente.id);
      expect(cancelado.estado, EstadoPedido.cancelado);
      expect(cancelado.motivo, 'Cancelado por el cliente');

      final enCurso = s.pedidos.firstWhere((p) => p.estado.enCurso);
      expect(await vm.cancelar(enCurso), isA<Fallo>());
    });
  });

  group('Chat', () {
    test('enviar un mensaje y recibir la respuesta del negocio', () async {
      await entrarComoCliente();
      final conversacion =
          await container.read(conversacionConNegocioProvider('n_2').future);
      expect(conversacion.negocioNombre, 'Arepas La Esquina');

      // Mantiene vivo el Stream de mensajes durante el test.
      final sub = container.listen(
        mensajesProvider(conversacion.id),
        (_, _) {},
      );
      addTearDown(sub.close);

      final r = await container
          .read(chatViewModelProvider.notifier)
          .enviar(conversacion.id, '  Hola, ¿tienen arepas?  ');
      expect(r, isA<Exito>());

      // Espera la respuesta automática del negocio (mock).
      await Future<void>.delayed(const Duration(milliseconds: 50));
      final mensajes = container.read(mensajesProvider(conversacion.id)).value!;
      expect(mensajes.first.texto, 'Hola, ¿tienen arepas?');
      expect(mensajes.first.remitenteId, 'u_1');
      expect(mensajes, hasLength(2));
      expect(mensajes.last.remitenteId, 'n_2');

      final chats = await container.read(conversacionesProvider.future);
      expect(chats.single.ultimoMensaje, mensajes.last.texto);
    });

    test('abrir dos veces el chat con el mismo negocio no lo duplica',
        () async {
      await entrarComoCliente();
      final a = await container.read(conversacionConNegocioProvider('n_3').future);
      container.invalidate(conversacionConNegocioProvider('n_3'));
      final b = await container.read(conversacionConNegocioProvider('n_3').future);
      expect(a.id, b.id);
    });
  });
}
