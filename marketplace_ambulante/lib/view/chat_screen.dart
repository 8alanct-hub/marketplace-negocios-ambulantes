import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_theme.dart';
import '../model/chat.dart';
import '../viewmodel/chat_viewmodel.dart';
import '../viewmodel/resultado.dart';
import '../viewmodel/sesion_viewmodel.dart';
import 'widgets/auth_widgets.dart';
import 'widgets/estado_widgets.dart';

/// View: "Chat con el negocio".
class ChatScreen extends ConsumerWidget {
  const ChatScreen({super.key, required this.negocioId});

  final String negocioId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(conversacionConNegocioProvider(negocioId));

    return async.when(
      loading: () => Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(),
        body: ErrorCarga(
          mensaje: error.toString(),
          onReintentar: () =>
              ref.invalidate(conversacionConNegocioProvider(negocioId)),
        ),
      ),
      data: (conversacion) => _Chat(conversacion: conversacion),
    );
  }
}

class _Chat extends ConsumerStatefulWidget {
  const _Chat({required this.conversacion});

  final Conversacion conversacion;

  @override
  ConsumerState<_Chat> createState() => _ChatState();
}

class _ChatState extends ConsumerState<_Chat> {
  final _textoCtrl = TextEditingController();

  @override
  void dispose() {
    _textoCtrl.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    final texto = _textoCtrl.text;
    if (texto.trim().isEmpty) return;
    _textoCtrl.clear();
    final r = await ref
        .read(chatViewModelProvider.notifier)
        .enviar(widget.conversacion.id, texto);
    if (r is Fallo && mounted) {
      _textoCtrl.text = texto; // no perder lo escrito
      mostrarMensaje(context, r.mensaje);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mensajes = ref.watch(mensajesProvider(widget.conversacion.id));
    final miId = ref.watch(sesionProvider)?.id;
    final enviando = ref.watch(chatViewModelProvider);

    return Scaffold(
      appBar: AppBar(title: Text(widget.conversacion.negocioNombre)),
      body: Column(
        children: [
          Expanded(
            child: mensajes.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => const Center(
                child: Text('No pudimos cargar los mensajes.'),
              ),
              data: (lista) => lista.isEmpty
                  ? const EstadoVacio(
                      icono: Icons.waving_hand_outlined,
                      mensaje: 'Escribe tu primer mensaje para coordinar tu '
                          'pedido o la entrega.',
                    )
                  : ListView.builder(
                      // reverse: el último mensaje queda abajo y visible.
                      reverse: true,
                      padding: const EdgeInsets.all(12),
                      itemCount: lista.length,
                      itemBuilder: (context, i) {
                        final m = lista[lista.length - 1 - i];
                        return _Burbuja(mensaje: m, esMio: m.remitenteId == miId);
                      },
                    ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textoCtrl,
                      textCapitalization: TextCapitalization.sentences,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _enviar(),
                      decoration: const InputDecoration(
                        hintText: 'Mensaje',
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton.filled(
                    tooltip: 'Enviar',
                    onPressed: enviando ? null : _enviar,
                    icon: const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Burbuja extends StatelessWidget {
  const _Burbuja({required this.mensaje, required this.esMio});

  final Mensaje mensaje;
  final bool esMio;

  @override
  Widget build(BuildContext context) {
    final hora = TimeOfDay.fromDateTime(mensaje.fechaEnvio).format(context);
    return Align(
      alignment: esMio ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.75,
        ),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 3),
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
          decoration: BoxDecoration(
            color: esMio ? AppColors.negro : AppColors.grisFondo,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(14),
              topRight: const Radius.circular(14),
              bottomLeft: Radius.circular(esMio ? 14 : 4),
              bottomRight: Radius.circular(esMio ? 4 : 14),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                mensaje.texto,
                style: TextStyle(
                  color: esMio ? AppColors.blanco : AppColors.negro,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                hora,
                style: TextStyle(
                  fontSize: 10,
                  color: esMio ? Colors.white70 : AppColors.grisTexto,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
