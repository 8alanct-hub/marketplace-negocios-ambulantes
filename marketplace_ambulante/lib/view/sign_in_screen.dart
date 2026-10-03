import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/router/app_router.dart';
import '../core/utils/validators.dart';
import '../viewmodel/estado_formulario.dart';
import '../viewmodel/sign_in_viewmodel.dart';
import 'widgets/auth_widgets.dart';

/// View: "Iniciar sesión".
///
/// - "Iniciar sesión" → según la cuenta:
///     sin rol  → ¿Eres un?
///     usuario  → Marketplace
///     negocio  → Panel del negocio
/// - "Regístrate"     → Crear cuenta
class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key, this.emailInicial});

  /// Correo que viene escrito desde "Crear cuenta".
  final String? emailInicial;

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _formKey = GlobalKey<FormState>();

  /// Después del primer intento, los errores se actualizan al escribir.
  bool _validarAlEscribir = false;
  late final _emailCtrl = TextEditingController(text: widget.emailInicial);
  final _passwordCtrl = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _limpiarError(String _) =>
      ref.read(signInViewModelProvider.notifier).limpiarError();

  Future<void> _iniciarSesion() async {
    FocusScope.of(context).unfocus();
    setState(() => _validarAlEscribir = true);
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final usuario = await ref
        .read(signInViewModelProvider.notifier)
        .iniciarSesion(email: _emailCtrl.text, password: _passwordCtrl.text);

    if (!mounted || usuario == null) return;
    // go() reemplaza la pila: "atrás" no regresa a esta pantalla.
    context.go(AppRoutes.segunUsuario(usuario));
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(signInViewModelProvider);

    ref.listen<EstadoFormulario>(signInViewModelProvider, (prev, next) {
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
                        titulo: 'Inicia sesión',
                        subtitulo: 'Ingresa tu correo electrónico y tu '
                            'contraseña para continuar',
                      ),
                      const SizedBox(height: 16),
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
                        textInputAction: TextInputAction.done,
                        autofillHints: const [AutofillHints.password],
                        validator: Validators.passwordRequerida,
                        onChanged: _limpiarError,
                        onFieldSubmitted: (_) => _iniciarSesion(),
                      ),
                      const SizedBox(height: 16),
                      BotonPrincipal(
                        texto: 'Iniciar sesión',
                        cargando: state.cargando,
                        onPressed: _iniciarSesion,
                      ),
                      const SizedBox(height: 8),
                      EnlaceAuth(
                        pregunta: '¿No tienes cuenta?',
                        accion: 'Regístrate',
                        onTap: state.cargando
                            ? null
                            : () => context.go(AppRoutes.registro),
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
