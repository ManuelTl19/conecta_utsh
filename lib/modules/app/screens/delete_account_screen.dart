import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:resize/resize.dart';
import 'package:conecta_utsh/helpers/style.dart';
import 'package:conecta_utsh/modules/app/components/app_text_field.dart';
import 'package:conecta_utsh/modules/app/services/user_profile_service.dart';

class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({
    required this.profileService,
    required this.onUnauthorized,
    required this.onAccountDeleted,
    super.key,
  });

  final UserProfileService profileService;
  final Future<void> Function() onUnauthorized;
  final Future<void> Function() onAccountDeleted;

  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  bool _isDeleting = false;
  bool _obscurePassword = true;
  int _cooldownSeconds = 0;
  String? _errorMessage;
  Timer? _cooldownTimer;

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _passwordController.removeListener(_passwordChanged);
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _delete() async {
    if (_isDeleting ||
        _cooldownSeconds > 0 ||
        !(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() {
      _isDeleting = true;
      _errorMessage = null;
    });
    final password = _passwordController.text;
    try {
      await widget.profileService.eliminarCuenta(password: password);
      _passwordController.clear();
      await widget.onAccountDeleted();
    } on UserProfileApiException catch (error) {
      if (!mounted) return;
      if (error.statusCode == 404) {
        _passwordController.clear();
        await widget.onUnauthorized();
        return;
      }
      if (error.statusCode == 429) {
        _passwordController.clear();
        _startCooldown(error.retryAfterSeconds ?? 60);
        setState(() => _errorMessage = error.message);
      } else if (error.statusCode == 400) {
        _passwordController.clear();
        setState(() => _errorMessage = error.message);
      } else if (error.statusCode != 401) {
        setState(() => _errorMessage = error.message);
      }
    } finally {
      _passwordController.clear();
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  void _passwordChanged() {
    if (mounted) setState(() {});
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

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        title: const Text('Eliminar cuenta'),
        backgroundColor: colors.surface,
        foregroundColor: colors.onSurface,
        surfaceTintColor: Colors.transparent,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: Style.getPaddingSymmetric(horizontal: 22, vertical: 18),
          children: [
            Icon(Icons.warning_amber_rounded, color: colors.error, size: 38),
            SizedBox(height: 12.h),
            Text(
              'Tu cuenta se dará de baja y ya no podrás iniciar sesión. '
              'Esta acción no se puede deshacer desde la app.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: colors.onSurface),
            ),
            SizedBox(height: 20.h),
            AppTextField(
              controller: _passwordController,
              label: 'Contraseña',
              hint: 'Confirma tu contraseña',
              semanticsLabel: 'Contraseña para eliminar la cuenta',
              obscureText: _obscurePassword,
              autofillHints: const [AutofillHints.password],
              enableSuggestions: false,
              autocorrect: false,
              enableInteractiveSelection: false,
              validator: (value) => value == null || value.isEmpty
                  ? 'Ingresa tu contraseña.'
                  : null,
              suffixIcon: Semantics(
                button: true,
                label: _obscurePassword
                    ? 'Mostrar contraseña'
                    : 'Ocultar contraseña',
                child: IconButton(
                  tooltip: _obscurePassword
                      ? 'Mostrar contraseña'
                      : 'Ocultar contraseña',
                  constraints: const BoxConstraints(
                    minWidth: 44,
                    minHeight: 44,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
              ),
            ),
            if (_errorMessage != null) ...[
              SizedBox(height: 10.h),
              Text(
                _errorMessage!,
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: colors.error),
              ),
            ],
            SizedBox(height: 20.h),
            Semantics(
              button: true,
              label: 'Eliminar mi cuenta',
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed:
                      _isDeleting ||
                          _cooldownSeconds > 0 ||
                          _passwordController.text.isEmpty
                      ? null
                      : _delete,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.error,
                    foregroundColor: colors.onError,
                    disabledBackgroundColor: colors.error.withValues(
                      alpha: .45,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: Style.getCircularBorderRadius(18),
                    ),
                    elevation: 0,
                  ),
                  child: _isDeleting
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: colors.onError,
                          ),
                        )
                      : Text(
                          _cooldownSeconds > 0
                              ? 'Espera $_cooldownSeconds s'
                              : 'Eliminar mi cuenta',
                        ),
                ),
              ),
            ),
            SizedBox(height: 10.h),
            TextButton(
              onPressed: _isDeleting
                  ? null
                  : () => Navigator.of(context).maybePop(),
              style: TextButton.styleFrom(
                minimumSize: const Size.fromHeight(44),
              ),
              child: const Text('Cancelar'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_passwordChanged);
  }
}
