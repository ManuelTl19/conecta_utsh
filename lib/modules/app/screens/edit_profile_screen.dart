import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:resize/resize.dart';
import 'package:conecta_utsh/helpers/style.dart';
import 'package:conecta_utsh/modules/app/components/app_text_field.dart';
import 'package:conecta_utsh/modules/app/components/primary_button.dart';
import 'package:conecta_utsh/modules/app/models/education_catalog.dart';
import 'package:conecta_utsh/modules/app/models/user_profile_model.dart';
import 'package:conecta_utsh/modules/app/services/user_profile_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({
    required this.profile,
    required this.profileService,
    super.key,
  });

  final UserProfile profile;
  final UserProfileService profileService;

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  static const _cuatrimestres = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11];

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombreController;
  late final TextEditingController _apellidoPaternoController;
  late final TextEditingController _apellidoMaternoController;
  late final TextEditingController _telefonoController;
  late final TextEditingController _correoController;
  late final TextEditingController _matriculaController;
  late String? _direccion;
  late String? _carrera;
  late int? _cuatrimestre;
  bool _isSaving = false;
  String? _errorMessage;

  List<String> get _carreras =>
      _direccion == null ? const [] : educationCatalog[_direccion] ?? const [];

  @override
  void initState() {
    super.initState();
    final profile = widget.profile;
    _nombreController = TextEditingController(text: profile.nombre);
    _apellidoPaternoController = TextEditingController(
      text: profile.apellidoPaterno,
    );
    _apellidoMaternoController = TextEditingController(
      text: profile.apellidoMaterno,
    );
    _telefonoController = TextEditingController(text: profile.telefono ?? '');
    _correoController = TextEditingController(text: profile.correo);
    _matriculaController = TextEditingController(text: profile.matricula);
    _direccion = educationCatalog.containsKey(profile.direccion)
        ? profile.direccion
        : null;
    _carrera = _carreras.contains(profile.carrera) ? profile.carrera : null;
    _cuatrimestre = _cuatrimestres.contains(profile.cuatrimestre)
        ? profile.cuatrimestre
        : null;
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidoPaternoController.dispose();
    _apellidoMaternoController.dispose();
    _telefonoController.dispose();
    _correoController.dispose();
    _matriculaController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_isSaving || !(_formKey.currentState?.validate() ?? false)) return;
    final direccion = _direccion;
    final carrera = _carrera;
    final cuatrimestre = _cuatrimestre;
    if (direccion == null ||
        carrera == null ||
        cuatrimestre == null ||
        !(_carreras.contains(carrera))) {
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });
    try {
      await widget.profileService.updateCurrentUser(
        UserProfileUpdate(
          nombre: _nombreController.text.trim(),
          apellidoPaterno: _apellidoPaternoController.text.trim(),
          apellidoMaterno: _apellidoMaternoController.text.trim(),
          telefono: _telefonoController.text.trim(),
          direccion: direccion,
          carrera: carrera,
          cuatrimestre: cuatrimestre,
        ),
      );
      if (mounted) Navigator.of(context).pop(true);
    } on Exception catch (error) {
      if (mounted) {
        setState(() => _errorMessage = error.toString());
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  String? _requiredText(String? value, String field) {
    if (value == null || value.trim().isEmpty) {
      return 'Ingresa $field.';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    final phone = value?.trim() ?? '';
    if (phone.isEmpty || RegExp(r'^\d{10}$').hasMatch(phone)) return null;
    return 'Ingresa un teléfono de 10 dígitos.';
  }

  InputDecoration _dropdownDecoration(String label) => InputDecoration(
    labelText: label,
    labelStyle: Style.getHeaderThree(color: Style.getTextColor(), fontSize: 10),
    filled: true,
    fillColor: Style.getCardColor(),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
    border: OutlineInputBorder(
      borderRadius: Style.getCircularBorderRadius(18),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: Style.getCircularBorderRadius(18),
      borderSide: BorderSide(color: Style.getSubtleColor()),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: Style.getCircularBorderRadius(18),
      borderSide: BorderSide(color: Style.getPrimaryColor(), width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: Style.getCircularBorderRadius(18),
      borderSide: BorderSide(color: Style.getErrorColor()),
    ),
  );

  Widget _sectionTitle(String title) => Padding(
    padding: Style.getPaddingVertical(padding: 6),
    child: Text(
      title,
      style: Style.getHeaderTwo(
        color: Style.getTextColor(),
        fontSize: 14,
        fontWeight: FontWeight.w700,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Style.getBackgroundColor(),
      appBar: AppBar(
        title: const Text('Editar perfil'),
        backgroundColor: Style.getBackgroundColor(),
        foregroundColor: Style.getTextColor(),
        surfaceTintColor: Colors.transparent,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: Style.getPaddingSymmetric(horizontal: 22, vertical: 18),
          children: [
            _sectionTitle('Datos personales'),
            AppTextField(
              controller: _nombreController,
              label: 'Nombre',
              hint: 'Nombre',
              validator: (value) => _requiredText(value, 'tu nombre'),
              textInputAction: TextInputAction.next,
            ),
            SizedBox(height: 12.h),
            AppTextField(
              controller: _apellidoPaternoController,
              label: 'Apellido paterno',
              hint: 'Apellido paterno',
              validator: (value) => _requiredText(value, 'tu apellido paterno'),
              textInputAction: TextInputAction.next,
            ),
            SizedBox(height: 12.h),
            AppTextField(
              controller: _apellidoMaternoController,
              label: 'Apellido materno',
              hint: 'Apellido materno',
              validator: (value) => _requiredText(value, 'tu apellido materno'),
              textInputAction: TextInputAction.next,
            ),
            SizedBox(height: 12.h),
            AppTextField(
              controller: _telefonoController,
              label: 'Teléfono',
              hint: '10 dígitos (opcional)',
              validator: _validatePhone,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ],
            ),
            SizedBox(height: 18.h),
            _sectionTitle('Datos académicos'),
            DropdownButtonFormField<String>(
              key: const ValueKey('direccion-dropdown'),
              initialValue: _direccion,
              isExpanded: true,
              decoration: _dropdownDecoration('Dirección académica'),
              validator: (value) =>
                  value == null ? 'Selecciona una dirección.' : null,
              items: educationCatalog.keys
                  .map(
                    (direccion) => DropdownMenuItem(
                      value: direccion,
                      child: Text(
                        direccion,
                        overflow: TextOverflow.ellipsis,
                        style: Style.getTextStyle(
                          color: Style.getTextColor(),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: _isSaving
                  ? null
                  : (value) {
                      setState(() {
                        _direccion = value;
                        _carrera = null;
                      });
                      _formKey.currentState?.validate();
                    },
            ),
            SizedBox(height: 12.h),
            DropdownButtonFormField<String>(
              key: ValueKey('carrera-dropdown-$_direccion'),
              initialValue: _carrera,
              isExpanded: true,
              decoration: _dropdownDecoration('Carrera'),
              validator: (value) {
                if (value == null) return 'Selecciona una carrera.';
                if (!_carreras.contains(value)) {
                  return 'La carrera no pertenece a la dirección elegida.';
                }
                return null;
              },
              items: _carreras
                  .map(
                    (carrera) => DropdownMenuItem(
                      value: carrera,
                      child: Text(
                        carrera,
                        overflow: TextOverflow.ellipsis,
                        style: Style.getTextStyle(
                          color: Style.getTextColor(),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: _isSaving
                  ? null
                  : (value) => setState(() => _carrera = value),
            ),
            SizedBox(height: 12.h),
            DropdownButtonFormField<int>(
              key: const ValueKey('cuatrimestre-dropdown'),
              initialValue: _cuatrimestre,
              decoration: _dropdownDecoration('Cuatrimestre'),
              validator: (value) => value == null
                  ? 'Selecciona un cuatrimestre entre 1 y 11.'
                  : null,
              items: _cuatrimestres
                  .map(
                    (cuatrimestre) => DropdownMenuItem(
                      value: cuatrimestre,
                      child: Text(
                        '$cuatrimestre',
                        style: Style.getTextStyle(
                          color: Style.getTextColor(),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: _isSaving
                  ? null
                  : (value) => setState(() => _cuatrimestre = value),
            ),
            SizedBox(height: 18.h),
            _sectionTitle('Datos de cuenta'),
            AppTextField(
              controller: _correoController,
              label: 'Correo electrónico',
              hint: 'Correo electrónico',
              validator: (_) => null,
              enabled: false,
            ),
            SizedBox(height: 12.h),
            AppTextField(
              controller: _matriculaController,
              label: 'Matrícula',
              hint: 'Matrícula',
              validator: (_) => null,
              enabled: false,
            ),
            if (_errorMessage != null) ...[
              SizedBox(height: 14.h),
              Text(
                _errorMessage!,
                style: Style.getTextStyle(
                  color: Style.getErrorColor(),
                  fontSize: 11,
                ),
              ),
            ],
            SizedBox(height: 24.h),
            PrimaryButton(
              label: 'Guardar',
              isLoading: _isSaving,
              onPressed: _isSaving ? null : _save,
            ),
            SizedBox(height: 20.h),
          ],
        ),
      ),
    );
  }
}
