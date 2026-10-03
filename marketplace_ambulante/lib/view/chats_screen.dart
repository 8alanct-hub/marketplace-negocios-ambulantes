import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/router/app_router.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/formato.dart';
import '../viewmodel/chat_viewmodel.dart';
import 'widgets/estado_widgets.dart';

/// View: lista de chats del usuario.
class ChatsScreen extends ConsumerWidget {
  const ChatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(conversacionesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Chats')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorCarga(
          mensaje: 'No pudimos cargar tus chats.',
          onReintentar: () => ref.invalidate(conversacionesProvider),
        ),
        data: (conversaciones) => RefreshIndicator(
          onRefresh: () => ref.refresh(conversacionesProvider.future),
          child: conversaciones.isEmpty
              ? ListView(
                  children: const [
                    EstadoVacio(
                      icono: Icons.chat_bubble_outline,
                      mensaje: 'Aún no tienes chats.\nEscríbele a un negocio '
                          'desde su página o desde tus pedidos.',
                    ),
                  ],
                )
              : ListView.separated(
                  itemCount: conversaciones.length,
                  separatorBuilder: (_, _) =>
                      const Divider(height: 1, indent: 72),
                  itemBuilder: (context, i) {
                    final c = conversaciones[i];
                    return ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: AppColors.grisFondo,
                        child: Icon(
                          Icons.storefront_outlined,
                          color: AppColors.negro,
                        ),
                      ),
                      title: Text(
                        c.negocioNombre,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        c.ultimoMensaje ?? 'Sin mensajes todavía',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Text(
                        Formato.haceCuanto(c.fechaUltimoMensaje),
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.grisTexto,
                        ),
                      ),
                      onTap: () =>
                          context.push(AppRoutes.chatConNegocio(c.negocioId)),
                    );
                  },
                ),
        ),
      ),
    );
  }
}
