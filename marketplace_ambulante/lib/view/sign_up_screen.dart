import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/router/app_router.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/validators.dart';
import '../viewmodel/estado_formulario.dart';
import '../viewmodel/sign_up_viewmodel.dart';
import 'widgets/auth_widgets.dart';

/// View: "Crear cuenta".
///
/// - "Crear cuenta"   → crea la cuenta → Iniciar sesión (con el correo escrito)
/// - "Inicia sesión"  → Iniciar sesión
class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();

  /// Después del primer intento, los errores se actualizan al escribir.
  bool _validarAlEscribir = false;
  final _nombreCtrl = TextEditingController();
  final _apellidoCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmarCtrl = TextEditingController();

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _apellidoCtrl.dispose();
    _telefonoCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmarCtrl.dispose();
    super.dispose();
  }

  void _limpiarError(String _) =>
      ref.read(signUpViewModelProvider.notifier).limpiarError();

  Future<void> _crearCuenta() async {
    FocusScope.of(context).unfocus();
    setState(() => _validarAlEscribir = true);
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final email = _emailCtrl.text.trim();
    final creada = await ref
        .read(signUpViewModelProvider.notifier)
        .registrar(
          nombre: _nombreCtrl.text,
          apellido: _apellidoCtrl.text,
          telefono: _telefonoCtrl.text,
          email: email,
          password: _passwordCtrl.text,
        );

    if (!mounted || !creada) return;
    mostrarMensaje(context, 'Cuenta creada. Ahora inicia sesión.');
    context.go(AppRoutes.iniciarSesion, extra: email);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(signUpViewModelProvider);

    // Efectos (mostrar error) van en listen, no dentro de build.
    ref.listen<EstadoFormulario>(signUpViewModelProvider, (prev, next) {
      if (next.error != null && next.error != prev?.error) {
        mostrarMensaje(context, next.error!);
      }
    });

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Form(
                key: _formKey,
                autovalidateMode: _validarAlEscribir
                    ? AutovalidateMode.onUserInteraction
                    : AutovalidateMode.disabled,
                child: AutofillGroup(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const EncabezadoAuth(
                        titulo: 'Crea una cuenta',
                        subtitulo: 'Completa tus datos para registrarte '
                            'en esta aplicación',
                      ),
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _nombreCtrl,
                              enabled: !state.cargando,
                              textCapitalization: TextCapitalization.words,
                              textInputAction: TextInputAction.next,
                              autofillHints: autofillSeguro(
                                const [AutofillHints.givenName],
                              ),
                              decoration:
                                  const InputDecoration(hintText: 'Nombre'),
                              validator: (v) => Validators.nombre(v),
                              onChanged: _limpiarError,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _apellidoCtrl,
                              enabled: !state.cargando,
                              textCapitalization: TextCapitalization.words,
                              textInputAction: TextInputAction.next,
                              autofillHints: autofillSeguro(
                                const [AutofillHints.familyName],
                              ),
                              decoration:
                                  const InputDecoration(hintText: 'Apellido'),
                              validator: (v) =>
                                  Validators.nombre(v, campo: 'tu apellido'),
                              onChanged: _limpiarError,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _telefonoCtrl,
                        enabled: !state.cargando,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.next,
                        autofillHints: autofillSeguro(
                          const [AutofillHints.telephoneNumber],
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Teléfono',
                        ),
                        validator: Validators.telefono,
                        onChanged: _limpiarError,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _emailCtrl,
                        enabled: !state.cargando,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        autofillHints: autofillSeguro(const [AutofillHints.email]),
                        autocorrect: false,
                        decoration: const InputDecoration(
                          hintText: 'correo@dominio.com',
                        ),
                        validator: Validators.email,
                        onChanged: _limpiarError,
                      ),
                      const SizedBox(height: 12),
                      CampoPassword(
                        controller: _passwordCtrl,
                        enabled: !state.cargando,
                        hint: 'Contraseña',
                        autofillHints: const [AutofillHints.newPassword],
                        validator: Validators.passwordNueva,
                        onChanged: _limpiarError,
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Mínimo ${Validators.minPassword} caracteres, '
                        'con letras y números',
                        style:
                            TextStyle(fontSize: 12, color: AppColors.grisTexto),
                      ),
                      const SizedBox(height: 12),
                      CampoPassword(
                        controller: _confirmarCtrl,
                        enabled: !state.cargando,
                        hint: 'Confirmar contraseña',
                        textInputAction: TextInputAction.done,
                        validator: (v) =>
                            Validators.confirmarPassword(v, _passwordCtrl.text),
                        onChanged: _limpiarError,
                        onFieldSubmitted: (_) => _crearCuenta(),
                      ),
                      const SizedBox(height: 16),
                      BotonPrincipal(
                        texto: 'Crear cuenta',
                        cargando: state.cargando,
                        onPressed: _crearCuenta,
                      ),
                      const SizedBox(height: 8),
                      EnlaceAuth(
                        pregunta: '¿Ya tienes cuenta?',
                        accion: 'Inicia sesión',
                        onTap: state.cargando
                            ? null
                            : () => context.go(AppRoutes.iniciarSesion),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Al continuar, aceptas nuestros Términos de servicio '
                        'y la Política de privacidad',
                        textAlign: TextAlign.center,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: AppColors.grisTexto),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
