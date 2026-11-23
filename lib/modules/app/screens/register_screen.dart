import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import 'package:conecta_utsh/helpers/style.dart';
import 'package:conecta_utsh/helpers/providers/app_settings.dart';
import 'package:conecta_utsh/modules/app/components/app_text_field.dart';
import 'package:conecta_utsh/modules/app/components/password_requirements_info.dart';
import 'package:conecta_utsh/modules/app/components/primary_button.dart';
import 'package:conecta_utsh/modules/app/components/step_indicator.dart';
import 'package:conecta_utsh/modules/app/components/theme_toggle_button.dart';
import 'package:conecta_utsh/modules/app/models/education_catalog.dart';
import 'package:conecta_utsh/modules/app/models/register_model.dart';
import 'package:conecta_utsh/modules/app/services/auth_service.dart';
import 'package:conecta_utsh/modules/app/services/password_validator.dart';
import 'package:conecta_utsh/utils/widgets/dialogs.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({this.authService, super.key});

  final AuthService? authService;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  static final _namePattern = RegExp(
    r'^[A-Za-zÁÉÍÓÚÜÑáéíóúüñ]+(?: [A-Za-zÁÉÍÓÚÜÑáéíóúüñ]+)*$',
  );
  static final _nameCharacters = RegExp(r'[A-Za-zÁÉÍÓÚÜÑáéíóúüñ ]');
  static final _repeatedSpaces = RegExp(r' {2,}');
  static final _emailPattern = RegExp(
    r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$',
  );

  final _personalFormKey = GlobalKey<FormState>();
  final _accountFormKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _paternalSurnameController = TextEditingController();
  final _maternalSurnameController = TextEditingController();
  final _enrollmentController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  AuthService? _ownedAuthService;
  int _step = 0;
  String? _selectedDirection;
  String? _selectedCareer;
  int? _selectedSemester;
  bool _isSubmitting = false;
  bool _isSavingTheme = false;
  bool _obscurePassword = true;
  bool _obscureConfirmation = true;

  AuthService get _authService =>
      widget.authService ?? (_ownedAuthService ??= AuthService());

  @override
  void dispose() {
    _firstNameController.dispose();
    _paternalSurnameController.dispose();
    _maternalSurnameController.dispose();
    _enrollmentController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _ownedAuthService?.close();
    super.dispose();
  }

  Future<void> _continue() async {
    if (!(_personalFormKey.currentState?.validate() ?? false)) {
      await _showMessage(
        'Completa los datos personales, académicos y el cuatrimestre.',
        title: 'Faltan datos',
      );
      return;
    }
    setState(() => _step = 1);
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

  void _goBack() {
    if (_step == 1) {
      setState(() => _step = 0);
    } else {
      Navigator.of(context).maybePop();
    }
  }

  Future<void> _submit() async {
    if (!(_accountFormKey.currentState?.validate() ?? false)) {
      await _showMessage(
        'Revisa los datos de acceso e intenta de nuevo.',
        title: 'Faltan datos',
      );
      return;
    }
    final direction = _selectedDirection;
    final career = _selectedCareer;
    final semester = _selectedSemester;
    if (direction == null || career == null || semester == null) {
      await _showMessage('Completa tu dirección, carrera y cuatrimestre.');
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await _authService.register(
        RegisterModel(
          firstName: _normalizePersonName(_firstNameController.text),
          paternalSurname: _normalizePersonName(
            _paternalSurnameController.text,
          ),
          maternalSurname: _normalizePersonName(
            _maternalSurnameController.text,
          ),
          enrollment: _enrollmentController.text.trim(),
          direction: direction,
          career: career,
          semester: semester,
          email: _emailController.text.trim(),
          phone: _phoneController.text.trim().isEmpty
              ? null
              : _phoneController.text.trim(),
          password: _passwordController.text.trim(),
          confirmPassword: _confirmPasswordController.text.trim(),
        ),
      );
      if (!mounted) return;
      await _showMessage(
        'Tu cuenta se registró correctamente.',
        title: 'Registro exitoso',
        success: true,
      );
      if (!mounted) return;
      Navigator.of(context).pop(_emailController.text.trim());
    } on AuthApiException catch (error) {
      if (mounted) {
        await _showMessage(error.message, title: 'No se pudo registrar');
      }
    } on StateError catch (error) {
      if (mounted) {
        await _showMessage(
          error.message.toString(),
          title: 'No se pudo registrar',
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
        await _showMessage(error.message, title: 'No se pudo registrar');
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

  Future<void> _showMessage(
    String message, {
    String title = 'Ocurrió un error',
    bool success = false,
  }) => Dialogs.showSimpleDialog(
    context,
    title: title,
    message: message,
    icon: success
        ? Icons.check_circle_outline_rounded
        : Icons.error_outline_rounded,
    color: success ? Style.getSuccessColor() : Style.getErrorColor(),
    duration: 2200,
  );

  String? _validatePersonName(String? value, String field) {
    final name = _normalizePersonName(value ?? '');
    if (name.isEmpty) return 'Ingresa $field';
    if (name.replaceAll(' ', '').length < 3) {
      return 'Escribe al menos 3 letras';
    }
    if (!_namePattern.hasMatch(name)) {
      return 'Usa solo letras y acentos';
    }
    return null;
  }

  String _normalizePersonName(String value) =>
      value.trim().replaceAll(_repeatedSpaces, ' ');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Style.getBackgroundColor(),
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final headerHeight = (constraints.maxHeight * .20)
                .clamp(190.0, 230.0)
                .toDouble();
            return Column(
              children: [
                SizedBox(
                  height: headerHeight,
                  width: double.infinity,
                  child: _RegisterHeader(
                    onBack: _goBack,
                    onToggleTheme: _toggleTheme,
                    isSavingTheme: _isSavingTheme,
                  ),
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
                          StepIndicator(
                            step: _step,
                            firstTitle: 'Datos personales',
                            secondTitle: 'Acceso',
                          ),
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
      inputFormatters: [
        FilteringTextInputFormatter.allow(_nameCharacters),
        _SingleSpaceFormatter(),
        LengthLimitingTextInputFormatter(50),
      ],
      validator: (value) => _validatePersonName(value, 'tu nombre'),
      textInputAction: TextInputAction.next,
    ),
    const SizedBox(height: 12),
    AppTextField(
      controller: _paternalSurnameController,
      label: 'Apellido paterno',
      hint: 'Inserta apellido paterno',
      inputFormatters: [
        FilteringTextInputFormatter.allow(_nameCharacters),
        _SingleSpaceFormatter(),
        LengthLimitingTextInputFormatter(50),
      ],
      validator: (value) => _validatePersonName(value, 'tu apellido paterno'),
      textInputAction: TextInputAction.next,
    ),
    const SizedBox(height: 12),
    AppTextField(
      controller: _maternalSurnameController,
      label: 'Apellido materno',
      hint: 'Inserta apellido materno',
      inputFormatters: [
        FilteringTextInputFormatter.allow(_nameCharacters),
        _SingleSpaceFormatter(),
        LengthLimitingTextInputFormatter(50),
      ],
      validator: (value) => _validatePersonName(value, 'tu apellido materno'),
      textInputAction: TextInputAction.next,
    ),
    const SizedBox(height: 12),
    AppTextField(
      controller: _enrollmentController,
      label: 'Matrícula',
      hint: 'Inserta tu matrícula',
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(8),
      ],
      validator: (value) {
        final enrollment = value?.trim() ?? '';
        if (enrollment.isEmpty) return 'Ingresa tu matrícula';
        if (!RegExp(r'^\d{8}$').hasMatch(enrollment)) {
          return 'La matrícula debe tener exactamente 8 dígitos';
        }
        return null;
      },
      textInputAction: TextInputAction.next,
    ),
    const SizedBox(height: 12),
    DropdownButtonFormField<String>(
      key: const ValueKey('direccion-dropdown'),
      initialValue: _selectedDirection,
      decoration: _dropdownDecoration('Dirección', 'Selecciona un área'),
      items: educationCatalog.keys
          .map(
            (direction) =>
                DropdownMenuItem(value: direction, child: Text(direction)),
          )
          .toList(),
      validator: (value) => value == null ? 'Selecciona una dirección' : null,
      onChanged: (value) {
        setState(() {
          _selectedDirection = value;
          _selectedCareer = null;
          _selectedSemester = null;
        });
      },
    ),
    if (_selectedDirection != null) ...[
      const SizedBox(height: 12),
      DropdownButtonFormField<String>(
        key: const ValueKey('carrera-dropdown'),
        initialValue: _selectedCareer,
        decoration: _dropdownDecoration('Carrera', 'Selecciona tu carrera'),
        isExpanded: true,
        items: educationCatalog[_selectedDirection]!
            .map(
              (career) => DropdownMenuItem(value: career, child: Text(career)),
            )
            .toList(),
        validator: (value) => value == null ? 'Selecciona una carrera' : null,
        onChanged: (value) => setState(() {
          _selectedCareer = value;
          _selectedSemester = null;
        }),
      ),
    ],
    if (_selectedCareer != null) ...[
      const SizedBox(height: 12),
      DropdownButtonFormField<int>(
        key: const ValueKey('cuatrimestre-dropdown'),
        initialValue: _selectedSemester,
        decoration: _dropdownDecoration(
          'Cuatrimestre',
          _selectedCareer!.startsWith('TSU en ')
              ? 'Selecciona del 1 al 6'
              : 'Selecciona del 7 al 10',
        ),
        items: cuatrimestresForCareer(_selectedCareer)
            .map(
              (semester) => DropdownMenuItem(
                value: semester,
                child: Text('$semester° cuatrimestre'),
              ),
            )
            .toList(),
        validator: (value) =>
            value == null ? 'Selecciona tu cuatrimestre' : null,
        onChanged: (value) => setState(() => _selectedSemester = value),
      ),
    ],
  ];

  InputDecoration _dropdownDecoration(
    String label,
    String hint,
  ) => InputDecoration(
    labelText: label,
    labelStyle: Style.getHeaderThree(color: Style.getTextColor(), fontSize: 10),
    hintText: hint,
    hintStyle: Style.getHintStyle(
      color: Style.getObscureTextColor(),
      fontSize: 12,
    ),
    filled: true,
    fillColor: Style.getCardColor(),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: BorderSide(color: Style.getSubtleColor()),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: BorderSide(color: Style.getPrimaryColor(), width: 1.5),
    ),
  );

  List<Widget> _accountFields() => [
    AppTextField(
      controller: _emailController,
      label: 'Correo electrónico',
      hint: 'Inserta tu correo electrónico',
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      inputFormatters: [LengthLimitingTextInputFormatter(100)],
      validator: (value) {
        final email = value?.trim() ?? '';
        if (email.isEmpty) {
          return 'Ingresa tu correo electrónico';
        }
        if (!_emailPattern.hasMatch(email)) {
          return 'Ingresa un correo válido';
        }
        return null;
      },
    ),
    const SizedBox(height: 12),
    AppTextField(
      controller: _phoneController,
      label: 'Teléfono',
      hint: 'Inserta tu teléfono',
      keyboardType: TextInputType.phone,
      textInputAction: TextInputAction.next,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(10),
      ],
      validator: (value) {
        final phone = value?.trim() ?? '';
        if (phone.isNotEmpty && !RegExp(r'^\d{10}$').hasMatch(phone)) {
          return 'Ingresa un teléfono de 10 dígitos';
        }
        return null;
      },
    ),
    const SizedBox(height: 12),
    AppTextField(
      controller: _passwordController,
      label: 'Contraseña',
      hint: 'Inserta tu contraseña',
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
      controller: _confirmPasswordController,
      label: 'Confirmar contraseña',
      hint: 'Confirma tu contraseña',
      obscureText: _obscureConfirmation,
      textInputAction: TextInputAction.done,
      inputFormatters: [LengthLimitingTextInputFormatter(128)],
      validator: (value) {
        final confirmation = value?.trim() ?? '';
        if (confirmation.isEmpty) {
          return 'Confirma tu contraseña';
        }
        if (confirmation != _passwordController.text.trim()) {
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

class _SingleSpaceFormatter extends TextInputFormatter {
  static final _repeatedSpaces = RegExp(r' {2,}');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final normalizedText = newValue.text.replaceAll(_repeatedSpaces, ' ');
    if (normalizedText == newValue.text) return newValue;

    // Caso común: el usuario tecleó un espacio justo después de otro.
    // Ignoramos la edición y conservamos el estado anterior.
    if (normalizedText == oldValue.text) return oldValue;

    // Caso general (pegado de texto, etc.)
    int normalizeOffset(int offset) {
      if (offset < 0) return 0;
      final bounded = offset.clamp(0, newValue.text.length).toInt();
      return newValue.text
          .substring(0, bounded)
          .replaceAll(_repeatedSpaces, ' ')
          .length;
    }

    return TextEditingValue(
      text: normalizedText,
      selection: TextSelection(
        baseOffset: normalizeOffset(newValue.selection.baseOffset),
        extentOffset: normalizeOffset(newValue.selection.extentOffset),
        affinity: newValue.selection.affinity,
        isDirectional: newValue.selection.isDirectional,
      ),
      // Sin composing: es un cambio mayor (pegado), no una tecla.
    );
  }
}

class _RegisterHeader extends StatelessWidget {
  const _RegisterHeader({
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
                icon: Icons.assignment_turned_in_outlined, // trámites / estadía
                size: 78,
                angleDegrees: 22,
              ),
            ),
            Positioned(
              top: 150,
              right: 88,
              child: _HeaderIcon(
                icon: Icons.badge_outlined, // credencial / alumno
                size: 78,
                angleDegrees: 22,
              ),
            ),
            Positioned(
              top: 44,
              right: 38,
              child: _HeaderIcon(
                icon: Icons.business_outlined, // empresa
                size: 78,
                angleDegrees: -12, // otro ángulo para variar
              ),
            ),
            Positioned(
              left: 20,
              top: MediaQuery.paddingOf(context).top + 10,
              child: Material(
                color: Style.getCardColor(),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
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
