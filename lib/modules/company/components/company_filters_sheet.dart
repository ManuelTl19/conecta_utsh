import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:resize/resize.dart';
import 'package:conecta_utsh/helpers/style.dart';
import 'package:conecta_utsh/modules/app/components/primary_button.dart';
import 'package:conecta_utsh/modules/app/models/education_catalog.dart';
import 'package:conecta_utsh/modules/company/models/company_filters.dart';
import 'package:conecta_utsh/modules/company/models/company_model.dart';
import 'package:conecta_utsh/modules/company/services/company_service.dart';

class _CareerMultiSelectSheet extends StatefulWidget {
  const _CareerMultiSelectSheet({
    required this.options,
    required this.selected,
  });

  final List<String> options;
  final List<String> selected;

  @override
  State<_CareerMultiSelectSheet> createState() =>
      _CareerMultiSelectSheetState();
}

class _CareerMultiSelectSheetState extends State<_CareerMultiSelectSheet> {
  late final Set<String> _selected = widget.selected
      .where(widget.options.contains)
      .toSet();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return SafeArea(
      top: false,
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * .75,
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 8.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Carreras que aceptan',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: colors.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Puedes seleccionar más de una carrera.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                key: ValueKey('career-options-${widget.options.length}'),
                itemCount: widget.options.length,
                itemBuilder: (context, index) {
                  final career = widget.options[index];
                  final selected = _selected.contains(career);
                  return CheckboxListTile(
                    value: selected,
                    title: Text(
                      career,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colors.onSurface,
                      ),
                    ),
                    controlAffinity: ListTileControlAffinity.trailing,
                    activeColor: colors.primary,
                    onChanged: (value) => setState(() {
                      if (value ?? false) {
                        _selected.add(career);
                      } else {
                        _selected.remove(career);
                      }
                    }),
                  );
                },
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 16.h),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        minimumSize: const Size.fromHeight(44),
                      ),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.of(
                        context,
                      ).pop(widget.options.where(_selected.contains).toList()),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(44),
                      ),
                      child: Text('Listo (${_selected.length})'),
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

class CompanyFiltersSheet extends StatefulWidget {
  const CompanyFiltersSheet({
    required this.initialFilters,
    required this.query,
    required this.companyService,
    this.sourceCompanies,
    super.key,
  });

  final CompanyFilters initialFilters;
  final String query;
  final CompanyService companyService;
  final List<CompanyModel>? sourceCompanies;

  @override
  State<CompanyFiltersSheet> createState() => _CompanyFiltersSheetState();
}

class _CompanyFiltersSheetState extends State<CompanyFiltersSheet> {
  static const _ratings = [
    (label: 'Todas', value: null),
    (label: '3+', value: 3.0),
    (label: '4+', value: 4.0),
    (label: '4.5+', value: 4.5),
  ];

  late CompanyFilters _draft;
  CompanyFilterOptions? _options;
  Timer? _countDebounce;
  int _countRequestId = 0;
  int _matchingCount = 0;
  bool _isLoadingOptions = true;
  bool _isLoadingCount = true;
  Object? _optionsError;
  Object? _countError;

  @override
  void initState() {
    super.initState();
    _draft = widget.initialFilters;
    _loadOptions();
    _scheduleCount(immediate: true);
  }

  @override
  void dispose() {
    _countDebounce?.cancel();
    _countRequestId++;
    super.dispose();
  }

