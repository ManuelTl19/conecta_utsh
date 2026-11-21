import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import 'package:conecta_utsh/helpers/providers/app_settings.dart';
import 'package:conecta_utsh/helpers/style.dart';
import 'package:conecta_utsh/modules/app/components/app_text_field.dart';
import 'package:conecta_utsh/modules/app/components/primary_button.dart';
import 'package:conecta_utsh/modules/app/components/theme_toggle_button.dart';
import 'package:conecta_utsh/modules/app/models/login_model.dart';
import 'package:conecta_utsh/modules/app/screens/dashboard_screen.dart';
import 'package:conecta_utsh/modules/app/screens/register_screen.dart';
import 'package:conecta_utsh/modules/app/screens/user_preferences_screen.dart';
import 'package:conecta_utsh/modules/app/services/auth_service.dart';
import 'package:conecta_utsh/modules/app/services/token_store.dart';
import 'package:conecta_utsh/modules/app/services/user_preferences_service.dart';
import 'package:conecta_utsh/utils/widgets/dialogs.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    this.onSubmit,
    this.onCreateAccount,
    this.authService,
    super.key,
  });

  final void Function(String email, String password)? onSubmit;
  final VoidCallback? onCreateAccount;
  final AuthService? authService;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  AuthService? _ownedAuthService;
  bool _obscurePassword = true;
  bool _isSavingTheme = false;
  bool _isSubmitting = false;
  bool _hasAutofilledRegisteredEmail = false;

  AuthService get _authService =>
      widget.authService ?? (_ownedAuthService ??= AuthService());

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _ownedAuthService?.close();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      await _showMessage(
        'Revisa tu correo y contraseña e intenta de nuevo.',
        title: 'Faltan datos',
      );
      return;
    }

    final onSubmit = widget.onSubmit;
    if (onSubmit != null) {
      onSubmit(_emailController.text.trim(), _passwordController.text.trim());
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final response = await _authService.login(
        LoginModel(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        ),
      );
      if (!mounted) return;
      AppSettings.isSignedIn = true;
      AppSettings.loginDate = DateTime.now().toIso8601String();
      final destination =
          await const UserPreferencesService().hasSeen(response.user.id)
          ? DashboardScreen(user: response.user, authService: _authService)
          : UserPreferencesScreen(
              user: response.user,
              authService: _authService,
            );
      if (!mounted) return;
      Navigator.of(context)
          .push(MaterialPageRoute<void>(builder: (_) => destination));
    } on AuthApiException catch (error) {
      if (mounted) {
        await _showMessage(error.message, title: 'No se pudo iniciar sesión');
      }
    } on TokenStorageException catch (error) {
      if (mounted) {
        await _showMessage(error.message, title: 'No se pudo iniciar sesión');
      }
    } on StateError catch (error) {
      if (mounted) {
        await _showMessage(
          error.message.toString(),
          title: 'No se pudo iniciar sesión',
        );
      }
    } on SocketException {
      if (mounted) {
        await _showMessage(
          'No fue posible conectar con el servidor.',
          title: 'Error de conexión',
        );
      }
    } on FormatException catch (error) {
      if (mounted) {
        await _showMessage(error.message, title: 'Respuesta no válida');
      }
    } on HttpException catch (error) {
      if (mounted) {
        await _showMessage(error.message, title: 'No se pudo iniciar sesión');
      }
    } on TimeoutException {
      if (mounted) {
        await _showMessage(
          'La solicitud tardó demasiado. Inténtalo otra vez.',
          title: 'Tiempo de espera agotado',
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _createAccount() async {
    final onCreateAccount = widget.onCreateAccount;
    if (onCreateAccount != null) {
      onCreateAccount();
      return;
    }
    final registeredEmail = await Navigator.of(context).push<String>(
      MaterialPageRoute<String>(
        builder: (_) => RegisterScreen(authService: _authService),
      ),
    );
    if (!mounted || registeredEmail == null || _hasAutofilledRegisteredEmail) {
      return;
    }
    _emailController.text = registeredEmail;
    _hasAutofilledRegisteredEmail = true;
  }

  Future<void> _toggleTheme() async {
    if (_isSavingTheme) return;
    setState(() => _isSavingTheme = true);
    try {
      final saved = await AppSettings().changeTheme();
      if (!mounted) return;
      if (!saved) {
        await _showMessage(
          'No se pudo guardar el tema.',
          title: 'No se pudo cambiar el tema',
        );
      }
    } finally {
      if (mounted) setState(() => _isSavingTheme = false);
    }
  }

  Future<void> _showMessage(
    String message, {
    String title = 'Ocurrió un error',
  }) => Dialogs.showSimpleDialog(
    context,
    title: title,
    message: message,
    icon: Icons.error_outline_rounded,
    color: Style.getErrorColor(),
    duration: 2200,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Style.getBackgroundColor(),
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final statusBar = MediaQuery.paddingOf(context).top;
            final headerHeight =
                statusBar +
                (constraints.maxHeight * .30).clamp(250.0, 320.0).toDouble();
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
                        spacing: 16,
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
                          SizedBox(height: 8),
                          AppTextField(
                            controller: _emailController,
                            label: 'Correo electrónico',
                            hint: 'Inserta tu correo electrónico',
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            inputFormatters: [
                              LengthLimitingTextInputFormatter(100),
                            ],
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Ingresa tu correo electrónico';
                              }
                              if (!RegExp(
                                r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$',
                              ).hasMatch(value.trim())) {
                                return 'Ingresa un correo válido';
                              }
                              return null;
                            },
                          ),
                          AppTextField(
                            controller: _passwordController,
                            label: 'Contraseña',
                            hint: 'Inserta tu contraseña',
                            obscureText: _obscurePassword,
                            textInputAction: TextInputAction.done,
                            inputFormatters: [
                              LengthLimitingTextInputFormatter(128),
                            ],
                            validator: (value) =>
                                value == null || value.trim().isEmpty
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
                          const SizedBox(height: 8),
                          PrimaryButton(
                            label: 'Iniciar sesión',
                            onPressed: _isSubmitting ? null : _submit,
                          ),
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
    return ClipPath(
      clipper: const _CircleBottomClipper(curveHeight: 30),
      child: Container(
        color: Style.getPrimaryColor(),
        child: Stack(
          children: [
            Positioned(
              top: 16,
              left: 36,
              child: _HeaderIcon(
                icon: Icons.school_outlined, // escuela
                size: 74,
                angleDegrees: -18,
              ),
            ),
            Positioned(
              top: 62,
              left: 118,
              child: _HeaderIcon(
                icon: Icons.handshake_outlined, // vinculación
                size: 62,
                angleDegrees: 14,
              ),
            ),
            Positioned(
              top: 120,
              left: 38,
              child: _HeaderIcon(
                icon: Icons.assignment_turned_in_outlined,
                size: 78,
                angleDegrees: 22,
              ),
            ),
            Positioned(
              top: 150,
              right: 88,
              child: _HeaderIcon(
                icon: Icons.badge_outlined,
                size: 78,
                angleDegrees: 22,
              ),
            ),
            Positioned(
              top: 44,
              right: 38,
              child: _HeaderIcon(
                icon: Icons.business_outlined,
                size: 78,
                angleDegrees: -12,
              ),
            ),
            Positioned(
              right: 20,
              top: MediaQuery.paddingOf(context).top + 10,
              child: ThemeToggleButton(
                onPressed: onToggleTheme,
                isSaving: isSavingTheme,
              ),
            ),
            Positioned(
              left: 20,
              right: 20,
              bottom: 80,
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

class _CircleBottomClipper extends CustomClipper<Path> {
  const _CircleBottomClipper({this.curveHeight = 40});

  /// Qué tanto se curva el borde inferior (la "flecha" del arco).
  final double curveHeight;

  @override
  Path getClip(Size size) {
    final w = size.width;
    final s = curveHeight;

    // Radio del círculo cuyo arco tiene cuerda w y altura s
    final radius = (w * w / 4 + s * s) / (2 * s);

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(0, size.height - s)
      ..arcToPoint(
        Offset(w, size.height - s),
        radius: Radius.circular(radius),
        clockwise: false, // el arco abulta hacia abajo
      )
      ..lineTo(w, 0)
      ..close();

    return path;
  }

  @override
  bool shouldReclip(covariant _CircleBottomClipper oldClipper) =>
      oldClipper.curveHeight != curveHeight;
}

class _HeaderIcon extends StatelessWidget {
  const _HeaderIcon({
    required this.icon,
    required this.size,
    this.angleDegrees = 0,
  });

  final IconData icon;
  final double size;
  final double angleDegrees;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Transform.rotate(
        angle: angleDegrees * (math.pi / 180), // Convierte grados a radianes
        child: Icon(
          icon,
          size: size,
          color: Style.getInverseTextColor().withValues(alpha: .08),
        ),
      ),
    );
  }
}
