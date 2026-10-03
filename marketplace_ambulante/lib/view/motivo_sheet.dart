import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../model/pedido.dart';

/// Pide el motivo para rechazar o cancelar un pedido.
/// Devuelve el motivo elegido o escrito, o null si el usuario se arrepiente.
Future<String?> pedirMotivo(
  BuildContext context, {
  required String titulo,
  required String textoBoton,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (_) => _MotivoSheet(titulo: titulo, textoBoton: textoBoton),
  );
}

class _MotivoSheet extends StatefulWidget {
  const _MotivoSheet({required this.titulo, required this.textoBoton});

  final String titulo;
  final String textoBoton;

  @override
  State<_MotivoSheet> createState() => _MotivoSheetState();
}

class _MotivoSheetState extends State<_MotivoSheet> {
  static const _otro = 'Otro';

  String? _elegido;
  final _otroCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Para habilitar el botón en cuanto se escribe el motivo "Otro".
    _otroCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _otroCtrl.dispose();
    super.dispose();
  }

  /// Motivo final, o null si todavía falta elegir/escribir.
  String? get _motivo {
    if (_elegido == null) return null;
    if (_elegido != _otro) return _elegido;
    final texto = _otroCtrl.text.trim();
    return texto.isEmpty ? null : texto;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.titulo,
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            const Text(
              'El cliente verá este motivo.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppColors.grisTexto),
            ),
            const SizedBox(height: 8),
            for (final opcion in [...motivosCancelacion, _otro])
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  _elegido == opcion
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: AppColors.negro,
                ),
                title: Text(opcion),
                onTap: () => setState(() => _elegido = opcion),
              ),
            if (_elegido == _otro)
              TextField(
                controller: _otroCtrl,
                autofocus: true,
                maxLength: 150,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText: 'Escribe el motivo',
                ),
              ),
            const SizedBox(height: 8),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.error),
              onPressed:
                  _motivo == null ? null : () => Navigator.pop(context, _motivo),
              child: Text(widget.textoBoton),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(foregroundColor: AppColors.negro),
              child: const Text('Volver'),
            ),
          ],
        ),
      ),
    );
  }
}