  Future<void> _loadOptions() async {
    try {
      final options = await widget.companyService.getFilterOptions(
        sourceCompanies: widget.sourceCompanies,
      );
      if (!mounted) return;
      setState(() {
        _options = options;
        _isLoadingOptions = false;
        _optionsError = null;
      });
    } on Exception catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoadingOptions = false;
        _optionsError = error;
      });
    }
  }

  void _scheduleCount({bool immediate = false}) {
    _countDebounce?.cancel();
    final requestId = ++_countRequestId;
    setState(() {
      _isLoadingCount = true;
      _countError = null;
    });
    if (immediate) {
      _loadCount(requestId);
    } else {
      _countDebounce = Timer(
        const Duration(milliseconds: 400),
        () => _loadCount(requestId),
      );
    }
  }

  Future<void> _loadCount(int requestId) async {
    try {
      final count = await widget.companyService.countCompanies(
        query: widget.query,
        filters: _draft,
        sourceCompanies: widget.sourceCompanies,
      );
      if (!mounted || requestId != _countRequestId) return;
      setState(() {
        _matchingCount = count;
        _isLoadingCount = false;
        _countError = null;
      });
    } on Exception catch (error) {
      if (!mounted || requestId != _countRequestId) return;
      setState(() {
        _isLoadingCount = false;
        _countError = error;
      });
    }
  }

  void _updateDraft(CompanyFilters filters) {
    setState(() => _draft = filters);
    _scheduleCount();
  }

  void _clearAll() => _updateDraft(const CompanyFilters());

  List<String> get _availableCareers {
    final direction = _draft.direccion;
    if (direction != null) return educationCatalog[direction] ?? const [];
    return educationCatalog.values.expand((careers) => careers).toSet().toList()
      ..sort();
  }

  InputDecoration _dropdownDecoration(String hint) => InputDecoration(
    hintText: hint,
    filled: true,
    fillColor: Style.getCardColor(),
    contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
    border: OutlineInputBorder(
      borderRadius: Style.getCircularBorderRadius(18),
      borderSide: BorderSide(color: Style.getSubtleColor()),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: Style.getCircularBorderRadius(18),
      borderSide: BorderSide(color: Style.getSubtleColor()),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: Style.getCircularBorderRadius(18),
      borderSide: BorderSide(color: Style.getPrimaryColor(), width: 1.5),
    ),
  );

  Widget _sectionLabel(String label) => Padding(
    padding: EdgeInsets.only(top: 18.h, bottom: 8.h),
    child: Text(
      label,
      style: Style.getHeaderThree(
        color: Style.getObscureTextColor(),
        fontSize: 10,
        fontWeight: FontWeight.w600,
      ),
    ),
  );

  Widget _choiceChip({
    required String label,
    required bool selected,
    required String semanticLabel,
    required ValueChanged<bool> onSelected,
  }) {
    return Semantics(
      button: true,
      selected: selected,
      label: '$semanticLabel, ${selected ? 'seleccionado' : 'no seleccionado'}',
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: onSelected,
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
        materialTapTargetSize: MaterialTapTargetSize.padded,
        selectedColor: Style.getPrimaryColor(),
        backgroundColor: Style.getCardColor(),
        side: BorderSide(
          color: selected ? Style.getPrimaryColor() : Style.getSubtleColor(),
        ),
        shape: const StadiumBorder(),
        labelStyle: Style.getHeaderThree(
          color: selected ? Style.white : Style.getTextColor(),
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildDirectionPicker() => DropdownButtonFormField<String>(
    key: const ValueKey('direccion-picker'),
    initialValue: educationCatalog.containsKey(_draft.direccion)
        ? _draft.direccion
        : null,
    isExpanded: true,
    decoration: _dropdownDecoration('Selecciona una dirección'),
    items: educationCatalog.keys
        .map(
          (direction) => DropdownMenuItem(
            value: direction,
            child: Text(
              direction,
              overflow: TextOverflow.ellipsis,
              style: Style.getTextStyle(
                color: Style.getTextColor(),
                fontSize: 10,
              ),
            ),
          ),
        )
        .toList(),
    onChanged: (direction) => _updateDraft(
      _draft.copyWith(
        direccion: direction,
        clearDireccion: direction == null,
        carreras: const [],
      ),
    ),
  );

  Widget _buildCareerPicker() {
    final selectedCareers = _draft.carreras
        .where(_availableCareers.contains)
        .toList();
    final selectedSummary = switch (selectedCareers.length) {
      0 => '',
      1 => selectedCareers.single,
      _ => '${selectedCareers.length} carreras seleccionadas',
    };

    return Semantics(
      button: true,
      label: selectedCareers.isEmpty
          ? 'Seleccionar carreras que aceptan'
          : 'Carreras seleccionadas: ${selectedCareers.join(', ')}',
      child: InkWell(
        key: const ValueKey('carreras-picker'),
        borderRadius: Style.getCircularBorderRadius(18),
        onTap: _openCareerPicker,
        child: InputDecorator(
          isEmpty: selectedCareers.isEmpty,
          decoration: _dropdownDecoration('Selecciona una o varias carreras')
              .copyWith(
                suffixIcon: Icon(
                  Icons.arrow_drop_down_rounded,
                  color: Style.getObscureTextColor(),
                ),
              ),
          child: Text(
            selectedSummary,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Style.getTextStyle(
              color: Style.getTextColor(),
              fontSize: 10,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openCareerPicker() async {
    final selectedCareers = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (context) => _CareerMultiSelectSheet(
        options: _availableCareers,
        selected: _draft.carreras,
      ),
    );
    if (selectedCareers == null || !mounted) return;
    _updateDraft(_draft.copyWith(carreras: selectedCareers));
  }

  Widget _buildLocationSelectors() {
    final options = _options;
    final states = options?.estados ?? const <String>[];
    final municipalities = options?.municipiosDe(_draft.estado) ?? const [];
    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<String>(
            key: ValueKey('estado-${_draft.estado}'),
            initialValue: states.contains(_draft.estado) ? _draft.estado : null,
            isExpanded: true,
            decoration: _dropdownDecoration('Estado'),
            items: states
                .map(
                  (state) => DropdownMenuItem(
                    value: state,
                    child: Text(
                      state,
                      overflow: TextOverflow.ellipsis,
                      style: Style.getTextStyle(
                        color: Style.getTextColor(),
                        fontSize: 10,
                      ),
                    ),
                  ),
                )
                .toList(),
            onChanged: _isLoadingOptions
                ? null
                : (state) => _updateDraft(
                    _draft.copyWith(
                      estado: state,
                      clearEstado: state == null,
                      clearMunicipio: true,
                    ),
                  ),
          ),
        ),
        SizedBox(width: 8.w),
        Expanded(
          child: DropdownButtonFormField<String>(
            key: ValueKey('municipio-${_draft.estado}'),
            initialValue: municipalities.contains(_draft.municipio)
                ? _draft.municipio
                : null,
            isExpanded: true,
            decoration: _dropdownDecoration('Municipio'),
            items: municipalities
                .map(
                  (municipality) => DropdownMenuItem(
                    value: municipality,
                    child: Text(
                      municipality,
                      overflow: TextOverflow.ellipsis,
                      style: Style.getTextStyle(
                        color: Style.getTextColor(),
                        fontSize: 10,
                      ),
                    ),
                  ),
                )
                .toList(),
            onChanged: _draft.estado == null || _isLoadingOptions
                ? null
                : (municipality) => _updateDraft(
                    _draft.copyWith(
                      municipio: municipality,
                      clearMunicipio: municipality == null,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildRatingChips() => Wrap(
    spacing: 8.w,
    runSpacing: 4.h,
    children: [
      for (final rating in _ratings)
        _choiceChip(
          label: rating.label,
          semanticLabel: 'Calificación mínima ${rating.label}',
          selected: _draft.calificacionMin == rating.value,
          onSelected: (_) => _updateDraft(
            _draft.copyWith(
              calificacionMin: rating.value,
              clearCalificacionMin: rating.value == null,
            ),
          ),
        ),
    ],
  );

  void _apply() {
    if (_matchingCount == 0 || _isLoadingCount || _countError != null) return;
    Navigator.of(context).pop(_draft);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final buttonLabel = _isLoadingCount
        ? 'Calculando...'
        : _countError != null
        ? 'No se pudo contar'
        : _matchingCount == 0
        ? 'Sin resultados'
        : 'Ver $_matchingCount empresas';

    return SafeArea(
      top: false,
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * .86,
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 10.h),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Filtros',
                      style: Style.getHeaderTwo(
                        color: colors.onSurface,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _clearAll,
                    child: Text(
                      'Limpiar todo',
                      style: Style.getHeaderThree(
                        color: colors.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionLabel('Dirección académica'),
                    _buildDirectionPicker(),
                    _sectionLabel('Carrera que aceptan'),
                    _buildCareerPicker(),
                    _sectionLabel('Ubicación'),
                    _buildLocationSelectors(),
                    if (_optionsError != null) ...[
                      SizedBox(height: 8.h),
                      Text(
                        'No se pudieron cargar las ubicaciones.',
                        style: Style.getTextStyle(
                          color: Style.getErrorColor(),
                          fontSize: 10,
                        ),
                      ),
                      TextButton(
                        onPressed: _loadOptions,
                        child: const Text('Reintentar'),
                      ),
                    ],
                    _sectionLabel('Calificación mínima'),
                    _buildRatingChips(),
                    Material(
                      color: Style.getCardColor(),
                      borderRadius: Style.getCircularBorderRadius(18),
                      clipBehavior: Clip.antiAlias,
                      child: Semantics(
                        label: 'Solo mis favoritas',
                        value: _draft.soloFavoritas
                            ? 'Activado'
                            : 'Desactivado',
                        child: SwitchListTile(
                          title: Text(
                            'Solo mis favoritas',
                            style: Style.getHeaderThree(
                              color: Style.getTextColor(),
                              fontSize: 11,
                            ),
                          ),
                          value: _draft.soloFavoritas,
                          activeTrackColor: colors.primary,
                          onChanged: (value) => _updateDraft(
                            _draft.copyWith(soloFavoritas: value),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 20.h),
                  ],
                ),
              ),
            ),
            if (_countError != null)
              Padding(
                padding: EdgeInsets.fromLTRB(20.w, 4.h, 20.w, 8.h),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'No se pudo calcular el total de resultados.',
                        style: Style.getTextStyle(
                          color: Style.getErrorColor(),
                          fontSize: 10,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => _scheduleCount(immediate: true),
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                20.w,
                10.h,
                20.w,
                16.h + bottomInset,
              ),
              child: PrimaryButton(
                label: buttonLabel,
                onPressed:
                    _isLoadingCount ||
                        _countError != null ||
                        _matchingCount == 0
                    ? null
                    : _apply,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
