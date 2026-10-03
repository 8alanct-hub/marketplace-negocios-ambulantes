import 'package:flutter/material.dart';

import 'chats_screen.dart';
import 'marketplace_screen.dart';
import 'mis_pedidos_screen.dart';
import 'perfil_screen.dart';

/// Secciones de la barra inferior del usuario.
enum SeccionUsuario { inicio, pedidos, chats, perfil }

/// View: contenedor del usuario con la barra inferior
/// Inicio / Pedidos / Chats / Perfil.
class InicioUsuarioScreen extends StatefulWidget {
  const InicioUsuarioScreen({
    super.key,
    this.seccionInicial = SeccionUsuario.inicio,
  });

  final SeccionUsuario seccionInicial;

  @override
  State<InicioUsuarioScreen> createState() => _InicioUsuarioScreenState();
}

class _InicioUsuarioScreenState extends State<InicioUsuarioScreen> {
  late SeccionUsuario _seccion = widget.seccionInicial;

  @override
  void didUpdateWidget(InicioUsuarioScreen anterior) {
    super.didUpdateWidget(anterior);
    // Ej.: después de hacer un pedido se navega a "?seccion=pedidos".
    if (anterior.seccionInicial != widget.seccionInicial) {
      _seccion = widget.seccionInicial;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // IndexedStack mantiene cada sección viva (no pierde el scroll ni la
      // búsqueda al cambiar de pestaña).
      body: IndexedStack(
        index: _seccion.index,
        children: const [
          MarketplaceScreen(),
          MisPedidosScreen(),
          ChatsScreen(),
          PerfilScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _seccion.index,
        onDestinationSelected: (i) =>
            setState(() => _seccion = SeccionUsuario.values[i]),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.storefront_outlined),
            selectedIcon: Icon(Icons.storefront),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Pedidos',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            selectedIcon: Icon(Icons.chat_bubble),
            label: 'Chats',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}
