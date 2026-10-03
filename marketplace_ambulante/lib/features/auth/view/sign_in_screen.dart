import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/validators.dart';
import '../viewmodel/sign_in_state.dart';
import '../viewmodel/sign_in_viewmodel.dart';

/// Pantalla de entrada.
///
/// - "Continuar"      → crea cuenta → "¿Eres un?" (elegir rol)
/// - "Iniciar sesión" → cuenta existente → Marketplace o Panel del negocio
class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _enviar(SignInAccion accion) async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final vm = ref.read(signInViewModelProvider.notifier);
    final email = _emailCtrl.text;
    final usuario = accion == SignInAccion.registrar
        ? await vm.registrar(email)
        : await vm.iniciarSesion(email);

    if (!mounted || usuario == null) return;
    // go() reemplaza la pila: el usuario no puede "volver" al Sign In.
    context.go(AppRoutes.segunUsuario(usuario));
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(signInViewModelProvider);

    // Efectos secundarios (SnackBar) van en listen, no en build.
    ref.listen<SignInState>(signInViewModelProvider, (prev, next) {
      final error = next.error;
      if (error != null && error != prev?.error) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(error)));
      }
    });

    final text = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      AppConstants.nombreApp,
                      textAlign: TextAlign.center,
                      style: text.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 96),
                    Text(
                      'Crea una cuenta',
                      textAlign: TextAlign.center,
                      style: text.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Ingresa tu correo electrónico para registrarte '
                      'en esta aplicación',
                      textAlign: TextAlign.center,
                      style:
                          text.bodySmall?.copyWith(color: AppColors.grisTexto),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailCtrl,
                      enabled: !state.cargando,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.email],
                      autocorrect: false,
                      decoration: const InputDecoration(
                        hintText: 'correo@dominio.com',
                      ),
                      validator: Validators.email,
                      onChanged: (_) => ref
                          .read(signInViewModelProvider.notifier)
                          .limpiarError(),
                      onFieldSubmitted: (_) => _enviar(SignInAccion.registrar),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: state.cargando
                          ? null
                          : () => _enviar(SignInAccion.registrar),
                      child: state.accionEnCurso == SignInAccion.registrar
                          ? const _Spinner()
                          : const Text('Continuar'),
                    ),
                    const _Separador(),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.grisFondo,
                        foregroundColor: AppColors.negro,
                      ),
                      onPressed: state.cargando
                          ? null
                          : () => _enviar(SignInAccion.iniciarSesion),
                      child: state.accionEnCurso == SignInAccion.iniciarSesion
                          ? const _Spinner()
                          : const Text('Iniciar sesión'),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Al continuar, aceptas nuestros Términos de servicio '
                      'y la Política de privacidad',
                      textAlign: TextAlign.center,
                      style:
                          text.bodySmall?.copyWith(color: AppColors.grisTexto),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Separador extends StatelessWidget {
  const _Separador();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(child: Divider(color: AppColors.grisBorde)),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Text('o', style: TextStyle(color: AppColors.grisTexto)),
          ),
          Expanded(child: Divider(color: AppColors.grisBorde)),
        ],
      ),
    );
  }
}

class _Spinner extends StatelessWidget {
  const _Spinner();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 18,
      height: 18,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        color: AppColors.grisTexto,
      ),
    );
  }
}
