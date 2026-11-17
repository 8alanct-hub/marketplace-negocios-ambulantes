/// Dónde está la API (backend) de la app.
///
/// Por defecto la app usa la API publicada en Render, conectada a la base
/// de datos real (Supabase). Se puede cambiar al ejecutar:
///
///   flutter run --dart-define=API_URL=http://10.0.2.2:3000/api
///       (API corriendo en tu computador, vista desde el emulador Android)
///
///   flutter run --dart-define=USAR_MOCKS=true
///       (sin internet: vuelve a los datos de prueba en memoria)
abstract final class ApiConfig {
  static const url = String.fromEnvironment(
    'API_URL',
    defaultValue: 'https://marketplace-negocios-ambulantes.onrender.com/api',
  );

  static const usarMocks = bool.fromEnvironment('USAR_MOCKS');
}
