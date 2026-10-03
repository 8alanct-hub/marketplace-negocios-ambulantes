import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/router/app_router.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/formato.dart';
import '../core/utils/validators.dart';
import '../model/imagen_service.dart';
import '../model/negocio.dart';
import '../model/producto.dart';
import '../viewmodel/configuracion_negocio_state.dart';
import '../viewmodel/configuracion_negocio_viewmodel.dart';
import '../viewmodel/marketplace_viewmodel.dart';
import '../viewmodel/panel_negocio_viewmodel.dart';
import '../viewmodel/resultado.dart';
import '../viewmodel/sesion_viewmodel.dart';
import 'producto_form_sheet.dart';
import 'widgets/auth_widgets.dart';
import 'widgets/estado_widgets.dart';
import 'widgets/permisos_widgets.dart';
import 'widgets/seleccion_widgets.dart';

/// View: "Configuración de negocio".
///
/// - Portada / logo   → menú Cámara o Galería
/// - Ubicación        → GPS (fijo: marcar el local; ambulante: actualizar)
/// - Formas de pago   → Pago en el negocio / Contraentrega
/// - Tipo             → Fijo / Ambulante (se puede cambiar)
/// - Productos        → formulario desde abajo (se guardan al momento)
/// - Guardar cambios  → Panel del negocio
/// - Atrás con cambios sin guardar → advertencia
class ConfiguracionNegocioScreen extends ConsumerStatefulWidget {
  const ConfiguracionNegocioScreen({super.key});

  @override
  ConsumerState<ConfiguracionNegocioScreen> createState() =>
      _ConfiguracionNegocioScreenState();
}

