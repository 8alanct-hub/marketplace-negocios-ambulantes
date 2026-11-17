import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';

void main() {
  // Los datos vienen de la API (core/constants/api_config.dart), que está
  // conectada a la base de datos en Supabase. Qué implementación usa cada
  // repositorio se decide en model/repository_providers.dart.
  runApp(const ProviderScope(child: EcosistemaApp()));
}
