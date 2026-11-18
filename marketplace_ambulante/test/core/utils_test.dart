import 'package:flutter_test/flutter_test.dart';

import 'package:marketplace_ambulante/core/utils/distancia.dart';
import 'package:marketplace_ambulante/core/utils/formato.dart';

void main() {
  group('Distancia', () {
    test('Cartagena → Bogotá son unos 650 km', () {
      final m = Distancia.metrosEntre(10.4236, -75.5478, 4.7110, -74.0721);
      expect(m / 1000, closeTo(650, 15));
    });

    test('mismo punto = 0 m', () {
      expect(Distancia.metrosEntre(10.42, -75.54, 10.42, -75.54), 0);
    });

    test('texto legible', () {
      expect(Distancia.texto(347), 'a 350 m');
      expect(Distancia.texto(1234), 'a 1,2 km');
      expect(Distancia.texto(25300), 'a 25 km');
    });
  });

  group('Formato', () {
    test('precio con separador de miles', () {
      expect(Formato.precio(25000), '\$ 25.000');
      expect(Formato.precio(1500000), '\$ 1.500.000');
      expect(Formato.precio(900), '\$ 900');
    });

    test('hace cuánto', () {
      final ahora = DateTime(2026, 10, 3, 12);
      expect(Formato.haceCuanto(ahora, ahora: ahora), 'hace un momento');
      expect(
        Formato.haceCuanto(ahora.subtract(const Duration(minutes: 5)),
            ahora: ahora),
        'hace 5 min',
      );
      expect(
        Formato.haceCuanto(ahora.subtract(const Duration(days: 1)),
            ahora: ahora),
        'hace 1 día',
      );
    });

    test('normalizar quita tildes y mayúsculas', () {
      expect(Formato.normalizar('  Panadería ÚNICA '), 'panaderia unica');
    });
  });
}