class _ConfiguracionNegocioScreenState
    extends ConsumerState<ConfiguracionNegocioScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _descripcionCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  final _direccionCtrl = TextEditingController();
  bool _camposListos = false;
  bool _validarAlEscribir = false;

  ConfiguracionNegocioViewModel get _vm =>
      ref.read(configuracionNegocioViewModelProvider.notifier);

  @override
  void initState() {
    super.initState();
    // Cuando terminan de cargar los datos, se llenan los campos (una vez).
    ref.listenManual(
      configuracionNegocioViewModelProvider,
      (anterior, siguiente) {
        final datos = siguiente.value;
        if (datos == null || _camposListos) return;
        _camposListos = true;
        _nombreCtrl.text = datos.negocio.nombre;
        _descripcionCtrl.text = datos.negocio.descripcion;
        _telefonoCtrl.text = datos.negocio.telefono;
        _direccionCtrl.text = datos.negocio.direccion;
      },
      fireImmediately: true,
    );
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _descripcionCtrl.dispose();
    _telefonoCtrl.dispose();
    _direccionCtrl.dispose();
    super.dispose();
  }

  Future<void> _procesar(Resultado resultado) async {
    if (!mounted) return;
    await procesarResultado(context, resultado, abrirAjustes: _vm.abrirAjustes);
  }

  Future<void> _cambiarPortada() async {
    final fuente = await elegirFuenteImagen(context, titulo: 'Foto de portada');
    if (fuente == null) return;
    await _procesar(await _vm.elegirPortada(fuente));
  }

  Future<void> _cambiarLogo() async {
    final fuente = await elegirFuenteImagen(context, titulo: 'Logo del negocio');
    if (fuente == null) return;
    await _procesar(await _vm.elegirLogo(fuente));
  }

  /// true si hay algo editado que todavía no se guardó.
  bool get _hayCambios {
    final s = ref.read(configuracionNegocioViewModelProvider).value;
    if (s == null) return false;
    return s.hayCambios(
      nombre: _nombreCtrl.text,
      descripcion: _descripcionCtrl.text,
      telefono: _telefonoCtrl.text,
      direccion: _direccionCtrl.text,
    );
  }

  /// Botón atrás (de la barra o del teléfono).
  Future<void> _alIntentarSalir() async {
    if (_hayCambios) {
      final salir = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('¿Salir sin guardar?'),
          content: const Text(
            'Tienes cambios sin guardar. Si sales ahora, se perderán.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Seguir editando'),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: AppColors.error),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Salir sin guardar'),
            ),
          ],
        ),
      );
      if (salir != true || !mounted) return;
      // Descarta lo editado: la próxima vez carga lo guardado.
      ref.invalidate(configuracionNegocioViewModelProvider);
    }
    if (!mounted) return;
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.panelNegocio);
    }
  }

  Future<void> _actualizarUbicacion() async {
    await _procesar(await _vm.actualizarUbicacion());
  }

  Future<void> _guardar() async {
    FocusScope.of(context).unfocus();
    setState(() => _validarAlEscribir = true);
    if (!(_formKey.currentState?.validate() ?? false)) {
      mostrarMensaje(context, 'Revisa los campos marcados en rojo.');
      return;
    }
    final resultado = await _vm.guardar(
      nombre: _nombreCtrl.text,
      descripcion: _descripcionCtrl.text,
      telefono: _telefonoCtrl.text,
      direccion: _direccionCtrl.text,
    );
    if (!mounted) return;
    if (resultado is Exito) {
      // El panel muestra el nombre y la ubicación: que los vuelva a cargar.
      ref.invalidate(panelNegocioViewModelProvider);
      // El Marketplace muestra el logo, nombre y ubicación: que recargue.
      ref.invalidate(marketplaceViewModelProvider);
      mostrarMensaje(context, 'Cambios guardados');
      context.go(AppRoutes.panelNegocio);
    } else {
      await _procesar(resultado);
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(configuracionNegocioViewModelProvider);
    final datos = async.value;

    // canPop: false → al ir atrás se llama a _alIntentarSalir, que decide
    // si advierte o sale directo.
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _alIntentarSalir();
      },
      child: Scaffold(
      appBar: AppBar(title: const Text('Configura tu negocio')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorCarga(
          mensaje: error.toString(),
          onReintentar: () =>
              ref.invalidate(configuracionNegocioViewModelProvider),
          accionExtra: TextButton(
            onPressed: () {
              ref.read(sesionProvider.notifier).cerrar();
              context.go(AppRoutes.iniciarSesion);
            },
            child: const Text('Cerrar sesión'),
          ),
        ),
        data: _contenido,
      ),
      bottomNavigationBar: datos == null
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Center(
                  heightFactor: 1,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: _anchoMaximo),
                    child: BotonPrincipal(
                      texto: 'Guardar cambios',
                      cargando: datos.guardando,
                      onPressed: _guardar,
                    ),
                  ),
                ),
              ),
            ),
      ),
    );
  }

  Widget _contenido(ConfiguracionNegocioState s) {
    final esFijo = s.negocio.tipo == TipoNegocio.fijo;

    return Form(
      key: _formKey,
      autovalidateMode: _validarAlEscribir
          ? AutovalidateMode.onUserInteraction
          : AutovalidateMode.disabled,
      // En pantallas anchas (web/tablet) el contenido no pasa de 600 px.
      child: ListView(
        padding: EdgeInsets.fromLTRB(
          16 + _margenLateral(context),
          8,
          16 + _margenLateral(context),
          24,
        ),
        children: [
          _Portada(
            estado: s,
            onCambiarPortada: s.ocupado ? null : _cambiarPortada,
            onCambiarLogo: s.ocupado ? null : _cambiarLogo,
          ),

          // ------------------------------------------------- Tipo
          _Seccion(
            titulo: 'Tipo de negocio',
            descripcion: '¿Atiendes en un local o te mueves por la ciudad?',
            children: [
              SegmentedButton<TipoNegocio>(
                expandedInsets: EdgeInsets.zero,
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(
                    value: TipoNegocio.fijo,
                    label: Text('Fijo'),
                    icon: Icon(Icons.store_mall_directory_outlined),
                  ),
                  ButtonSegment(
                    value: TipoNegocio.ambulante,
                    label: Text('Ambulante'),
                    icon: IconoAsset(IconosApp.carritoAmbulante, size: 18),
                  ),
                ],
                selected: {s.negocio.tipo},
                onSelectionChanged:
                    s.ocupado ? null : (sel) => _vm.cambiarTipo(sel.first),
              ),
            ],
          ),

          // ------------------------------------------------ Datos
          _Seccion(
            titulo: 'Datos del negocio',
            children: [
              TextFormField(
                controller: _nombreCtrl,
                enabled: !s.ocupado,
                textCapitalization: TextCapitalization.words,
                decoration:
                    const InputDecoration(labelText: 'Nombre del negocio'),
                validator: Validators.nombreComercial,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descripcionCtrl,
                enabled: !s.ocupado,
                textCapitalization: TextCapitalization.sentences,
                maxLines: 3,
                maxLength: 300,
                decoration: const InputDecoration(
                  labelText: 'Descripción',
                  hintText: 'Cuéntale a tus clientes qué ofreces',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 4),
              TextFormField(
                controller: _telefonoCtrl,
                enabled: !s.ocupado,
                keyboardType: TextInputType.phone,
                decoration:
                    const InputDecoration(labelText: 'Teléfono de contacto'),
                validator: Validators.telefono,
              ),
            ],
          ),

          // -------------------------------------------- Ubicación
          _Seccion(
            titulo: 'Ubicación',
            descripcion: esFijo
                ? 'Escribe la dirección de tu local y marca su punto en el '
                    'mapa estando allí.'
                : 'Como te mueves, actualiza tu ubicación cada vez que '
                    'cambies de lugar para que los clientes cercanos te '
                    'encuentren.',
            children: [
              if (esFijo) ...[
                TextFormField(
                  controller: _direccionCtrl,
                  enabled: !s.ocupado,
                  decoration: const InputDecoration(
                    labelText: 'Dirección del local',
                    hintText: 'Ej: Cra 7 # 45-10, Chapinero',
                  ),
                  validator: (v) =>
                      Validators.requerido(v, 'Ingresa la dirección del local'),
                ),
                const SizedBox(height: 12),
              ],
              _EstadoUbicacion(negocio: s.negocio),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: s.ocupado ? null : _actualizarUbicacion,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.negro,
                  side: const BorderSide(color: AppColors.grisBorde),
                  minimumSize: const Size.fromHeight(44),
                ),
                icon: s.ubicando
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.my_location),
                label: Text(
                  !esFijo
                      ? 'Actualizar mi ubicación'
                      : s.negocio.tieneUbicacion
                          ? 'Volver a marcar con mi ubicación actual'
                          : 'Usar mi ubicación actual',
                ),
              ),
            ],
          ),

          // --------------------------------------- Formas de pago
          _Seccion(
            titulo: 'Formas de pago que aceptas',
            descripcion:
                'La app no procesa pagos: el cliente te paga directamente.',
            children: [
              for (final m in s.modalidades)
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  value: s.modalidadesElegidas.contains(m.id),
                  onChanged:
                      s.ocupado ? null : (_) => _vm.alternarModalidad(m.id),
                  title: Text(m.nombre),
                  subtitle: Text(
                    m.descripcion,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
            ],
          ),

          // -------------------------------------------- Productos
          _Seccion(
            titulo: 'Productos del negocio',
            descripcion: s.productos.isEmpty
                ? 'Agrega el primero para que los clientes puedan pedirlo.'
                : 'Toca un producto para editarlo o eliminarlo.',
            children: [
              SizedBox(
                height: 200,
                // El primer cuadro siempre es "Agregar"; después, los productos.
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: s.productos.length + 1,
                  separatorBuilder: (_, _) => const SizedBox(width: 12),
                  itemBuilder: (context, i) {
                    if (i == 0) {
                      return _TarjetaAgregar(
                        onTap: () => mostrarFormularioProducto(context),
                      );
                    }
                    final p = s.productos[i - 1];
                    return _TarjetaProducto(
                      producto: p,
                      onTap: () =>
                          mostrarFormularioProducto(context, producto: p),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ======================================================= Widgets privados

const double _anchoMaximo = 600;

/// Margen extra a cada lado para que el contenido quede centrado y no pase
/// de [_anchoMaximo] en pantallas anchas. En el celular es 0.
double _margenLateral(BuildContext context) {
  final ancho = MediaQuery.sizeOf(context).width;
  return ancho > _anchoMaximo + 32 ? (ancho - _anchoMaximo - 32) / 2 : 0;
}

class _Seccion extends StatelessWidget {
  const _Seccion({
    required this.titulo,
    required this.children,
    this.descripcion,
  });

  final String titulo;
  final String? descripcion;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            titulo,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          if (descripcion != null) ...[
            const SizedBox(height: 2),
            Text(
              descripcion!,
              style: const TextStyle(fontSize: 12, color: AppColors.grisTexto),
            ),
          ],
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

/// Portada con el logo encima (esquina inferior izquierda).
class _Portada extends StatelessWidget {
  const _Portada({
    required this.estado,
    required this.onCambiarPortada,
    required this.onCambiarLogo,
  });

  final ConfiguracionNegocioState estado;
  final VoidCallback? onCambiarPortada;
  final VoidCallback? onCambiarLogo;

  Widget? _imagen(ImagenElegida? nueva, String? url) {
    if (nueva != null) {
      return Image.memory(nueva.bytes, fit: BoxFit.cover, gaplessPlayback: true);
    }
    if (url != null) return ImagenDesdeUrl(url: url);
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final portada =
        _imagen(estado.portadaNueva, estado.negocio.bannerUrl);
    final logo = _imagen(estado.logoNuevo, estado.negocio.logoUrl);

    return Stack(
      children: [
        // Espacio inferior para que el logo quede dentro del Stack
        // (si se sale, no recibiría los toques).
        Padding(
          padding: const EdgeInsets.only(bottom: 40),
          child: Material(
            color: AppColors.grisFondo,
            borderRadius: BorderRadius.circular(12),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onCambiarPortada,
              child: AspectRatio(
                aspectRatio: 16 / 7,
                child: portada ??
                    const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_photo_alternate_outlined,
                          color: AppColors.grisTexto,
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Agrega una foto de portada',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.grisTexto,
                          ),
                        ),
                      ],
                    ),
              ),
            ),
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: _BotonCamara(
            tooltip: 'Cambiar portada',
            onPressed: onCambiarPortada,
          ),
        ),
        Positioned(
          left: 16,
          bottom: 0,
          child: GestureDetector(
            onTap: onCambiarLogo,
            child: Stack(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.grisFondo,
                    border: Border.all(color: AppColors.blanco, width: 3),
                  ),
                  child: logo ??
                      const Icon(
                        Icons.storefront_outlined,
                        color: AppColors.grisTexto,
                        size: 32,
                      ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: _BotonCamara(
                    tooltip: 'Cambiar logo',
                    onPressed: onCambiarLogo,
                    pequeno: true,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _BotonCamara extends StatelessWidget {
  const _BotonCamara({
    required this.tooltip,
    required this.onPressed,
    this.pequeno = false,
  });

  final String tooltip;
  final VoidCallback? onPressed;
  final bool pequeno;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.blanco,
      shape: const CircleBorder(side: BorderSide(color: AppColors.grisBorde)),
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        iconSize: pequeno ? 16 : 20,
        visualDensity: pequeno ? VisualDensity.compact : null,
        constraints: pequeno
            ? const BoxConstraints.tightFor(width: 28, height: 28)
            : null,
        padding: pequeno ? EdgeInsets.zero : null,
        icon: const Icon(Icons.photo_camera_outlined, color: AppColors.negro),
      ),
    );
  }
}

class _EstadoUbicacion extends StatelessWidget {
  const _EstadoUbicacion({required this.negocio});
  final Negocio negocio;

  @override
  Widget build(BuildContext context) {
    final tiene = negocio.tieneUbicacion;
    final actualizada = negocio.ubicacionActualizada;

    var texto = 'Aún no has marcado la ubicación';
    if (tiene) {
      final lat = negocio.latitud!.toStringAsFixed(5);
      final lng = negocio.longitud!.toStringAsFixed(5);
      texto = 'Ubicación marcada ($lat, $lng)';
      if (actualizada != null) {
        texto += '\nActualizada ${Formato.haceCuanto(actualizada)}';
      }
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          tiene ? Icons.location_on : Icons.location_off_outlined,
          size: 20,
          color: tiene ? AppColors.negro : AppColors.grisTexto,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            texto,
            style: TextStyle(
              fontSize: 13,
              color: tiene ? AppColors.negro : AppColors.grisTexto,
            ),
          ),
        ),
      ],
    );
  }
}

class _TarjetaProducto extends StatelessWidget {
  const _TarjetaProducto({required this.producto, required this.onTap});

  final Producto producto;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final aviso = producto.agotado
        ? 'Agotado'
        : !producto.disponible
            ? 'No disponible'
            : null;

    return SizedBox(
      width: 120,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 120,
                height: 120,
                child: producto.imagenUrl != null
                    ? ImagenDesdeUrl(url: producto.imagenUrl!)
                    : const ColoredBox(
                        color: AppColors.grisFondo,
                        child: Icon(
                          Icons.image_outlined,
                          color: AppColors.grisTexto,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              producto.nombre,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            Text(
              Formato.precio(producto.precio),
              style: const TextStyle(fontSize: 12),
            ),
            if (aviso != null)
              Text(
                aviso,
                style: const TextStyle(fontSize: 11, color: AppColors.error),
              ),
          ],
        ),
      ),
    );
  }
}

/// Cuadro del mismo tamaño que un producto, con "+" y el texto "Agregar".
class _TarjetaAgregar extends StatelessWidget {
  const _TarjetaAgregar({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.grisFondo,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.grisBorde),
              ),
              child: const Icon(
                Icons.add,
                size: 36,
                color: AppColors.negro,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Agregar',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const Text(
              'Nuevo producto',
              style: TextStyle(fontSize: 12, color: AppColors.grisTexto),
            ),
          ],
        ),
      ),
    );
  }
}
