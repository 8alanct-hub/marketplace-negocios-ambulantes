/// Validaciones de formularios. Devuelven un mensaje de error o null si
/// el valor es válido (formato que espera TextFormField.validator).
abstract final class Validators {
  static final _emailRegex = RegExp(r'^[\w.+-]+@[\w-]+(\.[\w-]+)+$');
  static final _tieneLetra = RegExp(r'[A-Za-zÁÉÍÓÚáéíóúÑñ]');
  static final _tieneNumero = RegExp(r'\d');

  static const minPassword = 8;
  static final _soloLetras = RegExp(r"^[A-Za-zÁÉÍÓÚÜáéíóúüÑñ' -]+$");

  /// Nombre o apellido: obligatorio, solo letras (acepta tildes y espacios).
  static String? nombre(String? value, {String campo = 'tu nombre'}) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Ingresa $campo';
    if (v.length < 2) return 'Debe tener al menos 2 letras';
    if (!_soloLetras.hasMatch(v)) return 'Usa solo letras';
    return null;
  }

  /// Teléfono: entre 7 y 15 dígitos. Acepta espacios, guiones y "+" inicial.
  static String? telefono(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Ingresa tu teléfono';
    final digitos = v.replaceAll(RegExp(r'[\s-]'), '');
    if (!RegExp(r'^\+?\d{7,15}$').hasMatch(digitos)) {
      return 'Ingresa un teléfono válido';
    }
    return null;
  }

  static String? email(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Ingresa tu correo electrónico';
    if (!_emailRegex.hasMatch(v)) return 'Ingresa un correo válido';
    return null;
  }

  /// Contraseña nueva (crear cuenta): mínimo 8, con letras y números.
  static String? passwordNueva(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return 'Crea una contraseña';
    if (v.length < minPassword) {
      return 'Debe tener al menos $minPassword caracteres';
    }
    if (!_tieneLetra.hasMatch(v) || !_tieneNumero.hasMatch(v)) {
      return 'Debe combinar letras y números';
    }
    return null;
  }

  /// Confirmación: debe ser igual a [original].
  static String? confirmarPassword(String? value, String original) {
    if ((value ?? '').isEmpty) return 'Confirma tu contraseña';
    if (value != original) return 'Las contraseñas no coinciden';
    return null;
  }

  /// Contraseña al iniciar sesión: solo se pide que no esté vacía.
  static String? passwordRequerida(String? value) {
    if ((value ?? '').isEmpty) return 'Ingresa tu contraseña';
    return null;
  }

  /// Campo obligatorio de texto libre.
  static String? requerido(String? value, String mensaje) =>
      (value?.trim() ?? '').isEmpty ? mensaje : null;

  static String? nombreComercial(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Ingresa el nombre de tu negocio';
    if (v.length < 2) return 'Debe tener al menos 2 caracteres';
    return null;
  }

  /// Precio en pesos, sin decimales.
  static String? precio(String? value) {
    final n = int.tryParse(value?.trim() ?? '');
    if (n == null) return 'Ingresa el precio';
    if (n <= 0) return 'Debe ser mayor a 0';
    return null;
  }

  static String? stock(String? value) {
    final n = int.tryParse(value?.trim() ?? '');
    if (n == null) return 'Ingresa la cantidad';
    if (n < 0) return 'No puede ser negativa';
    return null;
  }
}
