import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import 'package:conecta_utsh/helpers/style.dart';
import 'package:conecta_utsh/modules/app/components/app_text_field.dart';
import 'package:conecta_utsh/modules/app/components/primary_button.dart';
import 'package:conecta_utsh/modules/app/models/password_reset_model.dart';
import 'package:conecta_utsh/modules/app/screens/forgot_password_code_screen.dart';
import 'package:conecta_utsh/modules/app/services/auth_service.dart';
import 'package:conecta_utsh/modules/app/services/password_reset_state_store.dart';
import 'package:conecta_utsh/utils/widgets/dialogs.dart';

class ForgotPasswordEmailScreen extends StatefulWidget {
  const ForgotPasswordEmailScreen({
    required this.authService,
    this.initialEmail = '',
    this.stateStore,
    super.key,
  });

  final AuthService authService;
  final String initialEmail;
  final PasswordResetStateStore? stateStore;

  @override
  State<ForgotPasswordEmailScreen> createState() =>
      _ForgotPasswordEmailScreenState();
}

class _ForgotPasswordEmailScreenState extends State<ForgotPasswordEmailScreen> {
  static final _emailPattern = RegExp(
    r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$',
  );

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController;
  bool _isSending = false;

  PasswordResetStateStore get _stateStore =>
      widget.stateStore ?? PasswordResetStateStore();

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.initialEmail);
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    if (_isSending) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSending = true);
    final email = _emailController.text.trim();
    try {
      await widget.authService.forgotPassword(
        ForgotPasswordRequest(email: email),
      );
      final state = PasswordResetState(
        email: email,
        expiresAt: DateTime.now().add(const Duration(minutes: 10)),
      );
      await _stateStore.save(state);
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ForgotPasswordCodeScreen(
            authService: widget.authService,
            state: state,
            stateStore: _stateStore,
          ),
        ),
      );
    } on AuthApiException catch (error) {
      if (mounted) {
        await _showError(
          error.message,
          title: error.statusCode == HttpStatus.notFound
              ? 'Correo no encontrado'
              : 'No se pudo enviar el código',
        );
      }
    } on SocketException {
      if (mounted) {
        await _showError(
          'No fue posible conectar con el servidor.',
          title: 'Error de red',
        );
      }
    } on TimeoutException {
      if (mounted) {
        await _showError(
          'La solicitud tardó demasiado. Inténtalo otra vez.',
          title: 'Tiempo de espera agotado',
        );
      }
    } on HttpException catch (error) {
      if (mounted) await _showError(error.message);
    } on FormatException catch (error) {
      if (mounted) await _showError(error.message);
    } on StateError catch (error) {
      if (mounted) await _showError(error.message.toString());
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _showError(
    String message, {
    String title = 'Ocurrió un error',
  }) => Dialogs.showSimpleDialog(
    context,
    title: title,
    message: message,
    icon: Icons.error_outline_rounded,
    color: Style.getErrorColor(),
    duration: 2500,
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Style.getBackgroundColor(),
    appBar: AppBar(
      title: const Text('Recuperar contraseña'),
      backgroundColor: Style.getBackgroundColor(),
      foregroundColor: Style.getTextColor(),
    ),
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  Icons.mark_email_unread_outlined,
                  size: 56,
                  color: Style.getPrimaryColor(),
                ),
                const SizedBox(height: 20),
                Text(
                  'Ingresa tu correo electrónico y te enviaremos un código.',
                  textAlign: TextAlign.center,
                  style: Style.getHeaderTwo(color: Style.getTextColor()),
                ),
                const SizedBox(height: 24),
                AppTextField(
                  controller: _emailController,
                  label: 'Correo electrónico',
                  hint: 'Inserta tu correo electrónico',
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                  inputFormatters: [LengthLimitingTextInputFormatter(100)],
                  validator: (value) {
                    final email = value?.trim() ?? '';
                    if (email.isEmpty) return 'Ingresa tu correo electrónico';
                    if (!_emailPattern.hasMatch(email)) {
                      return 'Ingresa un correo válido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                PrimaryButton(
                  label: _isSending ? 'Enviando...' : 'Enviar código',
                  onPressed: _isSending ? null : _sendCode,
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
