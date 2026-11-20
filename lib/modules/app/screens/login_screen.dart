import 'dart:async';
import 'dart:io';

import 'package:material_ui/material_ui.dart';

import 'package:conecta_utsh/helpers/providers/app_settings.dart';
import 'package:conecta_utsh/helpers/style.dart';
import 'package:conecta_utsh/modules/app/components/app_text_field.dart';
import 'package:conecta_utsh/modules/app/components/primary_button.dart';
import 'package:conecta_utsh/modules/app/models/login_model.dart';
import 'package:conecta_utsh/modules/app/screens/register_screen.dart';
import 'package:conecta_utsh/modules/app/services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    this.onSubmit,
    this.onCreateAccount,
    this.authService,
    super.key,
  });

  final void Function(String enrollment, String password)? onSubmit;
  final VoidCallback? onCreateAccount;
  final AuthService? authService;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _enrollmentController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isSavingTheme = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _enrollmentController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final onSubmit = widget.onSubmit;
    if (onSubmit != null) {
      onSubmit(_enrollmentController.text.trim(), _passwordController.text);
      return;
    }

    final service = widget.authService;
    if (service == null) {
      _showMessage('La autenticación aún no está configurada.');
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await service.login(
        LoginModel(
          enrollment: _enrollmentController.text.trim(),
          password: _passwordController.text,
        ),
      );
      if (!mounted) return;
      AppSettings.isSignedIn = true;
      AppSettings.loginDate = DateTime.now().toIso8601String();
      _showMessage('Sesión iniciada correctamente.');
    } on AuthApiException catch (error) {
      if (mounted) _showMessage(error.message);
    } on SocketException {
      if (mounted) {
        _showMessage('No fue posible conectar con el servidor.');
      }
    } on FormatException catch (error) {
      if (mounted) _showMessage(error.message);
    } on HttpException catch (error) {
      if (mounted) _showMessage(error.message);
    } on TimeoutException {
      if (mounted) {
        _showMessage('La solicitud tardó demasiado. Inténtalo otra vez.');
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _createAccount() {
    final onCreateAccount = widget.onCreateAccount;
    if (onCreateAccount != null) {
      onCreateAccount();
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => RegisterScreen(authService: widget.authService),
      ),
    );
  }

  Future<void> _toggleTheme() async {
    if (_isSavingTheme) return;
    setState(() => _isSavingTheme = true);
    try {
      final saved = await AppSettings().changeTheme();
      if (!mounted) return;
      if (!saved) _showMessage('No se pudo guardar el tema.');
    } finally {
      if (mounted) setState(() => _isSavingTheme = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Style.getBackgroundColor(),
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final headerHeight = (constraints.maxHeight * .31)
                .clamp(210.0, 270.0)
                .toDouble();
            return Column(
              children: [
                SizedBox(
                  height: headerHeight,
                  width: double.infinity,
                  child: _LoginHeader(
                    onBack: () => Navigator.of(context).maybePop(),
                    onToggleTheme: _toggleTheme,
                    isSavingTheme: _isSavingTheme,
                  ),
                ),
                SizedBox(height: 20),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(28, 12, 28, 24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Iniciar sesión',
                            textAlign: TextAlign.center,
                            style: Style.getHeaderOne(
                              color: Style.getTextColor(),
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 22),
                          AppTextField(
                            controller: _enrollmentController,
                            hint: 'Inserta tu matrícula',
                            textInputAction: TextInputAction.next,
                            validator: (value) =>
                                value == null || value.trim().isEmpty
                                ? 'Ingresa tu matrícula'
                                : null,
                          ),
                          const SizedBox(height: 18),
                          AppTextField(
                            controller: _passwordController,
                            hint: 'Inserta tu contraseña',
                            obscureText: _obscurePassword,
                            textInputAction: TextInputAction.done,
                            validator: (value) => value == null || value.isEmpty
                                ? 'Ingresa tu contraseña'
                                : null,
                            suffixIcon: IconButton(
                              tooltip: _obscurePassword
                                  ? 'Mostrar contraseña'
                                  : 'Ocultar contraseña',
                              onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: Style.getIconColor(),
                                size: 20,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          // Cambiar a "Iniciar sesión" cuando el flujo final
                          // confirme que el botón autentica y no registra.
                          PrimaryButton(
                            label: 'Iniciar sesión',
                            onPressed: _isSubmitting ? null : _submit,
                          ),
                          const SizedBox(height: 18),
                          Wrap(
                            alignment: WrapAlignment.center,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                '¿Aún no tienes una cuenta? ',
                                style: Style.getHeaderThree(
                                  color: Style.getObscureTextColor(),
                                  fontSize: 10,
                                ),
                              ),
                              TextButton(
                                onPressed: _createAccount,
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  foregroundColor: Style.getTextColor(),
                                ),
                                child: Text(
                                  'Crear cuenta',
                                  style: Style.getHeaderThree(
                                    color: Style.getTextColor(),
                                    fontSize: 10,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _LoginHeader extends StatelessWidget {
  const _LoginHeader({
    required this.onBack,
    required this.onToggleTheme,
    required this.isSavingTheme,
  });

  final VoidCallback onBack;
  final VoidCallback onToggleTheme;
  final bool isSavingTheme;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
      child: Container(
        color: Style.getPrimaryColor(),
        child: Stack(
          children: [
            Positioned(
              top: 16,
              left: 44,
              child: _HeaderIcon(icon: Icons.circle, size: 20),
            ),
            Positioned(
              top: 52,
              left: 102,
              child: _HeaderIcon(icon: Icons.circle, size: 26),
            ),
            Positioned(
              top: 52,
              left: 160,
              child: _HeaderIcon(icon: Icons.circle, size: 26),
            ),
            Positioned(
              top: 16,
              right: 45,
              child: _HeaderIcon(icon: Icons.circle, size: 20),
            ),
            Positioned(
              right: 20,
              top: MediaQuery.paddingOf(context).top + 10,
              child: _HeaderActionButton(
                tooltip: Style.isDarkModeOn
                    ? 'Cambiar a modo claro'
                    : 'Cambiar a modo oscuro',
                onPressed: isSavingTheme ? null : onToggleTheme,
                icon: Style.isDarkModeOn
                    ? Icons.light_mode_outlined
                    : Icons.dark_mode_outlined,
              ),
            ),
            Positioned(
              left: 20,
              right: 20,
              bottom: 26,
              child: Column(
                children: [
                  Text(
                    'Vincula UTSH',
                    style: Style.getHeaderThree(
                      color: Style.getInverseTextColor().withValues(alpha: .9),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Ingresa tus datos',
                    textAlign: TextAlign.center,
                    style: Style.getHeaderOne(
                      color: Style.getInverseTextColor(),
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderActionButton extends StatelessWidget {
  const _HeaderActionButton({
    required this.tooltip,
    required this.onPressed,
    required this.icon,
  });

  final String tooltip;
  final VoidCallback? onPressed;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Style.getCardColor(),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        icon: Icon(icon, color: Style.getPrimaryColor(), size: 19),
      ),
    );
  }
}

class _HeaderIcon extends StatelessWidget {
  const _HeaderIcon({required this.icon, required this.size});

  final IconData icon;
  final double size;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Icon(
        icon,
        size: size,
        color: Style.getInverseTextColor().withValues(alpha: .08),
      ),
    );
  }
}
