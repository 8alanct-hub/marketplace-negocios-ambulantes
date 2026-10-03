import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Ícono hecho con una imagen PNG de assets/icons/, pintado de un solo
/// color para que combine con los íconos de Material.
class IconoAsset extends StatelessWidget {
  const IconoAsset(this.ruta, {super.key, this.size = 24});

  final String ruta;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      ruta,
      width: size,
      height: size,
      color: IconTheme.of(context).color ?? AppColors.negro,
    );
  }
}

/// Rutas de los íconos propios.
abstract final class IconosApp {
  /// Carrito de vendedor ambulante.
  /// Crédito: "Portable Food Store" de Flaticon (se muestra en Acerca de).
  static const carritoAmbulante = 'assets/icons/carrito_ambulante.png';
}

/// Tarjeta de opción: ícono + título + descripción + flecha.
/// Si [onTap] es null se ve deshabilitada.
class OpcionCard extends StatelessWidget {
  const OpcionCard({
    super.key,
    required this.icono,
    required this.titulo,
    required this.descripcion,
    required this.onTap,
  });

  /// Normalmente un `Icon(...)` o un `IconoAsset(...)`.
  final Widget icono;
  final String titulo;
  final String descripcion;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onTap == null ? 0.5 : 1,
      child: Material(
        color: AppColors.blanco,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.grisBorde),
        ),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.grisFondo,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: IconTheme(
                    data: const IconThemeData(
                      color: AppColors.negro,
                      size: 24,
                    ),
                    child: Center(child: icono),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        titulo,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        descripcion,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.grisTexto,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.grisTexto),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Estructura común de las pantallas de "elige una opción":
/// título, subtítulo, opciones y botón inferior.
class PantallaSeleccion extends StatelessWidget {
  const PantallaSeleccion({
    super.key,
    required this.titulo,
    required this.subtitulo,
    required this.opciones,
    required this.textoBotonInferior,
    required this.onBotonInferior,
    this.cargando = false,
  });

  final String titulo;
  final String subtitulo;
  final List<Widget> opciones;
  final String textoBotonInferior;
  final VoidCallback onBotonInferior;
  final bool cargando;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Barra de progreso fina mientras se guarda.
            SizedBox(
              height: 2,
              child: cargando ? const LinearProgressIndicator() : null,
            ),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          titulo,
                          textAlign: TextAlign.center,
                          style: text.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          subtitulo,
                          textAlign: TextAlign.center,
                          style: text.bodySmall
                              ?.copyWith(color: AppColors.grisTexto),
                        ),
                        const SizedBox(height: 32),
                        for (final opcion in opciones) ...[
                          opcion,
                          const SizedBox(height: 12),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: OutlinedButton(
                  onPressed: cargando ? null : onBotonInferior,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(44),
                    foregroundColor: AppColors.negro,
                    side: const BorderSide(color: AppColors.grisBorde),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(textoBotonInferior),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
