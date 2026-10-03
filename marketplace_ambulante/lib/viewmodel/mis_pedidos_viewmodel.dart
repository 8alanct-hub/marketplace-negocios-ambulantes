import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../model/pedido.dart';
import '../model/pedido_repository.dart';
import '../model/repository_providers.dart';
import 'configuracion_negocio_viewmodel.dart' show CargaException;
import 'resultado.dart';
import 'seleccion_rol_viewmodel.dart' show errorSinSesion;
import 'sesion_viewmodel.dart';

class MisPedidosState {
  const MisPedidosState({
    required this.pedidos,
    required this.nombresModalidad,
    this.pedidoEnProceso,
  });

  /// Los más recientes primero.
  final List<Pedido> pedidos;
  final Map<String, String> nombresModalidad;
  final String? pedidoEnProceso;

  String nombreModalidad(String id) => nombresModalidad[id] ?? '—';

  MisPedidosState copyWith({
    List<Pedido>? pedidos,
    String? pedidoEnProceso,
    bool limpiarPedidoEnProceso = false,
  }) =>
      MisPedidosState(
        pedidos: pedidos ?? this.pedidos,
        nombresModalidad: nombresModalidad,
        pedidoEnProceso: limpiarPedidoEnProceso
            ? null
            : pedidoEnProceso ?? this.pedidoEnProceso,
      );
}

/// ViewModel de "Mis pedidos" (vista del usuario).
class MisPedidosViewModel extends AsyncNotifier<MisPedidosState> {
  @override
  Future<MisPedidosState> build() async {
    final sesion = ref.watch(sesionProvider);
    if (sesion == null) throw const CargaException(errorSinSesion);

    final (pedidos, modalidades) = await (
      ref.read(pedidoRepositoryProvider).obtenerPorUsuario(sesion.id),
      ref.read(negocioRepositoryProvider).obtenerModalidadesPago(),
    ).wait;

    return MisPedidosState(
      pedidos: pedidos,
      nombresModalidad: {for (final m in modalidades) m.id: m.nombre},
    );
  }

  MisPedidosState get _actual => state.requireValue;

  Future<void> recargar() async {
    ref.invalidateSelf();
    await future;
  }

  /// Solo se puede cancelar mientras el negocio no haya respondido.
  Future<Resultado> cancelar(Pedido pedido) async {
    if (_actual.pedidoEnProceso != null) {
      return const Fallo('Espera a que termine la acción anterior.');
    }
    state = AsyncData(_actual.copyWith(pedidoEnProceso: pedido.id));
    try {
      final cancelado =
          await ref.read(pedidoRepositoryProvider).cancelarPorCliente(pedido.id);
      if (!ref.mounted) return const Exito();
      state = AsyncData(_actual.copyWith(
        pedidos: [
          for (final p in _actual.pedidos) p.id == pedido.id ? cancelado : p,
        ],
        limpiarPedidoEnProceso: true,
      ));
      return const Exito();
    } on PedidoException catch (e) {
      if (ref.mounted) {
        state = AsyncData(_actual.copyWith(limpiarPedidoEnProceso: true));
      }
      return Fallo(e.mensaje);
    } catch (_) {
      if (ref.mounted) {
        state = AsyncData(_actual.copyWith(limpiarPedidoEnProceso: true));
      }
      return const Fallo('No se pudo cancelar el pedido. Intenta de nuevo.');
    }
  }
}

final misPedidosViewModelProvider =
    AsyncNotifierProvider<MisPedidosViewModel, MisPedidosState>(
  MisPedidosViewModel.new,
);
