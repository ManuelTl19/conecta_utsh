import 'package:material_ui/material_ui.dart';

import 'package:conecta_utsh/helpers/providers/app_settings.dart';
import 'package:conecta_utsh/helpers/style.dart';
import 'package:conecta_utsh/modules/auth/widgets/primary_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({this.onSubmit, this.onCreateAccount, super.key});

  final void Function(String enrollment, String password)? onSubmit;
  final VoidCallback? onCreateAccount;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _enrollmentController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isSavingTheme = false;

  @override
  void dispose() {
    _enrollmentController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final onSubmit = widget.onSubmit;
    if (onSubmit != null) {
      onSubmit(_enrollmentController.text.trim(), _passwordController.text);
      return;
    }

    _showNotConfigured('La autenticación aún no está configurada.');
  }

  void _createAccount() {
    final onCreateAccount = widget.onCreateAccount;
    if (onCreateAccount != null) {
      onCreateAccount();
      return;
    }
    _showNotConfigured('La creación de cuenta aún no está configurada.');
  }

  Future<void> _toggleTheme() async {
    if (_isSavingTheme) return;
    setState(() => _isSavingTheme = true);
    try {
      final saved = await AppSettings().changeTheme();
      if (!mounted) return;
      if (!saved) _showNotConfigured('No se pudo guardar el tema.');
    } finally {
      if (mounted) setState(() => _isSavingTheme = false);
    }
  }

  void _showNotConfigured(String message) {
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
                          _LoginField(
                            controller: _enrollmentController,
                            hint: 'Inserta tu matrícula',
                            textInputAction: TextInputAction.next,
                            validator: (value) =>
                                value == null || value.trim().isEmpty
                                ? 'Ingresa tu matrícula'
                                : null,
                          ),
                          const SizedBox(height: 18),
                          _LoginField(
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
                            label: 'Registrarse',
                            onPressed: _submit,
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
              child: _HeaderStripe(height: 145, width: 20),
            ),
            Positioned(
              top: 52,
              left: 102,
              child: _HeaderStripe(height: 130, width: 26),
            ),
            Positioned(
              top: 52,
              left: 160,
              child: _HeaderStripe(height: 130, width: 26),
            ),
            Positioned(
              top: 16,
              right: 45,
              child: _HeaderStripe(height: 145, width: 20),
            ),
            Positioned(
              left: 20,
              top: MediaQuery.paddingOf(context).top + 10,
              child: _HeaderActionButton(
                tooltip: 'Volver',
                onPressed: onBack,
                icon: Icons.arrow_back_ios_new,
              ),
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

class _HeaderStripe extends StatelessWidget {
  const _HeaderStripe({required this.height, required this.width});

  final double height;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: Style.getInverseTextColor().withValues(alpha: .055),
        borderRadius: BorderRadius.circular(width),
      ),
    );
  }
}

class _LoginField extends StatelessWidget {
  const _LoginField({
    required this.controller,
    required this.hint,
    required this.validator,
    this.obscureText = false,
    this.textInputAction,
    this.suffixIcon,
  });

  final TextEditingController controller;
  final String hint;
  final String? Function(String?) validator;
  final bool obscureText;
  final TextInputAction? textInputAction;
  final Widget? suffixIcon;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      textInputAction: textInputAction,
      validator: validator,
      style: Style.getTextStyle(color: Style.getTextColor(), fontSize: 12),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: Style.getHintStyle(
          color: Style.getObscureTextColor(),
          fontSize: 12,
        ),
        filled: true,
        fillColor: Style.getSubtleColor(),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Style.getPrimaryColor(), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Style.getErrorColor()),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Style.getErrorColor(), width: 1.5),
        ),
      ),
    );
  }
}
