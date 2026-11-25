import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:resize/resize.dart';
import 'package:conecta_utsh/helpers/style.dart';
import 'package:conecta_utsh/modules/app/components/app_text_field.dart';
import 'package:conecta_utsh/modules/app/components/primary_button.dart';
import 'package:conecta_utsh/modules/app/services/password_validator.dart';
import 'package:conecta_utsh/modules/app/services/user_profile_service.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({required this.profileService, super.key});

  final UserProfileService profileService;

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmationController = TextEditingController();
  bool _isSubmitting = false;
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirmation = true;
  String? _errorMessage;
  int _cooldownSeconds = 0;
  Timer? _cooldownTimer;

  @override
  void initState() {
    super.initState();
    _currentController.addListener(_passwordChanged);
    _newController.addListener(_passwordChanged);
    _confirmationController.addListener(_passwordChanged);
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _currentController.removeListener(_passwordChanged);
    _newController.removeListener(_passwordChanged);
    _confirmationController.removeListener(_passwordChanged);
    _currentController.dispose();
    _newController.dispose();
    _confirmationController.dispose();
    super.dispose();
  }

  bool get _hasMinLength => _newController.text.runes.length >= 8;
  bool get _hasUppercase =>
      RegExp(r'[A-ZÁÉÍÓÚÜÑ]').hasMatch(_newController.text);
  bool get _hasLowercase =>
      RegExp(r'[a-záéíóúüñ]').hasMatch(_newController.text);
  bool get _hasNumber => RegExp(r'\d').hasMatch(_newController.text);
  bool get _hasSpecial =>
      RegExp(r'[^A-Za-zÁÉÍÓÚÜÑáéíóúüñ0-9\s]').hasMatch(_newController.text);
  bool get _hasNoSpaces => !RegExp(r'\s').hasMatch(_newController.text);

  bool get _passwordValid =>
      _hasMinLength &&
      _hasUppercase &&
      _hasLowercase &&
      _hasNumber &&
      _hasSpecial &&
      _hasNoSpaces;

  void _passwordChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _submit() async {
    if (_isSubmitting || _cooldownSeconds > 0) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_newController.text == _currentController.text) {
      setState(
        () => _errorMessage =
            'La nueva contraseña debe ser distinta de la actual.',
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });
    try {
      await widget.profileService.cambiarPassword(
        passwordActual: _currentController.text,
        nuevaPassword: _newController.text,
        confirmarPassword: _confirmationController.text,
      );
      if (!mounted) return;
      _clearFields();
      Navigator.of(context).pop(true);
    } on UserProfileApiException catch (error) {
      if (!mounted) return;
      if (error.statusCode == 429) {
        _startCooldown(error.retryAfterSeconds ?? 60);
        setState(() => _errorMessage = error.message);
      } else if (error.statusCode != 401 && error.statusCode != 403) {
        setState(() => _errorMessage = error.message);
      }
    } finally {
      _clearFields();
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _startCooldown(int seconds) {
    _cooldownTimer?.cancel();
    setState(() => _cooldownSeconds = seconds.clamp(1, 3600).toInt());
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return timer.cancel();
      if (_cooldownSeconds <= 1) {
        timer.cancel();
        setState(() => _cooldownSeconds = 0);
      } else {
        setState(() => _cooldownSeconds--);
      }
    });
  }

  void _clearFields() {
    _currentController.clear();
    _newController.clear();
    _confirmationController.clear();
  }

  Widget _visibilityButton({
    required bool obscured,
    required VoidCallback onPressed,
    required String label,
  }) => Semantics(
    button: true,
    label: obscured ? 'Mostrar $label' : 'Ocultar $label',
    child: IconButton(
      tooltip: obscured ? 'Mostrar $label' : 'Ocultar $label',
      constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
      onPressed: onPressed,
      icon: Icon(
        obscured ? Icons.visibility_outlined : Icons.visibility_off_outlined,
      ),
    ),
  );

  Widget _requirement(String label, bool satisfied) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.only(bottom: 4.h),
      child: Row(
        children: [
          Icon(
            satisfied ? Icons.check_circle_rounded : Icons.circle_outlined,
            size: 16,
            color: satisfied ? colors.primary : colors.onSurfaceVariant,
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: colors.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        title: const Text('Cambiar contraseña'),
        backgroundColor: colors.surface,
        foregroundColor: colors.onSurface,
        surfaceTintColor: Colors.transparent,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: Style.getPaddingSymmetric(horizontal: 22, vertical: 18),
          children: [
            AppTextField(
              controller: _currentController,
              label: 'Contraseña actual',
              hint: 'Contraseña actual',
              semanticsLabel: 'Contraseña actual',
              obscureText: _obscureCurrent,
              autofillHints: const [AutofillHints.password],
              enableSuggestions: false,
              autocorrect: false,
              enableInteractiveSelection: false,
              validator: (value) => value == null || value.isEmpty
                  ? 'Ingresa tu contraseña actual.'
                  : null,
              suffixIcon: _visibilityButton(
                obscured: _obscureCurrent,
                label: 'contraseña actual',
                onPressed: () =>
                    setState(() => _obscureCurrent = !_obscureCurrent),
              ),
            ),
            SizedBox(height: 12.h),
            AppTextField(
              controller: _newController,
              label: 'Nueva contraseña',
              hint: 'Nueva contraseña',
              semanticsLabel: 'Nueva contraseña',
              obscureText: _obscureNew,
              autofillHints: const [AutofillHints.newPassword],
              enableSuggestions: false,
              autocorrect: false,
              enableInteractiveSelection: false,
              validator: (value) => passwordValidationMessage(value),
              suffixIcon: _visibilityButton(
                obscured: _obscureNew,
                label: 'nueva contraseña',
                onPressed: () => setState(() => _obscureNew = !_obscureNew),
              ),
            ),
            SizedBox(height: 12.h),
            AppTextField(
              controller: _confirmationController,
              label: 'Confirmar nueva contraseña',
              hint: 'Confirmar nueva contraseña',
              semanticsLabel: 'Confirmar nueva contraseña',
              obscureText: _obscureConfirmation,
              autofillHints: const [AutofillHints.newPassword],
              enableSuggestions: false,
              autocorrect: false,
              enableInteractiveSelection: false,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Confirma tu nueva contraseña.';
                }
                if (value != _newController.text) {
                  return 'Las contraseñas no coinciden.';
                }
                return null;
              },
              suffixIcon: _visibilityButton(
                obscured: _obscureConfirmation,
                label: 'confirmación',
                onPressed: () => setState(
                  () => _obscureConfirmation = !_obscureConfirmation,
                ),
              ),
            ),
            SizedBox(height: 14.h),
            _requirement('Al menos 8 caracteres', _hasMinLength),
            _requirement('Una letra mayúscula', _hasUppercase),
            _requirement('Una letra minúscula', _hasLowercase),
            _requirement('Un número', _hasNumber),
            _requirement('Un carácter especial', _hasSpecial),
            _requirement('Sin espacios', _hasNoSpaces),
            if (_newController.text.isNotEmpty &&
                _currentController.text.isNotEmpty &&
                _newController.text == _currentController.text)
              Padding(
                padding: EdgeInsets.only(top: 5.h),
                child: Text(
                  'La nueva contraseña debe ser distinta de la actual.',
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: colors.error),
                ),
              ),
            if (_errorMessage != null) ...[
              SizedBox(height: 12.h),
              Text(
                _errorMessage!,
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: colors.error),
              ),
            ],
            SizedBox(height: 20.h),
            Semantics(
              button: true,
              label: 'Cambiar contraseña',
              child: PrimaryButton(
                label: _cooldownSeconds > 0
                    ? 'Espera $_cooldownSeconds s'
                    : 'Cambiar contraseña',
                isLoading: _isSubmitting,
                onPressed:
                    _isSubmitting || _cooldownSeconds > 0 || !_passwordValid
                    ? null
                    : _submit,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
