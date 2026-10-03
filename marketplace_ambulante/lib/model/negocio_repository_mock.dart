import 'dart:convert';

import 'imagen_service.dart';
import 'mock_catalogos.dart';
import 'mock_usuarios.dart';
import 'modalidad_pago.dart';
import 'negocio.dart';
import 'negocio_repository.dart';

class NegocioRepositoryMock implements NegocioRepository {
  NegocioRepositoryMock({
    this.latencia = const Duration(milliseconds: 600),
    DateTime? ahora,
  }) {
    // A los ambulantes de prueba se les pone una ubicación "reciente".
    final momento = ahora ?? DateTime.now();
    var minutos = 10;
    for (final n in mockNegocios) {
      _negocios[n.propietarioId] = n.tipo == TipoNegocio.ambulante
          ? n.copyWith(
              ubicacionActualizada:
                  momento.subtract(Duration(minutes: minutos += 15)),
            )
          : n;
    }
  }

  final Duration latencia;

  /// propietarioId → negocio
  final Map<String, Negocio> _negocios = {};

  /// negocioId → ids de modalidades de pago
  final Map<String, Set<String>> _modalidades = {
    for (final e in mockModalidadesPorNegocio.entries) e.key: {...e.value},
  };

  Future<void> _esperar() => Future<void>.delayed(latencia);

  @override
  Future<Negocio> crearNegocio({
    required String propietarioId,
    required TipoNegocio tipo,
  }) async {
    await _esperar();
    final existente = _negocios[propietarioId];
    final negocio = existente?.copyWith(tipo: tipo) ??
        Negocio(
          id: 'n_${_negocios.length + 1}',
          propietarioId: propietarioId,
          tipo: tipo,
        );
    _negocios[propietarioId] = negocio;
    return negocio;
  }

  @override
  Future<Negocio?> obtenerPorPropietario(String propietarioId) async {
    await _esperar();
    return _negocios[propietarioId];
  }

  @override
  Future<Negocio?> obtenerPorId(String negocioId) async {
    await _esperar();
    return _negocios.values.where((n) => n.id == negocioId).firstOrNull;
  }

  @override
  Future<List<Negocio>> obtenerNegociosPublicados() async {
    await _esperar();
    return _negocios.values
        .where((n) => n.nombre.isNotEmpty && n.tieneUbicacion)
        .toList();
  }

  @override
  Future<Negocio> actualizarNegocio(Negocio negocio) async {
    await _esperar();
    _negocios[negocio.propietarioId] = negocio;
    return negocio;
  }

  /// En el mock la imagen se guarda dentro de la misma URL ("data URI").
  /// Un backend real la subiría a un almacenamiento y devolvería https://...
  @override
  Future<String> subirImagen(ImagenElegida imagen) async {
    await _esperar();
    return 'data:${imagen.mime};base64,${base64Encode(imagen.bytes)}';
  }

  @override
  Future<List<ModalidadPago>> obtenerModalidadesPago() async {
    await _esperar();
    return mockModalidadesPago;
  }

  @override
  Future<Set<String>> obtenerModalidadesDelNegocio(String negocioId) async {
    await _esperar();
    return {...?_modalidades[negocioId]};
  }

  @override
  Future<void> guardarModalidadesDelNegocio(
    String negocioId,
    Set<String> modalidadIds,
  ) async {
    await _esperar();
    _modalidades[negocioId] = {...modalidadIds};
  }
}
