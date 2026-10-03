/// Formatos para mostrar datos al usuario.
abstract final class Formato {
  /// 25000 → "$ 25.000"
  static String precio(num valor) {
    final entero = valor.round().toString();
    final buffer = StringBuffer();
    for (var i = 0; i < entero.length; i++) {
      if (i > 0 && (entero.length - i) % 3 == 0) buffer.write('.');
      buffer.write(entero[i]);
    }
    return '\$ $buffer';
  }

  /// "hace un momento", "hace 5 min", "hace 2 h", "hace 3 días"
  static String haceCuanto(DateTime fecha, {DateTime? ahora}) {
    final d = (ahora ?? DateTime.now()).difference(fecha);
    if (d.inMinutes < 1) return 'hace un momento';
    if (d.inMinutes < 60) return 'hace ${d.inMinutes} min';
    if (d.inHours < 24) return 'hace ${d.inHours} h';
    return d.inDays == 1 ? 'hace 1 día' : 'hace ${d.inDays} días';
  }

  /// Minúsculas y sin tildes, para comparar en búsquedas.
  /// "Panadería" → "panaderia"
  static String normalizar(String texto) {
    const conTilde = 'áéíóúüÁÉÍÓÚÜ';
    const sinTilde = 'aeiouuaeiouu';
    final buffer = StringBuffer();
    for (final letra in texto.split('')) {
      final i = conTilde.indexOf(letra);
      buffer.write(i >= 0 ? sinTilde[i] : letra);
    }
    return buffer.toString().toLowerCase().trim();
  }
}
