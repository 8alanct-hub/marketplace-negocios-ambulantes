import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../model/imagen_service.dart';
import '../model/negocio.dart';
import '../model/negocio_repository.dart';
import '../model/producto.dart';
import '../model/producto_repository.dart';
import '../model/repository_providers.dart';
import '../model/ubicacion_service.dart';
import 'configuracion_negocio_state.dart';
import 'resultado.dart';
import 'seleccion_rol_viewmodel.dart' show errorSinSesion;
import 'sesion_viewmodel.dart';

/// Error al cargar la pantalla (se muestra con un botón "Reintentar").
class CargaException implements Exception {
  const CargaException(this.mensaje);
  final String mensaje;

  @override
  String toString() => mensaje;
}

/// ViewModel de "Configuración de negocio".
///
/// Es un AsyncNotifier porque primero tiene que CARGAR datos (negocio,
/// formas de pago, categorías y productos). Mientras carga, la View muestra
/// un indicador; si falla, un mensaje con "Reintentar".
class ConfiguracionNegocioViewModel
    extends AsyncNotifier<ConfiguracionNegocioState> {
  NegocioRepository get _negocios => ref.read(negocioRepositoryProvider);
  ProductoRepository get _productos => ref.read(productoRepositoryProvider);

  @override
  Future<ConfiguracionNegocioState> build() async {
    final sesion = ref.watch(sesionProvider);
    if (sesion == null) throw const CargaException(errorSinSesion);

    final negocio = await _negocios.obtenerPorPropietario(sesion.id);
    if (negocio == null) {
      throw const CargaException(
        'No encontramos tu negocio. Vuelve a elegir el tipo de negocio.',
      );
    }

    // Se cargan las 4 cosas al mismo tiempo.
    final (modalidades, elegidas, categorias, productos) = await (
      _negocios.obtenerModalidadesPago(),
      _negocios.obtenerModalidadesDelNegocio(negocio.id),
      _productos.obtenerCategorias(),
      _productos.obtenerPorNegocio(negocio.id),
    ).wait;

    return ConfiguracionNegocioState(
      // Si el negocio aún no tiene teléfono, se propone el del usuario.
      negocio: negocio.telefono.isEmpty
          ? negocio.copyWith(telefono: sesion.telefono)
          : negocio,
      negocioGuardado: negocio,
      modalidades: modalidades,
      modalidadesElegidas: elegidas,
      modalidadesGuardadas: elegidas,
      categorias: categorias,
      productos: productos,
    );
  }

  ConfiguracionNegocioState get _actual => state.requireValue;

  void _emitir(ConfiguracionNegocioState nuevo) => state = AsyncData(nuevo);

  // ---------------------------------------------------------------- Fotos

  /// Abre la cámara o la galería. Devuelve la imagen (null si canceló o
  /// falló) y el resultado para que la View muestre mensajes.
  Future<(ImagenElegida?, Resultado)> obtenerImagen(FuenteImagen fuente) async {
    try {
      final imagen = await ref.read(imagenServiceProvider).elegir(fuente);
      return (imagen, const Exito());
    } on ImagenException catch (e) {
      return (
        null,
        e.permisoBloqueado
            ? RequiereAjustes(e.mensaje, AjustesDestino.app)
            : Fallo(e.mensaje),
      );
    } catch (_) {
      return (null, const Fallo('No se pudo abrir la imagen.'));
    }
  }

  Future<Resultado> elegirPortada(FuenteImagen fuente) async {
    final (imagen, resultado) = await obtenerImagen(fuente);
    if (imagen != null && ref.mounted) {
      _emitir(_actual.copyWith(portadaNueva: imagen));
    }
    return resultado;
  }

  Future<Resultado> elegirLogo(FuenteImagen fuente) async {
    final (imagen, resultado) = await obtenerImagen(fuente);
    if (imagen != null && ref.mounted) {
      _emitir(_actual.copyWith(logoNuevo: imagen));
    }
    return resultado;
  }

  // ------------------------------------------------------------ Ubicación

  Future<Resultado> actualizarUbicacion() async {
    if (_actual.ocupado) return const Exito();
    _emitir(_actual.copyWith(ubicando: true));
    try {
      final c =
          await ref.read(ubicacionServiceProvider).obtenerUbicacionActual();
      if (!ref.mounted) return const Exito();
      _emitir(_actual.copyWith(
        ubicando: false,
        negocio: _actual.negocio.copyWith(
          latitud: c.latitud,
          longitud: c.longitud,
          ubicacionActualizada: DateTime.now(),
        ),
      ));
      return const Exito();
    } on UbicacionException catch (e) {
      if (ref.mounted) _emitir(_actual.copyWith(ubicando: false));
      return switch (e.motivo) {
        MotivoUbicacion.gpsApagado =>
          RequiereAjustes(e.mensaje, AjustesDestino.ubicacion),
        MotivoUbicacion.permisoBloqueado =>
          RequiereAjustes(e.mensaje, AjustesDestino.app),
        _ => Fallo(e.mensaje),
      };
    } catch (_) {
      if (ref.mounted) _emitir(_actual.copyWith(ubicando: false));
      return const Fallo(
        'No pudimos obtener tu ubicación. Intenta de nuevo.',
      );
    }
  }

  Future<void> abrirAjustes(AjustesDestino destino) async {
    final servicio = ref.read(ubicacionServiceProvider);
    try {
      switch (destino) {
        case AjustesDestino.app:
          await servicio.abrirAjustesApp();
        case AjustesDestino.ubicacion:
          await servicio.abrirAjustesUbicacion();
      }
    } catch (_) {
      // En web no existen esos ajustes: no hay nada que hacer.
    }
  }

  // ------------------------------------------------------ Tipo de negocio

  /// Cambia entre Fijo y Ambulante (se guarda con "Guardar cambios").
  void cambiarTipo(TipoNegocio tipo) {
    if (_actual.ocupado || tipo == _actual.negocio.tipo) return;
    _emitir(_actual.copyWith(negocio: _actual.negocio.copyWith(tipo: tipo)));
  }

  // ------------------------------------------------------- Formas de pago

  void alternarModalidad(String modalidadId) {
    final elegidas = {..._actual.modalidadesElegidas};
    if (!elegidas.remove(modalidadId)) elegidas.add(modalidadId);
    _emitir(_actual.copyWith(modalidadesElegidas: elegidas));
  }

  // ------------------------------------------------------------ Productos

  /// Crea (si [existente] es null) o edita un producto. Se guarda al momento.
  Future<Resultado> guardarProducto({
    Producto? existente,
    required String nombre,
    required String descripcion,
    required String categoriaId,
    required double precio,
    required int stock,
    required bool disponible,
    ImagenElegida? imagenNueva,
  }) async {
    try {
      var imagenUrl = existente?.imagenUrl;
      if (imagenNueva != null) {
        imagenUrl = await _negocios.subirImagen(imagenNueva);
      }
      final guardado = await _productos.guardarProducto(Producto(
        id: existente?.id ?? '',
        negocioId: _actual.negocio.id,
        categoriaId: categoriaId,
        nombre: nombre.trim(),
        descripcion: descripcion.trim(),
        precio: precio,
        imagenUrl: imagenUrl,
        stock: stock,
        disponible: disponible,
      ));
      if (!ref.mounted) return const Exito();

      final lista = [..._actual.productos];
      final i = lista.indexWhere((p) => p.id == guardado.id);
      if (i >= 0) {
        lista[i] = guardado;
      } else {
        lista.add(guardado);
      }
      _emitir(_actual.copyWith(productos: lista));
      return const Exito();
    } catch (_) {
      return const Fallo('No se pudo guardar el producto. Intenta de nuevo.');
    }
  }

  Future<Resultado> eliminarProducto(String productoId) async {
    try {
      await _productos.eliminarProducto(productoId);
      if (!ref.mounted) return const Exito();
      _emitir(_actual.copyWith(
        productos: _actual.productos.where((p) => p.id != productoId).toList(),
      ));
      return const Exito();
    } catch (_) {
      return const Fallo('No se pudo eliminar el producto.');
    }
  }

  // -------------------------------------------------------------- Guardar

  /// Valida lo que no son campos de texto, sube las fotos nuevas y guarda.
  Future<Resultado> guardar({
    required String nombre,
    required String descripcion,
    required String telefono,
    required String direccion,
  }) async {
    final actual = _actual;
    if (actual.ocupado) {
      return const Fallo('Espera a que termine la acción en curso.');
    }
    if (actual.modalidadesElegidas.isEmpty) {
      return const Fallo('Elige al menos una forma de pago.');
    }
    if (!actual.negocio.tieneUbicacion) {
      return Fallo(
        actual.negocio.tipo == TipoNegocio.fijo
            ? 'Marca la ubicación de tu local con "Usar mi ubicación actual".'
            : 'Toca "Actualizar mi ubicación" para que los clientes te '
                'encuentren.',
      );
    }

    _emitir(actual.copyWith(guardando: true));
    try {
      var negocio = actual.negocio.copyWith(
        nombre: nombre.trim(),
        descripcion: descripcion.trim(),
        telefono: telefono.trim(),
        direccion: actual.negocio.tipo == TipoNegocio.fijo
            ? direccion.trim()
            : '',
      );
      if (actual.portadaNueva != null) {
        negocio = negocio.copyWith(
          bannerUrl: await _negocios.subirImagen(actual.portadaNueva!),
        );
      }
      if (actual.logoNuevo != null) {
        negocio = negocio.copyWith(
          logoUrl: await _negocios.subirImagen(actual.logoNuevo!),
        );
      }
      final guardado = await _negocios.actualizarNegocio(negocio);
      await _negocios.guardarModalidadesDelNegocio(
        guardado.id,
        actual.modalidadesElegidas,
      );
      if (!ref.mounted) return const Exito();

      _emitir(_actual.copyWith(
        negocio: guardado,
        negocioGuardado: guardado,
        modalidadesGuardadas: actual.modalidadesElegidas,
        guardando: false,
        limpiarImagenesNuevas: true,
      ));
      return const Exito();
    } catch (_) {
      if (ref.mounted) _emitir(_actual.copyWith(guardando: false));
      return const Fallo(
        'No se pudieron guardar los cambios. Intenta de nuevo.',
      );
    }
  }
}

final configuracionNegocioViewModelProvider = AsyncNotifierProvider<
    ConfiguracionNegocioViewModel, ConfiguracionNegocioState>(
  ConfiguracionNegocioViewModel.new,
);
