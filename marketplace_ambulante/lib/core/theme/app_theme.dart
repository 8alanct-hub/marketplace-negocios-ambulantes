import 'package:flutter/material.dart';

/// Paleta base tomada de los mockups (blanco y negro con grises).
abstract final class AppColors {
  static const negro = Color(0xFF000000);
  static const blanco = Color(0xFFFFFFFF);
  static const grisTexto = Color(0xFF828282);
  static const grisBorde = Color(0xFFE0E0E0);
  static const grisFondo = Color(0xFFEEEEEE);
  static const error = Color(0xFFD32F2F);
}

abstract final class AppTheme {
  static final _radio = BorderRadius.circular(8);

  static OutlineInputBorder _borde(Color color, [double ancho = 1]) =>
      OutlineInputBorder(
        borderRadius: _radio,
        borderSide: BorderSide(color: color, width: ancho),
      );

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.blanco,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.negro,
          // Monocromático: sin tintes de color (antes los fondos de menús y
          // formularios salían rosados por el color automático de Material 3).
          dynamicSchemeVariant: DynamicSchemeVariant.monochrome,
          primary: AppColors.negro,
          onPrimary: AppColors.blanco,
          surface: AppColors.blanco,
          error: AppColors.error,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.blanco,
          foregroundColor: AppColors.negro,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.blanco,
          hintStyle: const TextStyle(color: AppColors.grisTexto, fontSize: 14),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          border: _borde(AppColors.grisBorde),
          enabledBorder: _borde(AppColors.grisBorde),
          focusedBorder: _borde(AppColors.negro, 1.5),
          errorBorder: _borde(AppColors.error),
          focusedErrorBorder: _borde(AppColors.error, 1.5),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.negro,
            foregroundColor: AppColors.blanco,
            minimumSize: const Size.fromHeight(44),
            shape: RoundedRectangleBorder(borderRadius: _radio),
            textStyle:
                const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ),
        snackBarTheme: const SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: AppColors.blanco,
          surfaceTintColor: Colors.transparent,
          // En pantallas anchas (web/tablet) no ocupa todo el ancho.
          constraints: BoxConstraints(maxWidth: 600),
        ),
        dialogTheme: const DialogThemeData(
          backgroundColor: AppColors.blanco,
          surfaceTintColor: Colors.transparent,
        ),
      );
}
