import 'dart:async';
import 'dart:io';

import 'package:material_ui/material_ui.dart';

import 'package:conecta_utsh/helpers/style.dart';
import 'package:conecta_utsh/modules/app/components/app_text_field.dart';
import 'package:conecta_utsh/modules/app/components/primary_button.dart';
import 'package:conecta_utsh/modules/app/models/register_model.dart';
import 'package:conecta_utsh/modules/app/services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({this.authService, super.key});

  final AuthService? authService;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _personalFormKey = GlobalKey<FormState>();
  final _accountFormKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _paternalSurnameController = TextEditingController();
  final _maternalSurnameController = TextEditingController();
  final _enrollmentController = TextEditingController();
  final _careerController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  int _step = 0;
  bool _isSubmitting = false;
  bool _obscurePassword = true;
  bool _obscureConfirmation = true;

  @override
  void dispose() {
    _firstNameController.dispose();
    _paternalSurnameController.dispose();
    _maternalSurnameController.dispose();
    _enrollmentController.dispose();
    _careerController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _continue() {
    if (!(_personalFormKey.currentState?.validate() ?? false)) return;
    setState(() => _step = 1);
  }

  void _goBack() {
    if (_step == 1) {
      setState(() => _step = 0);
    } else {
      Navigator.of(context).maybePop();
    }
  }

  Future<void> _submit() async {
    if (!(_accountFormKey.currentState?.validate() ?? false)) return;
    final service = widget.authService;
    if (service == null) {
      _showMessage(
        'La conexión con el servicio de registro aún no está configurada.',
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await service.register(
        RegisterModel(
          firstName: _firstNameController.text.trim(),
          paternalSurname: _paternalSurnameController.text.trim(),
          maternalSurname: _maternalSurnameController.text.trim(),
          enrollment: _enrollmentController.text.trim(),
          career: _careerController.text.trim(),
          email: _emailController.text.trim(),
          phone: _phoneController.text.trim(),
          password: _passwordController.text,
        ),
      );
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop();
      messenger.showSnackBar(
        const SnackBar(content: Text('Tu cuenta se registró correctamente.')),
      );
    } on AuthApiException catch (error) {
      if (mounted) _showMessage(error.message);
    } on SocketException {
      if (mounted) _showMessage('No fue posible conectar con el servidor.');
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

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  String? _required(String? value, String field) =>
      value == null || value.trim().isEmpty ? 'Ingresa $field' : null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Style.getBackgroundColor(),
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final headerHeight = (constraints.maxHeight * .25)
                .clamp(190.0, 230.0)
                .toDouble();
            return Column(
              children: [
                SizedBox(
                  height: headerHeight,
                  width: double.infinity,
                  child: _RegisterHeader(onBack: _goBack),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(28, 12, 28, 24),
                    child: Form(
                      key: _step == 0 ? _personalFormKey : _accountFormKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Registrarse',
                            textAlign: TextAlign.center,
                            style: Style.getHeaderOne(
                              color: Style.getTextColor(),
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _StepIndicator(step: _step),
                          const SizedBox(height: 14),
                          if (_step == 0) ..._personalFields(),
                          if (_step == 1) ..._accountFields(),
                          const SizedBox(height: 16),
                          PrimaryButton(
                            label: _step == 0 ? 'Continuar' : 'Registrarse',
                            onPressed: _isSubmitting
                                ? null
                                : _step == 0
                                ? _continue
                                : _submit,
                          ),
                          const SizedBox(height: 14),
                          Wrap(
                            alignment: WrapAlignment.center,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                '¿Ya tienes una cuenta? ',
                                style: Style.getHeaderThree(
                                  color: Style.getObscureTextColor(),
                                  fontSize: 10,
                                ),
                              ),
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(context).maybePop(),
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  foregroundColor: Style.getTextColor(),
                                ),
                                child: Text(
                                  'Iniciar sesión',
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

  List<Widget> _personalFields() => [
    AppTextField(
      controller: _firstNameController,
      label: 'Nombre(s)',
      hint: 'Inserta nombre(s)',
      validator: (value) => _required(value, 'tu nombre'),
      textInputAction: TextInputAction.next,
    ),
    const SizedBox(height: 8),
    AppTextField(
      controller: _paternalSurnameController,
      label: 'Apellido paterno',
      hint: 'Inserta apellido paterno',
      validator: (value) => _required(value, 'tu apellido paterno'),
      textInputAction: TextInputAction.next,
    ),
    const SizedBox(height: 8),
    AppTextField(
      controller: _maternalSurnameController,
      label: 'Apellido materno',
      hint: 'Inserta apellido materno',
      validator: (value) => _required(value, 'tu apellido materno'),
      textInputAction: TextInputAction.next,
    ),
    const SizedBox(height: 8),
    AppTextField(
      controller: _enrollmentController,
      label: 'Matrícula',
      hint: 'Inserta tu matrícula',
      validator: (value) => _required(value, 'tu matrícula'),
      textInputAction: TextInputAction.next,
    ),
    const SizedBox(height: 8),
    AppTextField(
      controller: _careerController,
      label: 'Carrera',
      hint: 'Inserta tu carrera',
      validator: (value) => _required(value, 'tu carrera'),
      textInputAction: TextInputAction.done,
    ),
  ];

  List<Widget> _accountFields() => [
    AppTextField(
      controller: _emailController,
      label: 'Correo electrónico',
      hint: 'Inserta tu correo electrónico',
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Ingresa tu correo electrónico';
        }
        if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(value.trim())) {
          return 'Ingresa un correo válido';
        }
        return null;
      },
    ),
    const SizedBox(height: 8),
    AppTextField(
      controller: _phoneController,
      label: 'Teléfono',
      hint: 'Inserta tu teléfono',
      keyboardType: TextInputType.phone,
      textInputAction: TextInputAction.next,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Ingresa tu teléfono';
        }
        if (value.trim().length < 10) return 'Ingresa un teléfono válido';
        return null;
      },
    ),
    const SizedBox(height: 8),
    AppTextField(
      controller: _passwordController,
      label: 'Contraseña',
      hint: 'Inserta tu contraseña',
      obscureText: _obscurePassword,
      textInputAction: TextInputAction.next,
      validator: (value) {
        if (value == null || value.isEmpty) return 'Ingresa tu contraseña';
        if (value.length < 8) return 'Usa al menos 8 caracteres';
        return null;
      },
      suffixIcon: IconButton(
        tooltip: _obscurePassword ? 'Mostrar contraseña' : 'Ocultar contraseña',
        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
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
    AppTextField(
      controller: _confirmPasswordController,
      label: 'Confirmar contraseña',
      hint: 'Confirma tu contraseña',
      obscureText: _obscureConfirmation,
      textInputAction: TextInputAction.done,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Confirma tu contraseña';
        }
        if (value != _passwordController.text) {
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
  ];
}

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.step});

  final int step;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 14,
      children: [
        _StepDot(active: step == 0, label: '1. Datos personales'),
        _StepDot(active: step == 1, label: '2. Acceso'),
      ],
    );
  }
}

class _StepDot extends StatelessWidget {
  const _StepDot({required this.active, required this.label});

  final bool active;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Style.getHeaderThree(
        color: active ? Style.getPrimaryColor() : Style.getObscureTextColor(),
        fontSize: 10,
        fontWeight: active ? FontWeight.w600 : FontWeight.w400,
      ),
    );
  }
}

class _RegisterHeader extends StatelessWidget {
  const _RegisterHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
      child: Container(
        color: Style.getPrimaryColor(),
        child: Stack(
          children: [
            Positioned(top: 16, left: 44, child: _HeaderCircle(size: 20)),
            Positioned(top: 52, left: 102, child: _HeaderCircle(size: 26)),
            Positioned(top: 52, left: 160, child: _HeaderCircle(size: 26)),
            Positioned(top: 16, right: 45, child: _HeaderCircle(size: 20)),
            Positioned(
              left: 20,
              top: MediaQuery.paddingOf(context).top + 10,
              child: Material(
                color: Style.getCardColor(),
                shape: const CircleBorder(),
                child: IconButton(
                  tooltip: 'Volver',
                  onPressed: onBack,
                  icon: Icon(
                    Icons.arrow_back_ios_new,
                    color: Style.getPrimaryColor(),
                    size: 18,
                  ),
                ),
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
                    'Crea tu cuenta',
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

class _HeaderCircle extends StatelessWidget {
  const _HeaderCircle({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Icon(
        Icons.circle,
        size: size,
        color: Style.getInverseTextColor().withValues(alpha: .08),
      ),
    );
  }
}
