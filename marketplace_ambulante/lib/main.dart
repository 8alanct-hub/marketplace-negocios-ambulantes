import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';

void main() {
  // Todavía no hay backend: las pantallas usan repositorios mock
  // (ver model/repository_providers.dart). Cuando se elija la base de datos,
  // se crean nuevas implementaciones de los repositorios y se cambian ahí.
  runApp(const ProviderScope(child: EcosistemaApp()));
}
