import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:resize/resize.dart';
import 'package:conecta_utsh/helpers/style.dart';
import 'package:conecta_utsh/modules/app/components/app_text_field.dart';
import 'package:conecta_utsh/modules/app/components/primary_button.dart';
import 'package:conecta_utsh/modules/app/models/education_catalog.dart';
import 'package:conecta_utsh/modules/app/models/user_profile_model.dart';
import 'package:conecta_utsh/modules/app/providers/user_profile_controller.dart';
import 'package:conecta_utsh/modules/app/services/user_profile_service.dart';
import 'package:conecta_utsh/utils/widgets/dialogs.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({
    required this.profile,
    required this.profileService,
    required this.profileController,
    super.key,
  });

  final UserProfile profile;
  final UserProfileService profileService;
  final UserProfileController profileController;

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  static const _cuatrimestres = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11];
  static final _namePattern = RegExp(
    r'^[A-Za-zÁÉÍÓÚÜÑáéíóúüñ]+(?: [A-Za-zÁÉÍÓÚÜÑáéíóúüñ]+)*$',
  );
  static final _nameCharacters = RegExp(r'[A-Za-zÁÉÍÓÚÜÑáéíóúüñ ]');
  static final _repeatedSpaces = RegExp(r' {2,}');

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombreController;
  late final TextEditingController _apellidoPaternoController;
  late final TextEditingController _apellidoMaternoController;
  late final TextEditingController _telefonoController;
  late String? _direccion;
  late String? _carrera;
  late int? _cuatrimestre;
  bool _isSaving = false;
  bool _isDiscarding = false;
  bool _discardConfirmed = false;
  String? _errorMessage;

  List<String> get _carreras =>
      _direccion == null ? const [] : educationCatalog[_direccion] ?? const [];

  bool get _hasChanges => _buildChanges().isNotEmpty;

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
    super.dispose();
  }

  Map<String, dynamic> _buildChanges() {
    final original = widget.profile;
    final name = _nombreController.text.trim();
    final paternal = _apellidoPaternoController.text.trim();
    final maternal = _normalizePersonName(_apellidoMaternoController.text);
    final phone = _telefonoController.text.trim();
    final changes = <String, dynamic>{};

    if (name != original.nombre) changes['nombre'] = name;
    if (paternal != original.apellidoPaterno) {
      changes['apellidoPaterno'] = paternal;
    }
    if (maternal != original.apellidoMaterno) {
      changes['apellidoMaterno'] = maternal;
    }
    if (_direccion != original.direccion || _carrera != original.carrera) {
      changes['direccion'] = _direccion;
      changes['carrera'] = _carrera;
    }
    if (_cuatrimestre != original.cuatrimestre) {
      changes['cuatrimestre'] = _cuatrimestre;
    }
    final originalPhone = original.telefono?.trim() ?? '';
    if (phone != originalPhone) changes['telefono'] = phone;
    return changes;
  }

  Future<void> _save() async {
    if (_isSaving || !(_formKey.currentState?.validate() ?? false)) return;
    final changes = _buildChanges();
    if (changes.isEmpty) {
      _showMessage('No hay cambios que guardar.');
      return;
    }
    if (_direccion == null ||
        _carrera == null ||
        !_carreras.contains(_carrera) ||
        _cuatrimestre == null ||
        !_cuatrimestres.contains(_cuatrimestre)) {
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });
    try {
      await widget.profileService.actualizarPerfil(changes);
      final refreshed = await widget.profileService.obtenerPerfil(
        fallback: widget.profile,
      );
      widget.profileController.update(refreshed);
      if (mounted) Navigator.of(context).pop(true);
    } on UserProfileApiException catch (error) {
      if (!mounted) return;
      if (error.statusCode == 409) {
        try {
          widget.profileController.update(
            await widget.profileService.obtenerPerfil(fallback: widget.profile),
          );
        } on UserProfileApiException {
          // Keep the conflict message if the refresh also fails.
        }
      }
      if (error.statusCode != 401 && error.statusCode != 403) {
        setState(() => _errorMessage = error.message);
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _handlePop(bool didPop) async {
    if (didPop || !_hasChanges || _isSaving || _isDiscarding) return;
    _isDiscarding = true;
    try {
      final discard = await Dialogs.showConfirmDialogDelete(
        context,
        title: 'Descartar cambios',
        message: '¿Descartar cambios?',
        icon: Icons.warning_amber_rounded,
        confirmText: 'Descartar',
        cancelText: 'Seguir editando',
        confirmColor: Theme.of(context).colorScheme.error,
        cancelColor: Theme.of(context).colorScheme.surfaceContainerHigh,
      );
      if (discard == true && mounted) {
        setState(() => _discardConfirmed = true);
        Navigator.of(context).pop();
      }
    } finally {
      _isDiscarding = false;
    }
  }

  String? _validatePersonName(
    String? value, {
    required String field,
    required bool isRequired,
    bool trimAndNormalize = false,
  }) {
    final raw = value ?? '';
    final name = trimAndNormalize ? _normalizePersonName(raw) : raw;
    if (name.isEmpty) {
      return isRequired ? 'Ingresa $field.' : null;
    }
    if (!trimAndNormalize && name != name.trim()) {
      return 'Quita los espacios al inicio o al final.';
    }
    if (name.replaceAll(' ', '').length < 3) {
      return 'Escribe al menos 3 letras.';
    }
    if (!_namePattern.hasMatch(name)) return 'Usa solo letras y acentos.';
    return null;
  }

  String? _validatePhone(String? value) {
    final phone = value?.trim() ?? '';
    final originallyHadPhone =
        widget.profile.telefono?.trim().isNotEmpty == true;
    if (phone.isEmpty) {
      return originallyHadPhone ? 'Ingresa un teléfono de 10 dígitos' : null;
    }
    if (!RegExp(r'^\d{10}$').hasMatch(phone)) {
      return 'Ingresa un teléfono de 10 dígitos';
    }
    return null;
  }

  String _normalizePersonName(String value) =>
      value.trim().replaceAll(_repeatedSpaces, ' ');

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

  Widget _readOnlyValue(String label, String value) => ListTile(
    contentPadding: EdgeInsets.zero,
    title: Text(label, style: Theme.of(context).textTheme.labelMedium),
    subtitle: Text(value.isEmpty ? 'No disponible' : value),
    trailing: const Icon(Icons.lock_outline_rounded),
  );

  @override
  Widget build(BuildContext context) {
    return PopScope<Object?>(
      canPop: (!_hasChanges || _discardConfirmed) && !_isSaving,
      onPopInvokedWithResult: (didPop, _) => _handlePop(didPop),
      child: Scaffold(
        backgroundColor: Style.getBackgroundColor(),
        appBar: AppBar(
          title: const Text('Editar perfil'),
          backgroundColor: Style.getBackgroundColor(),
          foregroundColor: Style.getTextColor(),
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            tooltip: 'Regresar',
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
          ),
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
                semanticsLabel: 'Nombre',
                inputFormatters: [
                  FilteringTextInputFormatter.allow(_nameCharacters),
                  LengthLimitingTextInputFormatter(50),
                ],
                validator: (value) => _validatePersonName(
                  value,
                  field: 'tu nombre',
                  isRequired: true,
                ),
                textInputAction: TextInputAction.next,
              ),
              SizedBox(height: 12.h),
              AppTextField(
                controller: _apellidoPaternoController,
                label: 'Apellido paterno',
                hint: 'Apellido paterno',
                semanticsLabel: 'Apellido paterno',
                inputFormatters: [
                  FilteringTextInputFormatter.allow(_nameCharacters),
                  LengthLimitingTextInputFormatter(50),
                ],
                validator: (value) => _validatePersonName(
                  value,
                  field: 'tu apellido paterno',
                  isRequired: true,
                ),
                textInputAction: TextInputAction.next,
              ),
              SizedBox(height: 12.h),
              AppTextField(
                controller: _apellidoMaternoController,
                label: 'Apellido materno',
                hint: 'Apellido materno',
                semanticsLabel: 'Apellido materno',
                inputFormatters: [
                  FilteringTextInputFormatter.allow(_nameCharacters),
                  LengthLimitingTextInputFormatter(50),
                ],
                validator: (value) => _validatePersonName(
                  value,
                  field: 'tu apellido materno',
                  isRequired: true,
                  trimAndNormalize: true,
                ),
                textInputAction: TextInputAction.next,
              ),
              SizedBox(height: 12.h),
              AppTextField(
                controller: _telefonoController,
                label: 'Teléfono',
                hint: '10 dígitos (opcional)',
                semanticsLabel: 'Teléfono',
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
                key: ValueKey('direccion-dropdown-$_direccion'),
                initialValue: _direccion,
                isExpanded: true,
                decoration: _dropdownDecoration('Dirección académica'),
                validator: (value) =>
                    value == null ? 'Selecciona una dirección.' : null,
                items: educationCatalog.keys
                    .map(
                      (direction) => DropdownMenuItem(
                        value: direction,
                        child: Text(direction, overflow: TextOverflow.ellipsis),
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
                      (career) => DropdownMenuItem(
                        value: career,
                        child: Text(career, overflow: TextOverflow.ellipsis),
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
                      (semester) => DropdownMenuItem(
                        value: semester,
                        child: Text('$semester'),
                      ),
                    )
                    .toList(),
                onChanged: _isSaving
                    ? null
                    : (value) => setState(() => _cuatrimestre = value),
              ),
              SizedBox(height: 18.h),
              _sectionTitle('Datos de cuenta'),
              _readOnlyValue('Correo electrónico', widget.profile.correo),
              _readOnlyValue('Matrícula', widget.profile.matricula),
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
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}
