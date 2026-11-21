import 'package:material_ui/material_ui.dart';

import 'package:conecta_utsh/helpers/style.dart';
import 'package:conecta_utsh/modules/app/components/primary_button.dart';
import 'package:conecta_utsh/modules/app/components/step_indicator.dart';
import 'package:conecta_utsh/modules/app/models/location_catalog.dart';
import 'package:conecta_utsh/modules/app/models/login_response_model.dart';
import 'package:conecta_utsh/modules/app/models/user_preferences_model.dart';
import 'package:conecta_utsh/modules/app/screens/dashboard_screen.dart';
import 'package:conecta_utsh/modules/app/services/auth_service.dart';
import 'package:conecta_utsh/modules/app/services/user_preferences_service.dart';
import 'package:conecta_utsh/utils/widgets/dialogs.dart';

class UserPreferencesScreen extends StatefulWidget {
  const UserPreferencesScreen({
    required this.user,
    required this.authService,
    this.preferencesService = const UserPreferencesService(),
    super.key,
  });

  final LoginUserModel user;
  final AuthService authService;
  final UserPreferencesService preferencesService;

  @override
  State<UserPreferencesScreen> createState() => _UserPreferencesScreenState();
}

class _UserPreferencesScreenState extends State<UserPreferencesScreen> {
  static const _employmentTypes = [
    'Tiempo completo',
    'Medio tiempo',
    'Proyecto',
  ];
  static const _employmentIcons = {
    'Tiempo completo': Icons.work_outline_rounded,
    'Medio tiempo': Icons.schedule_rounded,
    'Prácticas/Estadías': Icons.school_outlined,
    'Proyecto': Icons.assignment_outlined,
  };
  static const _specializations = [
    'Frontend',
    'Backend',
    'Full-Stack',
    'Datos',
    'Móvil',
    'Redes/Infraestructura',
    'QA/Pruebas',
  ];
  static const _specializationIcons = {
    'Frontend': Icons.code_rounded,
    'Backend': Icons.storage_rounded,
    'Full-Stack': Icons.layers_outlined,
    'Datos': Icons.analytics_outlined,
    'Móvil': Icons.smartphone_rounded,
    'Redes/Infraestructura': Icons.router_outlined,
    'QA/Pruebas': Icons.bug_report_outlined,
  };
  static const _modalities = ['En línea', 'Presencial', 'Híbrido'];
  static const _modalityIcons = {
    'En línea': Icons.wifi_rounded,
    'Presencial': Icons.location_on_outlined,
    'Híbrido': Icons.sync_alt_rounded,
  };

