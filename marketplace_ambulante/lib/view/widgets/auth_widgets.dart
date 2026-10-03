import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';

/// Nombre de la app + título + subtítulo de las pantallas de cuenta.
class EncabezadoAuth extends StatelessWidget {
  const EncabezadoAuth({
    super.key,
    required this.titulo,
    required this.subtitulo,
  });

  final String titulo;
  final String subtitulo;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          AppConstants.nombreApp,
          textAlign: TextAlign.center,
          style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 64),
        Text(
          titulo,
          textAlign: TextAlign.center,
          style: text.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Text(
          subtitulo,
          textAlign: TextAlign.center,
          style: text.bodySmall?.copyWith(color: AppColors.grisTexto),
        ),
      ],
    );
  }
}

/// Campo de contraseña con botón para mostrar/ocultar.
class CampoPassword extends StatefulWidget {
  const CampoPassword({
    super.key,
    required this.controller,
    required this.hint,
    required this.validator,
    this.enabled = true,
    this.textInputAction = TextInputAction.next,
    this.autofillHints,
    this.onChanged,
    this.onFieldSubmitted,
  });

  final TextEditingController controller;
  final String hint;
  final FormFieldValidator<String> validator;
  final bool enabled;
  final TextInputAction textInputAction;
  final Iterable<String>? autofillHints;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onFieldSubmitted;

  @override
  State<CampoPassword> createState() => _CampoPasswordState();
}

class _CampoPasswordState extends State<CampoPassword> {
  bool _oculta = true;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      enabled: widget.enabled,
      obscureText: _oculta,
      autocorrect: false,
      enableSuggestions: false,
      textInputAction: widget.textInputAction,
      autofillHints: autofillSeguro(widget.autofillHints),
      validator: widget.validator,
      onChanged: widget.onChanged,
      onFieldSubmitted: widget.onFieldSubmitted,
      decoration: InputDecoration(
        hintText: widget.hint,
        suffixIcon: IconButton(
          tooltip: _oculta ? 'Mostrar contraseña' : 'Ocultar contraseña',
          icon: Icon(
            _oculta ? Icons.visibility_outlined : Icons.visibility_off_outlined,
            color: AppColors.grisTexto,
          ),
          onPressed: () => setState(() => _oculta = !_oculta),
        ),
      ),
    );
  }
}

/// Botón negro principal que muestra un spinner mientras [cargando].
class BotonPrincipal extends StatelessWidget {
  const BotonPrincipal({
    super.key,
    required this.texto,
    required this.onPressed,
    this.cargando = false,
  });

  final String texto;
  final VoidCallback onPressed;
  final bool cargando;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: cargando ? null : onPressed,
      child: cargando
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.grisTexto,
              ),
            )
          : Text(texto),
    );
  }
}

/// "¿Ya tienes cuenta? Inicia sesión" / "¿No tienes cuenta? Regístrate".
class EnlaceAuth extends StatelessWidget {
  const EnlaceAuth({
    super.key,
    required this.pregunta,
    required this.accion,
    required this.onTap,
  });

  final String pregunta;
  final String accion;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    // Wrap (no Row): si no cabe en una línea, el botón baja a la siguiente
    // en vez de desbordarse en pantallas angostas.
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(pregunta, style: const TextStyle(color: AppColors.grisTexto)),
        TextButton(
          onPressed: onTap,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.negro,
            padding: const EdgeInsets.symmetric(horizontal: 4),
          ),
          child: Text(
            accion,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

/// Pistas de autocompletado solo en Android/iOS.
///
/// En web (Edge/Chrome) el gestor de contraseñas del navegador toma control
/// de los campos con pistas como `newPassword` y, cuando el formulario se
/// redibuja (por ejemplo al mostrar un error), el campo deja de aceptar texto.
Iterable<String>? autofillSeguro(Iterable<String>? hints) =>
    kIsWeb ? null : hints;

/// Muestra un mensaje en la parte inferior (SnackBar).
void mostrarMensaje(BuildContext context, String mensaje) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(mensaje)));
}
