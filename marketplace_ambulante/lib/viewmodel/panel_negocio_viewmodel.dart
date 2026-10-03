import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../model/pedido.dart';
import '../model/pedido_repository.dart';
import '../model/repository_providers.dart';
import '../model/ubicacion_service.dart';
import 'configuracion_negocio_viewmodel.dart' show CargaException;
import 'panel_negocio_state.dart';
import 'resultado.dart';
import 'seleccion_rol_viewmodel.dart' show errorSinSesion;
import 'sesion_viewmodel.dart';

/// ViewModel del "Panel del negocio": recibe pedidos y cambia su estado.
class PanelNegocioViewModel extends AsyncNotifier<PanelNegocioState> {
  @override
  Future<PanelNegocioState> build() async {
    final sesion = ref.watch(sesionProvider);
    if (sesion == null) throw const CargaException(errorSinSesion);

    final negocios = ref.read(negocioRepositoryProvider);
    final negocio = await negocios.obtenerPorPropietario(sesion.id);
    if (negocio == null) {
      throw const CargaException('Aún no has creado tu negocio.');
    }

    final (pedidos, modalidades) = await (
      ref.read(pedidoRepositoryProvider).obtenerPorNegocio(negocio.id),
      negocios.obtenerModalidadesPago(),
    ).wait;

    return PanelNegocioState(
      negocio: negocio,
      pedidos: pedidos,
      nombresModalidad: {for (final m in modalidades) m.id: m.nombre},
    );
  }

  PanelNegocioState get _actual => state.requireValue;

  void _emitir(PanelNegocioState nuevo) => state = AsyncData(nuevo);

  /// Vuelve a cargar todo (deslizar hacia abajo para actualizar).
  Future<void> recargar() async {
    ref.invalidateSelf();
    await future;
  }

  /// Aceptar → En preparación → Listo → Entregado.
  Future<Resultado> avanzar(Pedido pedido) {
    final siguiente = pedido.estado.siguiente;
    if (siguiente == null) {
      return Future.value(const Fallo('Este pedido ya terminó.'));
    }
    return _cambiarEstado(pedido, siguiente);
  }

  /// Pedido nuevo que el negocio no acepta.
  Future<Resultado> rechazar(Pedido pedido, String motivo) =>
      _cambiarEstado(pedido, EstadoPedido.rechazado, motivo: motivo);

  /// Pedido en curso que el negocio ya no puede completar.
  Future<Resultado> cancelar(Pedido pedido, String motivo) =>
      _cambiarEstado(pedido, EstadoPedido.cancelado, motivo: motivo);

  Future<Resultado> _cambiarEstado(
    Pedido pedido,
    EstadoPedido nuevo, {
    String? motivo,
  }) async {
    if (motivo != null && motivo.trim().isEmpty) {
      return const Fallo('Indica el motivo.');
    }
    if (_actual.pedidoEnProceso != null) {
      return const Fallo('Espera a que termine la acción anterior.');
    }
    _emitir(_actual.copyWith(pedidoEnProceso: pedido.id));
    try {
      final actualizado = await ref
          .read(pedidoRepositoryProvider)
          .cambiarEstado(pedido.id, nuevo, motivo: motivo);
      if (!ref.mounted) return const Exito();
      _emitir(_actual.copyWith(
        pedidos: [
          for (final p in _actual.pedidos) p.id == pedido.id ? actualizado : p,
        ],
        limpiarPedidoEnProceso: true,
      ));
      return const Exito();
    } on PedidoException catch (e) {
      if (ref.mounted) {
        _emitir(_actual.copyWith(limpiarPedidoEnProceso: true));
      }
      return Fallo(e.mensaje);
    } catch (_) {
      if (ref.mounted) {
        _emitir(_actual.copyWith(limpiarPedidoEnProceso: true));
      }
      return const Fallo('No se pudo actualizar el pedido. Intenta de nuevo.');
    }
  }

  /// Para negocios ambulantes: toma el GPS y lo guarda al momento.
  Future<Resultado> actualizarUbicacion() async {
    if (_actual.ubicando) return const Exito();
    _emitir(_actual.copyWith(ubicando: true));
    try {
      final c =
          await ref.read(ubicacionServiceProvider).obtenerUbicacionActual();
      final guardado =
          await ref.read(negocioRepositoryProvider).actualizarNegocio(
                _actual.negocio.copyWith(
                  latitud: c.latitud,
                  longitud: c.longitud,
                  ubicacionActualizada: DateTime.now(),
                ),
              );
      if (!ref.mounted) return const Exito();
      _emitir(_actual.copyWith(negocio: guardado, ubicando: false));
      return const Exito();
    } on UbicacionException catch (e) {
      if (ref.mounted) _emitir(_actual.copyWith(ubicando: false));
      return resultadoDeUbicacion(e);
    } catch (_) {
      if (ref.mounted) _emitir(_actual.copyWith(ubicando: false));
      return const Fallo('No pudimos actualizar tu ubicación.');
    }
  }

  Future<void> abrirAjustes(AjustesDestino destino) =>
      abrirAjustesDispositivo(ref.read(ubicacionServiceProvider), destino);
}

final panelNegocioViewModelProvider =
    AsyncNotifierProvider<PanelNegocioViewModel, PanelNegocioState>(
  PanelNegocioViewModel.new,
);
