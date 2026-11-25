import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import 'package:conecta_utsh/helpers/style.dart';
import 'package:conecta_utsh/modules/app/components/app_text_field.dart';
import 'package:conecta_utsh/modules/app/components/password_requirements_info.dart';
import 'package:conecta_utsh/modules/app/components/primary_button.dart';
import 'package:conecta_utsh/modules/app/models/password_reset_model.dart';
import 'package:conecta_utsh/modules/app/screens/forgot_password_email_screen.dart';
import 'package:conecta_utsh/modules/app/screens/login_screen.dart';
import 'package:conecta_utsh/modules/app/services/auth_service.dart';
import 'package:conecta_utsh/modules/app/services/password_reset_state_store.dart';
import 'package:conecta_utsh/modules/app/services/password_validator.dart';
import 'package:conecta_utsh/utils/widgets/dialogs.dart';

class ForgotPasswordCodeScreen extends StatefulWidget {
  const ForgotPasswordCodeScreen({
    required this.authService,
    required this.state,
    this.stateStore,
    super.key,
  });

  final AuthService authService;
  final PasswordResetState state;
  final PasswordResetStateStore? stateStore;

  @override
  State<ForgotPasswordCodeScreen> createState() =>
      _ForgotPasswordCodeScreenState();
}

class _ForgotPasswordCodeScreenState extends State<ForgotPasswordCodeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _controllers = List.generate(6, (_) => TextEditingController());
  final _focusNodes = List.generate(6, (_) => FocusNode());
  final _passwordController = TextEditingController();
  final _confirmationController = TextEditingController();
  late DateTime _expiresAt;
  String? _resetToken;
  Timer? _timer;
  Duration _remaining = Duration.zero;
  bool _isExpired = false;
  bool _isCodeConfirmed = false;
  bool _isVerifyingCode = false;
  bool _isResending = false;
  bool _isSubmitting = false;
  bool _obscurePassword = true;
  bool _obscureConfirmation = true;

  PasswordResetStateStore get _stateStore =>
      widget.stateStore ?? PasswordResetStateStore();

  String get _code => _controllers.map((controller) => controller.text).join();
  bool get _hasCompleteCode => RegExp(r'^\d{6}$').hasMatch(_code);
  bool get _isPasswordValid =>
      isValidPassword(_passwordController.text) &&
      _confirmationController.text.trim() == _passwordController.text.trim();

  @override
  void initState() {
    super.initState();
    _expiresAt = widget.state.expiresAt;
    _passwordController.addListener(_passwordChanged);
    _confirmationController.addListener(_passwordChanged);
    _updateRemaining();
    if (!_isExpired) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        _updateRemaining();
      });
    } else {
      _clearExpiredState();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final focusNode in _focusNodes) {
      focusNode.dispose();
    }
    _passwordController
      ..removeListener(_passwordChanged)
      ..dispose();
    _confirmationController
      ..removeListener(_passwordChanged)
      ..dispose();
    super.dispose();
  }

  void _passwordChanged() {
    if (mounted) setState(() {});
  }

  void _updateRemaining() {
    final remaining = _expiresAt.difference(DateTime.now());
    if (!mounted) {
      _remaining = remaining.isNegative ? Duration.zero : remaining;
      _isExpired = remaining <= Duration.zero;
      return;
    }
    setState(() {
      _remaining = remaining.isNegative ? Duration.zero : remaining;
      _isExpired = remaining <= Duration.zero;
    });
    if (_isExpired) {
      _timer?.cancel();
      _isCodeConfirmed = false;
      _resetToken = null;
      _passwordController.clear();
      _confirmationController.clear();
      _clearExpiredState();
    }
  }

  Future<void> _clearExpiredState() async {
    try {
      await _stateStore.clear();
    } on StateError catch (error) {
      if (mounted) await _showMessage(error.message.toString());
    }
  }

  void _onCodeChanged(int index, String value) {
    if (value.length > 1) {
      final digits = value.replaceAll(RegExp(r'\D'), '');
      for (var offset = 0; offset < 6 - index; offset++) {
        final digitIndex = index + offset;
        _controllers[digitIndex].text = offset < digits.length
            ? digits[offset]
            : '';
      }
      final focusIndex = (index + digits.length).clamp(0, 5);
      _focusNodes[focusIndex].requestFocus();
    } else if (value.isNotEmpty && index < 5) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
    setState(() {});
  }

  Future<void> _confirmCode() async {
    if (_isExpired || _isVerifyingCode || !_hasCompleteCode) return;
    setState(() => _isVerifyingCode = true);
    try {
      final savedState = await _stateStore.readActive();
      if (savedState == null) {
        _updateRemaining();
        await _showMessage(
          'El código expiró. Solicita uno nuevo para continuar.',
          title: 'Código expirado',
        );
        return;
      }
      final verification = await widget.authService.verifyResetCode(
        VerifyResetCodeRequest(email: widget.state.email, code: _code),
      );
      if (mounted && DateTime.now().isBefore(_expiresAt)) {
        setState(() {
          _resetToken = verification.resetToken;
          _expiresAt = DateTime.now().add(
            Duration(seconds: verification.expiresInSeconds),
          );
          _remaining = Duration(seconds: verification.expiresInSeconds);
          _isCodeConfirmed = true;
        });
      }
    } on AuthApiException catch (error) {
      if (!mounted) return;
      await _showMessage(
        error.message,
        title:
            error.statusCode == HttpStatus.badRequest ||
                error.statusCode == HttpStatus.unauthorized ||
                error.statusCode == HttpStatus.unprocessableEntity
            ? 'Código incorrecto'
            : 'No se pudo verificar el código',
      );
    } on SocketException {
      if (mounted) {
        await _showMessage(
          'No fue posible conectar con el servidor.',
          title: 'Error de red',
        );
      }
    } on TimeoutException {
      if (mounted) {
        await _showMessage(
          'La solicitud tardó demasiado. Inténtalo otra vez.',
          title: 'Tiempo de espera agotado',
        );
      }
    } on HttpException catch (error) {
      if (mounted) await _showMessage(error.message);
    } on FormatException catch (error) {
      if (mounted) await _showMessage(error.message);
    } on StateError catch (error) {
      if (mounted) await _showMessage(error.message.toString());
    } finally {
      if (mounted) setState(() => _isVerifyingCode = false);
    }
  }

  Future<void> _submitPassword() async {
    final resetToken = _resetToken;
    if (_isSubmitting ||
        !_isCodeConfirmed ||
        _isExpired ||
        resetToken == null) {
      return;
    }
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSubmitting = true);
    try {
      await widget.authService.resetPassword(
        ResetPasswordRequest(
          email: widget.state.email,
          resetToken: resetToken,
          newPassword: _passwordController.text.trim(),
          confirmPassword: _confirmationController.text.trim(),
        ),
      );
      _resetToken = null;
      await _stateStore.clear();
      if (!mounted) return;
      await _showMessage(
        'Tu contraseña se actualizó correctamente.',
        title: 'Cambio exitoso',
        success: true,
      );
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil<void>(
        MaterialPageRoute<void>(
          builder: (_) => LoginScreen(initialEmail: widget.state.email),
        ),
        (_) => false,
      );
    } on AuthApiException catch (error) {
      if (!mounted) return;
      final message = error.message.toLowerCase();
      final expired =
          error.statusCode == HttpStatus.gone || message.contains('expir');
      final incorrect =
          error.statusCode == HttpStatus.badRequest ||
          error.statusCode == HttpStatus.unauthorized ||
          error.statusCode == HttpStatus.unprocessableEntity ||
          message.contains('incorrect') ||
          message.contains('inválid');
      if (expired) {
        setState(() {
          _isExpired = true;
          _isCodeConfirmed = false;
          _remaining = Duration.zero;
        });
        _timer?.cancel();
        await _clearExpiredState();
      } else if (incorrect) {
        setState(() {
          _isCodeConfirmed = false;
          _resetToken = null;
        });
      }
      await _showMessage(
        error.message,
        title: expired
            ? 'Código expirado'
            : incorrect
            ? 'Código incorrecto'
            : 'No se pudo cambiar la contraseña',
      );
    } on SocketException {
      if (mounted) {
        await _showMessage(
          'No fue posible conectar con el servidor.',
          title: 'Error de red',
        );
      }
    } on TimeoutException {
      if (mounted) {
        await _showMessage(
          'La solicitud tardó demasiado. Inténtalo otra vez.',
          title: 'Tiempo de espera agotado',
        );
      }
    } on HttpException catch (error) {
      if (mounted) await _showMessage(error.message);
    } on FormatException catch (error) {
      if (mounted) await _showMessage(error.message);
    } on StateError catch (error) {
      if (mounted) await _showMessage(error.message.toString());
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _resendCode() async {
    if (_isResending) return;
    setState(() => _isResending = true);
    try {
      await widget.authService.forgotPassword(
        ForgotPasswordRequest(email: widget.state.email),
      );
      final renewedState = PasswordResetState(
        email: widget.state.email,
        expiresAt: DateTime.now().add(const Duration(minutes: 10)),
      );
      await _stateStore.save(renewedState);
      if (!mounted) return;
      _expiresAt = renewedState.expiresAt;
      _timer?.cancel();
      _isExpired = false;
      _isCodeConfirmed = false;
      _resetToken = null;
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        _updateRemaining();
      });
      for (final controller in _controllers) {
        controller.clear();
      }
      _passwordController.clear();
      _confirmationController.clear();
      _focusNodes.first.requestFocus();
      _updateRemaining();
      await _showMessage(
        'Enviamos un nuevo código a tu correo.',
        title: 'Código reenviado',
        success: true,
      );
    } on AuthApiException catch (error) {
      if (mounted) {
        await _showMessage(
          error.message,
          title: error.statusCode == HttpStatus.notFound
              ? 'Correo no encontrado'
              : 'No se pudo reenviar el código',
        );
      }
    } on SocketException {
      if (mounted) {
        await _showMessage(
          'No fue posible conectar con el servidor.',
          title: 'Error de red',
        );
      }
    } on TimeoutException {
      if (mounted) {
        await _showMessage(
          'La solicitud tardó demasiado. Inténtalo otra vez.',
          title: 'Tiempo de espera agotado',
        );
      }
    } on HttpException catch (error) {
      if (mounted) await _showMessage(error.message);
    } on FormatException catch (error) {
      if (mounted) await _showMessage(error.message);
    } on StateError catch (error) {
      if (mounted) await _showMessage(error.message.toString());
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  Future<void> _useAnotherEmail() async {
    try {
      await _stateStore.clear();
    } on StateError catch (error) {
      if (mounted) await _showMessage(error.message.toString());
      return;
    }
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => ForgotPasswordEmailScreen(
          authService: widget.authService,
          stateStore: _stateStore,
        ),
      ),
    );
  }

  Future<void> _showMessage(
    String message, {
    String title = 'Ocurrió un error',
    bool success = false,
  }) => Dialogs.showSimpleDialog(
    context,
    title: title,
    message: message,
    icon: success ? Icons.check_circle_outline : Icons.error_outline_rounded,
    color: success ? Style.getSuccessColor() : Style.getErrorColor(),
    duration: 2200,
  );

  String get _formattedTime {
    final minutes = _remaining.inMinutes
        .remainder(60)
        .toString()
        .padLeft(2, '0');
    final seconds = _remaining.inSeconds
        .remainder(60)
        .toString()
        .padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Widget _buildPasswordFields() => Form(
    key: _formKey,
    autovalidateMode: AutovalidateMode.onUserInteraction,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Nueva contraseña',
          style: Style.getHeaderTwo(color: Style.getTextColor()),
        ),
        const SizedBox(height: 12),
        AppTextField(
          controller: _passwordController,
          label: 'Nueva contraseña',
          hint: 'Ingresa una contraseña nueva',
          obscureText: _obscurePassword,
          textInputAction: TextInputAction.next,
          inputFormatters: [LengthLimitingTextInputFormatter(128)],
          validator: passwordValidationMessage,
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const PasswordRequirementsInfo(),
              IconButton(
                tooltip: _obscurePassword
                    ? 'Mostrar contraseña'
                    : 'Ocultar contraseña',
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: Style.getIconColor(),
                  size: 20,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        AppTextField(
          controller: _confirmationController,
          label: 'Confirmar contraseña',
          hint: 'Confirma tu contraseña nueva',
          obscureText: _obscureConfirmation,
          textInputAction: TextInputAction.done,
          inputFormatters: [LengthLimitingTextInputFormatter(128)],
          validator: (value) {
            if ((value ?? '').isEmpty) return 'Confirma tu contraseña';
            if (value?.trim() != _passwordController.text.trim()) {
              return 'Las contraseñas no coinciden';
            }
            return null;
          },
          suffixIcon: IconButton(
            tooltip: _obscureConfirmation
                ? 'Mostrar contraseña'
                : 'Ocultar contraseña',
            onPressed: () =>
                setState(() => _obscureConfirmation = !_obscureConfirmation),
            icon: Icon(
              _obscureConfirmation
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: Style.getIconColor(),
              size: 20,
            ),
          ),
        ),
        const SizedBox(height: 20),
        PrimaryButton(
          label: _isSubmitting ? 'Guardando...' : 'Cambiar contraseña',
          onPressed: _isPasswordValid && !_isSubmitting
              ? _submitPassword
              : null,
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Style.getBackgroundColor(),
    appBar: AppBar(
      automaticallyImplyLeading: false,
      title: const Text('Recuperar contraseña'),
      backgroundColor: Style.getBackgroundColor(),
      foregroundColor: Style.getTextColor(),
    ),
    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Enviamos un código a ${widget.state.email}.',
              textAlign: TextAlign.center,
              style: Style.getHeaderTwo(color: Style.getTextColor()),
            ),
            const SizedBox(height: 16),
            Text(
              _isExpired ? 'El código expiró' : 'Vigencia: $_formattedTime',
              textAlign: TextAlign.center,
              style: Style.getHeaderOne(
                color: _isExpired
                    ? Style.getErrorColor()
                    : Style.getPrimaryColor(),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: List.generate(
                6,
                (index) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: TextField(
                        controller: _controllers[index],
                        focusNode: _focusNodes[index],
                        enabled:
                            !_isExpired &&
                            !_isCodeConfirmed &&
                            !_isVerifyingCode,
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.next,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        onChanged: (value) => _onCodeChanged(index, value),
                        style: Style.getHeaderOne(
                          color: Style.getTextColor(),
                          fontSize: 22,
                        ),
                        decoration: InputDecoration(
                          counterText: '',
                          filled: true,
                          fillColor: Style.getCardColor(),
                          contentPadding: EdgeInsets.zero,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Style.getSubtleColor(),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Style.getSubtleColor(),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Style.getPrimaryColor(),
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // if (_isCodeConfirmed && !_isExpired) ...[
            //   const SizedBox(height: 8),
            //   Align(
            //     alignment: Alignment.centerRight,
            //     child: TextButton(
            //       onPressed: _editCode,
            //       child: Text(
            //         'Editar código',
            //         style: Style.getHeaderThree(color: Style.getPrimaryColor()),
            //       ),
            //     ),
            //   ),
            // ],
            const SizedBox(height: 12),
            if (!_isExpired && !_isCodeConfirmed)
              PrimaryButton(
                label: _isVerifyingCode ? 'Verificando...' : 'Confirmar código',
                onPressed: _hasCompleteCode && !_isVerifyingCode
                    ? _confirmCode
                    : null,
              ),
            if (_isExpired) ...[
              PrimaryButton(
                label: _isResending ? 'Enviando...' : 'Reenviar código',
                onPressed: _isResending ? null : _resendCode,
              ),
            ],
            if (!_isExpired && !_isCodeConfirmed) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: _useAnotherEmail,
                child: Text(
                  '¿Correo incorrecto? Usar otro correo',
                  style: Style.getHeaderThree(color: Style.getPrimaryColor()),
                ),
              ),
            ],
            if (_isExpired)
              TextButton(
                onPressed: _isResending ? null : _useAnotherEmail,
                child: Text(
                  'Usar otro correo',
                  style: Style.getHeaderThree(color: Style.getPrimaryColor()),
                ),
              ),
            if (_isCodeConfirmed && !_isExpired) ...[
              const SizedBox(height: 16),
              _buildPasswordFields(),
            ],
          ],
        ),
      ),
    ),
  );
}
