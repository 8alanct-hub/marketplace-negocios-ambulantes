import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:marketplace_ambulante/model/auth_repository_mock.dart';
import 'package:marketplace_ambulante/model/mock_usuarios.dart';
import 'package:marketplace_ambulante/model/negocio_repository_mock.dart';
import 'package:marketplace_ambulante/model/pedido.dart';
import 'package:marketplace_ambulante/model/pedido_repository_mock.dart';
import 'package:marketplace_ambulante/model/repository_providers.dart';
import 'package:marketplace_ambulante/viewmodel/panel_negocio_viewmodel.dart';
import 'package:marketplace_ambulante/viewmodel/resultado.dart';
import 'package:marketplace_ambulante/viewmodel/sign_in_viewmodel.dart';

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer(
      overrides: [
        authRepositoryProvider
            .overrideWithValue(AuthRepositoryMock(latencia: Duration.zero)),
        negocioRepositoryProvider
            .overrideWithValue(NegocioRepositoryMock(latencia: Duration.zero)),
        pedidoRepositoryProvider
            .overrideWithValue(PedidoRepositoryMock(latencia: Duration.zero)),
      ],
    );
  });

  tearDown(() => container.dispose());

  PanelNegocioViewModel vm() =>
      container.read(panelNegocioViewModelProvider.notifier);

  Future<void> entrarComoNegocio() => container
      .read(signInViewModelProvider.notifier)
      .iniciarSesion(email: 'negocio@test.com', password: mockPassword);

  test('separa los pedidos en nuevos, en curso e historial', () async {
    await entrarComoNegocio();
    final s = await container.read(panelNegocioViewModelProvider.future);

    expect(s.negocio.nombre, 'Nouveau Beauty Salon');
    expect(s.nuevos.map((p) => p.id), ['1001', '1002']);
    expect(s.enCurso.map((p) => p.id), ['1003', '1004']);
    expect(s.historial.map((p) => p.id), ['1005', '1006']);
    expect(s.nombreModalidad('m_2'), 'Contraentrega');
  });

  test('aceptar un pedido nuevo lo pasa a "En curso"', () async {
    await entrarComoNegocio();
    final s = await container.read(panelNegocioViewModelProvider.future);
    final pedido = s.nuevos.first;

    expect(await vm().avanzar(pedido), isA<Exito>());

    final despues = container.read(panelNegocioViewModelProvider).value!;
    final actualizado = despues.pedidos.firstWhere((p) => p.id == pedido.id);
    expect(actualizado.estado, EstadoPedido.aceptado);
    expect(despues.nuevos, hasLength(1));
    expect(despues.pedidoEnProceso, isNull);
  });

  test('rechazar un pedido nuevo lo manda al historial', () async {
    await entrarComoNegocio();
    final s = await container.read(panelNegocioViewModelProvider.future);

    expect(
      await vm().rechazar(s.nuevos.last, 'Producto o servicio agotado'),
      isA<Exito>(),
    );
    final despues = container.read(panelNegocioViewModelProvider).value!;
    final rechazado = despues.historial.firstWhere((p) => p.id == '1002');
    expect(rechazado.estado, EstadoPedido.rechazado);
    expect(rechazado.motivo, 'Producto o servicio agotado');
  });

  test('un pedido entregado ya no avanza', () async {
    await entrarComoNegocio();
    final s = await container.read(panelNegocioViewModelProvider.future);
    final entregado =
        s.pedidos.firstWhere((p) => p.estado == EstadoPedido.entregado);

    expect(await vm().avanzar(entregado), isA<Fallo>());
  });

  test('no se puede rechazar un pedido que ya está en curso', () async {
    await entrarComoNegocio();
    final s = await container.read(panelNegocioViewModelProvider.future);

    expect(await vm().rechazar(s.enCurso.first, 'Otro motivo'), isA<Fallo>());
  });

  test('cancelar un pedido en curso con motivo → historial', () async {
    await entrarComoNegocio();
    final s = await container.read(panelNegocioViewModelProvider.future);
    final enCurso = s.enCurso.first;

    expect(
      await vm().cancelar(enCurso, 'El cliente no responde'),
      isA<Exito>(),
    );
    final despues = container.read(panelNegocioViewModelProvider).value!;
    final cancelado = despues.pedidos.firstWhere((p) => p.id == enCurso.id);
    expect(cancelado.estado, EstadoPedido.cancelado);
    expect(cancelado.motivo, 'El cliente no responde');
    expect(despues.historial, contains(cancelado));
  });

  test('cancelar o rechazar sin motivo no se permite', () async {
    await entrarComoNegocio();
    final s = await container.read(panelNegocioViewModelProvider.future);

    expect(await vm().cancelar(s.enCurso.first, '   '), isA<Fallo>());
    expect(await vm().rechazar(s.nuevos.first, ''), isA<Fallo>());
  });

  test('un pedido nuevo se rechaza, no se cancela', () async {
    await entrarComoNegocio();
    final s = await container.read(panelNegocioViewModelProvider.future);

    expect(await vm().cancelar(s.nuevos.first, 'Motivo'), isA<Fallo>());
  });
}
