import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_theme.dart';
import '../core/utils/validators.dart';
import '../model/imagen_service.dart';
import '../model/producto.dart';
import '../viewmodel/configuracion_negocio_viewmodel.dart';
import '../viewmodel/resultado.dart';
import 'widgets/auth_widgets.dart';
import 'widgets/permisos_widgets.dart';

/// Abre el formulario para agregar (o editar, si se pasa [producto]).
Future<void> mostrarFormularioProducto(
  BuildContext context, {
  Producto? producto,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (_) => ProductoFormSheet(producto: producto),
  );
}

/// View: formulario de producto (se muestra desde abajo).
class ProductoFormSheet extends ConsumerStatefulWidget {
  const ProductoFormSheet({super.key, this.producto});

  final Producto? producto;

  @override
  ConsumerState<ProductoFormSheet> createState() => _ProductoFormSheetState();
}

class _ProductoFormSheetState extends ConsumerState<ProductoFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _nombreCtrl = TextEditingController(text: widget.producto?.nombre);
  late final _descripcionCtrl =
      TextEditingController(text: widget.producto?.descripcion);
  late final _precioCtrl = TextEditingController(
    text: widget.producto?.precio.round().toString(),
  );
  late final _stockCtrl = TextEditingController(
    text: widget.producto?.stock.toString(),
  );
  late String? _categoriaId = widget.producto?.categoriaId;
  late bool _disponible = widget.producto?.disponible ?? true;
  ImagenElegida? _imagenNueva;
  bool _guardando = false;

  bool get _esNuevo => widget.producto == null;

  ConfiguracionNegocioViewModel get _vm =>
      ref.read(configuracionNegocioViewModelProvider.notifier);

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _descripcionCtrl.dispose();
    _precioCtrl.dispose();
    _stockCtrl.dispose();
    super.dispose();
  }

  /// Cierra el formulario y muestra el mensaje en la pantalla de atrás.
  void _cerrarConMensaje(String mensaje) {
    final messenger = ScaffoldMessenger.of(context);
    Navigator.pop(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(mensaje)));
  }

  Future<void> _elegirFoto() async {
    final fuente = await elegirFuenteImagen(context, titulo: 'Foto del producto');
    if (fuente == null) return;
    final (imagen, resultado) = await _vm.obtenerImagen(fuente);
    if (!mounted) return;
    if (imagen != null) {
      setState(() => _imagenNueva = imagen);
    } else {
      await procesarResultado(context, resultado, abrirAjustes: _vm.abrirAjustes);
    }
  }

  Future<void> _guardar() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _guardando = true);
    final resultado = await _vm.guardarProducto(
      existente: widget.producto,
      nombre: _nombreCtrl.text,
      descripcion: _descripcionCtrl.text,
      categoriaId: _categoriaId!,
      precio: double.parse(_precioCtrl.text),
      stock: int.parse(_stockCtrl.text),
      disponible: _disponible,
      imagenNueva: _imagenNueva,
    );
    if (!mounted) return;
    setState(() => _guardando = false);
    if (resultado is Exito) {
      _cerrarConMensaje(_esNuevo ? 'Producto agregado' : 'Producto actualizado');
    } else {
      await procesarResultado(context, resultado, abrirAjustes: _vm.abrirAjustes);
    }
  }

  Future<void> _eliminar() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar producto?'),
        content: Text('"${widget.producto!.nombre}" dejará de aparecer en tu '
            'negocio.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmar != true || !mounted) return;
    setState(() => _guardando = true);
    final resultado = await _vm.eliminarProducto(widget.producto!.id);
    if (!mounted) return;
    setState(() => _guardando = false);
    if (resultado is Exito) {
      _cerrarConMensaje('Producto eliminado');
    } else {
      await procesarResultado(context, resultado, abrirAjustes: _vm.abrirAjustes);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categorias =
        ref.watch(configuracionNegocioViewModelProvider).value?.categorias ??
            const [];

    return Padding(
      // Sube el formulario cuando aparece el teclado.
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _esNuevo ? 'Agregar producto' : 'Editar producto',
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              Center(
                child: _FotoProducto(
                  imagenNueva: _imagenNueva,
                  url: widget.producto?.imagenUrl,
                  onTap: _guardando ? null : _elegirFoto,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nombreCtrl,
                enabled: !_guardando,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(labelText: 'Nombre'),
                validator: (v) =>
                    Validators.requerido(v, 'Ingresa el nombre del producto'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descripcionCtrl,
                enabled: !_guardando,
                textCapitalization: TextCapitalization.sentences,
                maxLines: 2,
                maxLength: 200,
                decoration: const InputDecoration(
                  labelText: 'Descripción (opcional)',
                ),
              ),
              const SizedBox(height: 4),
              DropdownButtonFormField<String>(
                initialValue: _categoriaId,
                decoration: const InputDecoration(labelText: 'Categoría'),
                items: [
                  for (final c in categorias)
                    DropdownMenuItem(value: c.id, child: Text(c.nombre)),
                ],
                onChanged:
                    _guardando ? null : (v) => setState(() => _categoriaId = v),
                validator: (v) => v == null ? 'Elige una categoría' : null,
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _precioCtrl,
                      enabled: !_guardando,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                        labelText: 'Precio',
                        prefixText: '\$ ',
                      ),
                      validator: Validators.precio,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _stockCtrl,
                      enabled: !_guardando,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                        labelText: 'Cantidad disponible',
                      ),
                      validator: Validators.stock,
                    ),
                  ),
                ],
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _disponible,
                onChanged:
                    _guardando ? null : (v) => setState(() => _disponible = v),
                title: const Text('Disponible para pedidos'),
                subtitle: const Text(
                  'Si lo apagas, los clientes lo verán pero no podrán pedirlo',
                  style: TextStyle(fontSize: 12),
                ),
              ),
              const SizedBox(height: 8),
              BotonPrincipal(
                texto: _esNuevo ? 'Agregar producto' : 'Guardar producto',
                cargando: _guardando,
                onPressed: _guardar,
              ),
              if (!_esNuevo)
                TextButton(
                  style: TextButton.styleFrom(foregroundColor: AppColors.error),
                  onPressed: _guardando ? null : _eliminar,
                  child: const Text('Eliminar producto'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FotoProducto extends StatelessWidget {
  const _FotoProducto({
    required this.imagenNueva,
    required this.url,
    required this.onTap,
  });

  final ImagenElegida? imagenNueva;
  final String? url;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Widget contenido;
    if (imagenNueva != null) {
      contenido = Image.memory(imagenNueva!.bytes, fit: BoxFit.cover);
    } else if (url != null) {
      contenido = ImagenDesdeUrl(url: url!);
    } else {
      contenido = const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_a_photo_outlined, color: AppColors.grisTexto),
          SizedBox(height: 4),
          Text(
            'Agregar foto',
            style: TextStyle(fontSize: 12, color: AppColors.grisTexto),
          ),
        ],
      );
    }
    return Material(
      color: AppColors.grisFondo,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(width: 120, height: 120, child: contenido),
      ),
    );
  }
}
