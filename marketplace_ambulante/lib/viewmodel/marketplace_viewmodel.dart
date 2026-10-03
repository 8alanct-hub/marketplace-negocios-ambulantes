import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/utils/distancia.dart';
import '../model/negocio.dart';
import '../model/repository_providers.dart';
import '../model/ubicacion_service.dart';
import 'marketplace_state.dart';
import 'resultado.dart';
import 'sesion_viewmodel.dart';

/// ViewModel del "Marketplace": negocios ordenados por cercanía.
class MarketplaceViewModel extends AsyncNotifier<MarketplaceState> {
  @override
  Future<MarketplaceState> build() async {
    // Depende de la sesión: al cerrar e iniciar sesión se vuelve a cargar
    // (si no, se seguiría viendo la lista de la primera vez).
    ref.watch(sesionProvider);

    final negocios =
        await ref.read(negocioRepositoryProvider).obtenerNegociosPublicados();

    // Si no hay ubicación, igual se muestran los negocios (sin distancia)
    // con un aviso para activarla.
    Coordenadas? ubicacion;
    String? aviso;
    try {
      ubicacion =
          await ref.read(ubicacionServiceProvider).obtenerUbicacionActual();
    } on UbicacionException catch (e) {
      aviso = e.mensaje;
    } catch (_) {
      aviso = 'No pudimos obtener tu ubicación.';
    }

    return MarketplaceState(
      negocios: ordenarPorCercania(negocios, ubicacion),
      ubicacionUsuario: ubicacion,
      avisoUbicacion: aviso,
    );
  }

  /// Calcula la distancia de cada negocio y los ordena (más cerca primero).
  /// Sin [ubicacion], los ordena por nombre.
  static List<NegocioCercano> ordenarPorCercania(
    List<Negocio> negocios,
    Coordenadas? ubicacion,
  ) {
    final lista = [
      for (final n in negocios)
        NegocioCercano(
          n,
          ubicacion == null || !n.tieneUbicacion
              ? null
              : Distancia.metrosEntre(
                  ubicacion.latitud,
                  ubicacion.longitud,
                  n.latitud!,
                  n.longitud!,
                ),
        ),
    ];
    lista.sort((a, b) {
      final da = a.distanciaMetros, db = b.distanciaMetros;
      if (da != null && db != null) return da.compareTo(db);
      if (da != null) return -1;
      if (db != null) return 1;
      return a.negocio.nombre.compareTo(b.negocio.nombre);
    });
    return lista;
  }

  MarketplaceState get _actual => state.requireValue;

  void buscar(String texto) =>
      state = AsyncData(_actual.copyWith(busqueda: texto));

  Future<void> recargar() async {
    ref.invalidateSelf();
    await future;
  }

  /// Botón "Activar ubicación" del aviso.
  Future<Resultado> reintentarUbicacion() async {
    if (_actual.ubicando) return const Exito();
    state = AsyncData(_actual.copyWith(ubicando: true));
    try {
      final c =
          await ref.read(ubicacionServiceProvider).obtenerUbicacionActual();
      if (!ref.mounted) return const Exito();
      state = AsyncData(_actual.copyWith(
        negocios: ordenarPorCercania(
          [for (final n in _actual.negocios) n.negocio],
          c,
        ),
        ubicacionUsuario: c,
        limpiarAviso: true,
        ubicando: false,
      ));
      return const Exito();
    } on UbicacionException catch (e) {
      if (ref.mounted) state = AsyncData(_actual.copyWith(ubicando: false));
      return resultadoDeUbicacion(e);
    } catch (_) {
      if (ref.mounted) state = AsyncData(_actual.copyWith(ubicando: false));
      return const Fallo('No pudimos obtener tu ubicación.');
    }
  }

  Future<void> abrirAjustes(AjustesDestino destino) =>
      abrirAjustesDispositivo(ref.read(ubicacionServiceProvider), destino);
}

final marketplaceViewModelProvider =
    AsyncNotifierProvider<MarketplaceViewModel, MarketplaceState>(
  MarketplaceViewModel.new,
);
