import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/utils/distancia.dart';
import '../model/modalidad_pago.dart';
import '../model/negocio.dart';
import '../model/producto.dart';
import '../model/repository_providers.dart';
import 'configuracion_negocio_viewmodel.dart' show CargaException;
import 'marketplace_viewmodel.dart';

/// Todo lo que muestra la página pública de un negocio.
class PaginaNegocioDatos {
  const PaginaNegocioDatos({
    required this.negocio,
    required this.productos,
    required this.modalidades,
    required this.nombresCategoria,
    this.distanciaMetros,
  });

  final Negocio negocio;
  final List<Producto> productos;

  /// Formas de pago que ESTE negocio acepta.
  final List<ModalidadPago> modalidades;

  /// id de categoría → nombre.
  final Map<String, String> nombresCategoria;

  /// Distancia al usuario (null si no se conoce su ubicación).
  final double? distanciaMetros;
}

/// Carga la página de un negocio por su id.
///
/// Es un FutureProvider ".family": hay uno por cada negocio que se abre.
/// ".autoDispose": al salir de la página se libera, y al volver se carga de
/// nuevo (así se ven los cambios que haya hecho el negocio).
final paginaNegocioProvider =
    FutureProvider.autoDispose.family<PaginaNegocioDatos, String>(
  (ref, negocioId) async {
    final negocios = ref.read(negocioRepositoryProvider);
    final productos = ref.read(productoRepositoryProvider);

    final negocio = await negocios.obtenerPorId(negocioId);
    if (negocio == null) {
      throw const CargaException('Este negocio ya no está disponible.');
    }

    final (lista, todas, aceptadas, categorias) = await (
      productos.obtenerPorNegocio(negocioId),
      negocios.obtenerModalidadesPago(),
      negocios.obtenerModalidadesDelNegocio(negocioId),
      productos.obtenerCategorias(),
    ).wait;

    // Si el Marketplace ya conoce la ubicación del usuario, se reutiliza.
    final ubicacion =
        ref.read(marketplaceViewModelProvider).value?.ubicacionUsuario;
    final distancia = ubicacion == null || !negocio.tieneUbicacion
        ? null
        : Distancia.metrosEntre(
            ubicacion.latitud,
            ubicacion.longitud,
            negocio.latitud!,
            negocio.longitud!,
          );

    return PaginaNegocioDatos(
      negocio: negocio,
      productos: lista,
      modalidades: todas.where((m) => aceptadas.contains(m.id)).toList(),
      nombresCategoria: {for (final c in categorias) c.id: c.nombre},
      distanciaMetros: distancia,
    );
  },
);
