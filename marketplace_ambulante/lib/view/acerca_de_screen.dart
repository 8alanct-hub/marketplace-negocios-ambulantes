import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/constants/app_constants.dart';
import '../core/theme/app_theme.dart';
import 'widgets/auth_widgets.dart';
import 'widgets/seleccion_widgets.dart';

/// Un recurso de terceros que exige atribución.
class _Credito {
  const _Credito({
    required this.uso,
    required this.texto,
    required this.url,
    this.icono,
  });

  final String uso;
  final String texto;
  final String url;
  final Widget? icono;
}

/// Agrega aquí cada recurso nuevo que pida atribución.
const _creditos = [
  _Credito(
    uso: 'Ícono de negocio ambulante',
    texto: 'Portable Food Store - Free commerce icons (Flaticon)',
    url: 'https://www.flaticon.com/free-icon/portable-food-store_110108',
    icono: IconoAsset(IconosApp.carritoAmbulante),
  ),
];

/// View: "Acerca de" (descripción de la app y créditos).
class AcercaDeScreen extends StatelessWidget {
  const AcercaDeScreen({super.key});

  Future<void> _abrir(BuildContext context, String url) async {
    final ok = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
    if (!ok && context.mounted) {
      mostrarMensaje(context, 'No se pudo abrir el enlace.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Acerca de')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            AppConstants.nombreApp,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          const Text(
            'Versión 1.0.0',
            style: TextStyle(color: AppColors.grisTexto),
          ),
          const SizedBox(height: 12),
          const Text(
            'Marketplace local que conecta a las personas con pequeños '
            'negocios fijos y ambulantes de su zona. La app no procesa pagos '
            'ni hace domicilios: el pago y la entrega se acuerdan directamente '
            'con cada negocio.',
          ),
          const SizedBox(height: 24),
          const Text(
            'Créditos',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          for (final c in _creditos)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: c.icono,
              title: Text(c.uso),
              subtitle: Text(c.texto),
              trailing: const Icon(Icons.open_in_new, size: 18),
              onTap: () => _abrir(context, c.url),
            ),
        ],
      ),
    );
  }
}
