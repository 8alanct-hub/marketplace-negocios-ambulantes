import 'dart:async';

import 'package:geolocator/geolocator.dart';

class Coordenadas {
  const Coordenadas(this.latitud, this.longitud);

  final double latitud;
  final double longitud;
}

enum MotivoUbicacion { gpsApagado, permisoDenegado, permisoBloqueado, otro }

class UbicacionException implements Exception {
  const UbicacionException(this.motivo, this.mensaje);

  final MotivoUbicacion motivo;
  final String mensaje;

  @override
  String toString() => mensaje;
}

/// Acceso al GPS del dispositivo.
abstract interface class UbicacionService {
  /// Pide permiso si hace falta y devuelve la ubicación actual.
  Future<Coordenadas> obtenerUbicacionActual();

  /// Abre los ajustes de la app (para activar un permiso bloqueado).
  Future<void> abrirAjustesApp();

  /// Abre los ajustes de ubicación del sistema (para encender el GPS).
  Future<void> abrirAjustesUbicacion();
}

/// Implementación con el paquete geolocator.
class UbicacionServiceGps implements UbicacionService {
  @override
  Future<Coordenadas> obtenerUbicacionActual() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const UbicacionException(
        MotivoUbicacion.gpsApagado,
        'Tu ubicación (GPS) está apagada. Actívala para continuar.',
      );
    }

    var permiso = await Geolocator.checkPermission();
    if (permiso == LocationPermission.denied ||
        permiso == LocationPermission.unableToDetermine) {
      permiso = await Geolocator.requestPermission(); // aviso del sistema
    }
    if (permiso == LocationPermission.deniedForever) {
      throw const UbicacionException(
        MotivoUbicacion.permisoBloqueado,
        'El permiso de ubicación está bloqueado. Actívalo en los ajustes '
        'de la app para que los clientes cercanos encuentren tu negocio.',
      );
    }
    if (permiso == LocationPermission.denied) {
      throw const UbicacionException(
        MotivoUbicacion.permisoDenegado,
        'Necesitamos tu ubicación para que los clientes cercanos '
        'encuentren tu negocio.',
      );
    }

    try {
      final posicion = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );
      return Coordenadas(posicion.latitude, posicion.longitude);
    } on TimeoutException {
      throw const UbicacionException(
        MotivoUbicacion.otro,
        'Tardó demasiado en encontrar tu ubicación. Intenta de nuevo, '
        'de preferencia al aire libre.',
      );
    }
  }

  @override
  Future<void> abrirAjustesApp() async {
    await Geolocator.openAppSettings();
  }

  @override
  Future<void> abrirAjustesUbicacion() async {
    await Geolocator.openLocationSettings();
  }
}
