import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:marketplace_ambulante/view/seleccion_rol_screen.dart';
import 'package:marketplace_ambulante/view/sign_in_screen.dart';
import 'package:marketplace_ambulante/view/sign_up_screen.dart';
import 'package:marketplace_ambulante/view/tipo_negocio_screen.dart';

Widget _app(Widget pantalla) =>
    ProviderScope(child: MaterialApp(home: pantalla));

void main() {
  testWidgets('Crear cuenta valida correo y contraseñas', (tester) async {
    await tester.pumpWidget(_app(const SignUpScreen()));

    expect(find.text('Crea una cuenta'), findsOneWidget);
    expect(find.text('¿Ya tienes cuenta?'), findsOneWidget);

    // El formulario es largo: aseguramos que el botón esté en pantalla.
    final boton = find.widgetWithText(FilledButton, 'Crear cuenta');

    // Todo vacío → errores de cada campo.
    await tester.ensureVisible(boton);
    await tester.tap(boton);
    await tester.pump();
    expect(find.text('Ingresa tu nombre'), findsOneWidget);
    expect(find.text('Ingresa tu apellido'), findsOneWidget);
    expect(find.text('Ingresa tu teléfono'), findsOneWidget);
    expect(find.text('Ingresa tu correo electrónico'), findsOneWidget);
    expect(find.text('Crea una contraseña'), findsOneWidget);
    expect(find.text('Confirma tu contraseña'), findsOneWidget);

    // Datos mal escritos, contraseña débil y confirmación distinta.
    // Orden: nombre, apellido, teléfono, correo, contraseña, confirmar.
    final campos = find.byType(TextFormField);
    await tester.enterText(campos.at(0), 'Ana1');
    await tester.enterText(campos.at(1), 'Pérez');
    await tester.enterText(campos.at(2), '123');
    await tester.enterText(campos.at(3), 'ana@test.com');
    await tester.enterText(campos.at(4), 'corta');
    await tester.enterText(campos.at(5), 'otra');
    await tester.ensureVisible(boton);
    await tester.tap(boton);
    await tester.pump();
    expect(find.text('Usa solo letras'), findsOneWidget);
    expect(find.text('Ingresa un teléfono válido'), findsOneWidget);
    expect(find.text('Debe tener al menos 8 caracteres'), findsOneWidget);
    expect(find.text('Las contraseñas no coinciden'), findsOneWidget);
  });

  testWidgets('Iniciar sesión muestra el correo recibido y pide contraseña',
      (tester) async {
    await tester.pumpWidget(
      _app(const SignInScreen(emailInicial: 'ana@test.com')),
    );

    expect(find.text('ana@test.com'), findsOneWidget);
    expect(find.text('¿No tienes cuenta?'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Iniciar sesión'));
    await tester.pump();
    expect(find.text('Ingresa tu contraseña'), findsOneWidget);
  });

  testWidgets('¿Eres un? muestra Usuario, Negocio y Cerrar sesión',
      (tester) async {
    await tester.pumpWidget(_app(const SeleccionRolScreen()));
    expect(find.text('¿Eres un?'), findsOneWidget);
    expect(find.text('Usuario'), findsOneWidget);
    expect(find.text('Negocio'), findsOneWidget);
    expect(find.text('Cerrar sesión'), findsOneWidget);
  });

  testWidgets('Tipo de negocio muestra Ambulante, Fijo y Volver',
      (tester) async {
    await tester.pumpWidget(_app(const TipoNegocioScreen()));
    expect(find.text('¿Qué tipo de negocio?'), findsOneWidget);
    expect(find.text('Ambulante'), findsOneWidget);
    expect(find.text('Fijo'), findsOneWidget);
    expect(find.text('Volver'), findsOneWidget);
  });
}
