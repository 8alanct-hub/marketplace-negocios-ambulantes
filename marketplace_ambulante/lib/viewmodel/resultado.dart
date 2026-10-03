import '../model/ubicacion_service.dart';

/// Resultado de una acción del ViewModel, para que la View sepa qué mostrar.
sealed class Resultado {
  const Resultado();
}

/// Salió bien (o el usuario canceló: no hay nada que mostrar).
class Exito extends Resultado {
  const Exito();
}

/// Falló: mostrar [mensaje].
class Fallo extends Resultado {
  const Fallo(this.mensaje);
  final String mensaje;
}

enum AjustesDestino { app, ubicacion }

/// Falta un permiso o el GPS está apagado: mostrar un pop-up con un botón
/// que abre los ajustes del teléfono.
class RequiereAjustes extends Resultado {
  const RequiereAjustes(this.mensaje, this.destino);
  final String mensaje;
  final AjustesDestino destino;
}

/// Convierte un error de GPS en el [Resultado] que la View sabe mostrar.
Resultado resultadoDeUbicacion(UbicacionException e) => switch (e.motivo) {
      MotivoUbicacion.gpsApagado =>
        RequiereAjustes(e.mensaje, AjustesDestino.ubicacion),
      MotivoUbicacion.permisoBloqueado =>
        RequiereAjustes(e.mensaje, AjustesDestino.app),
      _ => Fallo(e.mensaje),
    };

/// Abre los ajustes del teléfono. En web no existen: no hace nada.
Future<void> abrirAjustesDispositivo(
  UbicacionService servicio,
  AjustesDestino destino,
) async {
  try {
    switch (destino) {
      case AjustesDestino.app:
        await servicio.abrirAjustesApp();
      case AjustesDestino.ubicacion:
        await servicio.abrirAjustesUbicacion();
    }
  } catch (_) {}
}