  final Set<String> _selectedEmploymentTypes = {};
  final Set<String> _selectedSpecializations = {};
  final Set<String> _selectedModalities = {};
  String? _academicLevel;
  String? _selectedLocation;
  int _step = 0;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final registeredLocation = widget.user.location;
    if (registeredLocation != null &&
        mexicanLocations.contains(registeredLocation)) {
      _selectedLocation = registeredLocation;
    }
  }

  UserPreferencesModel get _currentPreferences => UserPreferencesModel(
    academicLevel: _academicLevel,
    employmentTypes: _employmentTypes
        .where(_selectedEmploymentTypes.contains)
        .toList(),
    specializations: _specializations
        .where(_selectedSpecializations.contains)
        .toList(),
    modalities: _modalities.where(_selectedModalities.contains).toList(),
    location: _needsLocation ? _selectedLocation : null,
  );

  bool get _needsLocation =>
      _selectedModalities.contains('Presencial') ||
      _selectedModalities.contains('Híbrido');

  void _toggle(Set<String> values, String value) {
    setState(() {
      if (!values.add(value)) values.remove(value);
    });
  }

  Future<void> _finish({required bool skipped}) async {
    if (_isSaving) return;
    if (!skipped && _needsLocation && _selectedLocation == null) {
      await _showMessage('Selecciona el estado donde buscas estadías.');
      return;
    }

    setState(() => _isSaving = true);
    try {
      await widget.preferencesService.save(
        userId: widget.user.id,
        preferences: _currentPreferences,
        status: skipped ? 'omitido' : 'completado',
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => DashboardScreen(
            user: widget.user,
            authService: widget.authService,
          ),
        ),
      );
    } on StateError catch (error) {
      await _showMessage(error.message.toString());
    } on FormatException catch (error) {
      await _showMessage(error.message);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _showMessage(String message) => Dialogs.showSimpleDialog(
    context,
    title: 'No se pudieron guardar tus preferencias',
    message: message,
    icon: Icons.error_outline_rounded,
    color: Style.getErrorColor(),
    duration: 2200,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Style.getBackgroundColor(),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          'Preferencias de estadías',
          style: Style.getHeaderOne(
            color: Style.getTextColor(),
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 10, 24, 18),
              child: StepIndicator(
                step: _step,
                firstTitle: 'Perfil laboral',
                secondTitle: 'Modalidad',
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
                child: _step == 0 ? _buildLaborProfile() : _buildLocation(),
              ),
            ),
            _buildActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildLaborProfile() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 16),
        const _RecommendationNote(),
        const SizedBox(height: 22),
        const _SectionTitle(title: 'Nivel académico'),
        const SizedBox(height: 8),
        for (final level in ['TSU', 'Ingeniería'])
          _PreferenceOption(
            label: level,
            icon: level == 'TSU'
                ? Icons.school_outlined
                : Icons.business_center_outlined,
            selected: _academicLevel == level,
            onTap: () => setState(() => _academicLevel = level),
          ),
        const SizedBox(height: 18),
        const _SectionTitle(title: 'Tipo de estadía'),
        const SizedBox(height: 8),
        for (final employmentType in _employmentTypes)
          _PreferenceOption(
            label: employmentType,
            icon: _employmentIcons[employmentType]!,
            selected: _selectedEmploymentTypes.contains(employmentType),
            onTap: () => _toggle(_selectedEmploymentTypes, employmentType),
          ),
        if (widget.user.isInformationTechnologyCareer) ...[
          const SizedBox(height: 18),
          const _SectionTitle(title: 'Especialización (opcional)'),
          const SizedBox(height: 8),
          for (final specialization in _specializations)
            _PreferenceOption(
              label: specialization,
              icon: _specializationIcons[specialization]!,
              selected: _selectedSpecializations.contains(specialization),
              onTap: () => _toggle(_selectedSpecializations, specialization),
            ),
        ],
      ],
    );
  }

  Widget _buildLocation() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StepTitle(
          title: 'Modalidad y ubicación',
          description: 'Elige dónde buscar tus próximas estadías.',
        ),
        const SizedBox(height: 22),
        const _SectionTitle(title: 'Modalidad'),
        const SizedBox(height: 8),
        for (final modality in _modalities)
          _PreferenceOption(
            label: modality,
            icon: _modalityIcons[modality]!,
            selected: _selectedModalities.contains(modality),
            onTap: () => _toggle(_selectedModalities, modality),
          ),
        if (_needsLocation) ...[
          const SizedBox(height: 18),
          const _SectionTitle(title: 'Ubicación'),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _selectedLocation,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: 'Estado o zona',
              prefixIcon: Icon(
                Icons.map_outlined,
                color: Style.getPrimaryColor(),
              ),
              labelStyle: Style.getHeaderThree(
                color: Style.getTextColor(),
                fontSize: 10,
              ),
              hintText: 'Selecciona un estado',
              hintStyle: Style.getHintStyle(
                color: Style.getObscureTextColor(),
                fontSize: 12,
              ),
              filled: true,
              fillColor: Style.getCardColor(),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 15,
              ),
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
                borderSide: BorderSide(
                  color: Style.getPrimaryColor(),
                  width: 1.5,
                ),
              ),
            ),
            items: mexicanLocations
                .map(
                  (location) =>
                      DropdownMenuItem(value: location, child: Text(location)),
                )
                .toList(),
            onChanged: (value) => setState(() => _selectedLocation = value),
          ),
          const SizedBox(height: 6),
          Text(
            'Si buscas estadías fuera del país, selecciona “Fuera de México”.',
            style: Style.getHeaderThree(
              color: Style.getObscureTextColor(),
              fontSize: 10,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildActions() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
      child: _step == 0
          ? Row(
              children: [
                TextButton.icon(
                  onPressed: _isSaving ? null : () => _finish(skipped: true),
                  label: const Text('Omitir'),
                  style: TextButton.styleFrom(
                    foregroundColor: Style.getObscureTextColor(),
                    minimumSize: const Size(102, 50),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: PrimaryButton(
                    label: 'Siguiente',
                    onPressed: _isSaving
                        ? null
                        : () => setState(() => _step = 1),
                  ),
                ),
              ],
            )
          : Row(
              children: [
                OutlinedButton.icon(
                  onPressed: _isSaving ? null : () => setState(() => _step = 0),
                  icon: const Icon(Icons.arrow_back_rounded),
                  label: const Text('Regresar'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Style.getTextColor(),
                    side: BorderSide(color: Style.getSubtleColor()),
                    minimumSize: const Size(120, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: PrimaryButton(
                    label: 'Guardar',
                    onPressed: _isSaving ? null : () => _finish(skipped: false),
                  ),
                ),
              ],
            ),
    );
  }
}

class _StepTitle extends StatelessWidget {
  const _StepTitle({required this.title, required this.description});

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          title,
          textAlign: TextAlign.center,
          style: Style.getHeaderOne(
            color: Style.getTextColor(),
            fontSize: 21,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          description,
          textAlign: TextAlign.center,
          style: Style.getHeaderThree(
            color: Style.getObscureTextColor(),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) => Text(
    title,
    style: Style.getHeaderTwo(
      color: Style.getTextColor(),
      fontSize: 13,
      fontWeight: FontWeight.w700,
    ),
  );
}

class _PreferenceOption extends StatelessWidget {
  const _PreferenceOption({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: selected
            ? Style.getPrimaryColor().withValues(alpha: .05)
            : Style.getCardColor(),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            constraints: const BoxConstraints(minHeight: 48),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected
                    ? Style.getPrimaryColor()
                    : Style.getSubtleColor(),
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: selected
                        ? Style.getPrimaryColor().withValues(alpha: .12)
                        : Style.getSubtleColor().withValues(alpha: .45),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    icon,
                    color: selected
                        ? Style.getPrimaryColor()
                        : Style.getIconColor(),
                    size: 19,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: Style.getHeaderThree(
                      color: Style.getTextColor(),
                      fontSize: 12,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 21,
                  height: 21,
                  decoration: BoxDecoration(
                    color: selected
                        ? Style.getPrimaryColor()
                        : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selected
                          ? Style.getPrimaryColor()
                          : Style.getSubtleColor(),
                      width: 1.5,
                    ),
                  ),
                  child: selected
                      ? Icon(
                          Icons.check_rounded,
                          size: 15,
                          color: Style.getInverseTextColor(),
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RecommendationNote extends StatelessWidget {
  const _RecommendationNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Style.getPrimaryColor().withValues(alpha: .07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Style.getPrimaryColor().withValues(alpha: .16),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.tips_and_updates_outlined,
            color: Style.getPrimaryColor(),
            size: 21,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Estas preferencias personalizan las estadías recomendadas en '
              'Inicio. En el buscador podrás explorar otras áreas y categorías '
              'cuando quieras.',
              style: Style.getHeaderThree(
                color: Style.getTextColor(),
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
