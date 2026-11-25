import 'package:material_ui/material_ui.dart';
import 'package:resize/resize.dart';
import 'package:conecta_utsh/helpers/style.dart';
import 'package:conecta_utsh/modules/app/components/primary_button.dart';
import 'package:conecta_utsh/modules/app/models/education_catalog.dart';
import 'package:conecta_utsh/modules/company/models/company_filters.dart';

class CompanyFiltersSheet extends StatefulWidget {
  const CompanyFiltersSheet({
    required this.initialFilters,
    required this.options,
    super.key,
  });

  final CompanyFilters initialFilters;
  final CompanyFilterOptions options;

  @override
  State<CompanyFiltersSheet> createState() => _CompanyFiltersSheetState();
}

class _CompanyFiltersSheetState extends State<CompanyFiltersSheet> {
  late CompanyFilters _draft;

  @override
  void initState() {
    super.initState();
    _draft = widget.initialFilters;
  }

  List<String> get _availableCareers {
    final direction = _draft.direccionAcademica;
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

  Widget _buildDirectionPicker() => DropdownButtonFormField<String>(
    key: const ValueKey('direccion-picker'),
    initialValue: educationCatalog.containsKey(_draft.direccionAcademica)
        ? _draft.direccionAcademica
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
    onChanged: (direction) => setState(() {
      _draft = _draft.copyWith(
        direccionAcademica: direction,
        clearDireccionAcademica: direction == null,
        clearCarrera: true,
      );
    }),
  );

  Widget _buildCareerPicker() {
    final careers = _availableCareers;
    return DropdownButtonFormField<String>(
      key: ValueKey('carrera-${_draft.direccionAcademica}'),
      initialValue: careers.contains(_draft.carrera) ? _draft.carrera : null,
      isExpanded: true,
      decoration: _dropdownDecoration('Selecciona una carrera'),
      items: careers
          .map(
            (career) => DropdownMenuItem(
              value: career,
              child: Text(
                career,
                overflow: TextOverflow.ellipsis,
                style: Style.getTextStyle(
                  color: Style.getTextColor(),
                  fontSize: 10,
                ),
              ),
            ),
          )
          .toList(),
      onChanged: (career) => setState(() {
        _draft = _draft.copyWith(
          carrera: career,
          clearCarrera: career == null,
        );
      }),
    );
  }

  Widget _buildLocationSelectors() {
    final states = widget.options.estados;
    final municipalities = widget.options.municipiosDe(_draft.estado);
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
            onChanged: (state) => setState(() {
              _draft = _draft.copyWith(
                estado: state,
                clearEstado: state == null,
                clearMunicipio: true,
              );
            }),
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
            onChanged: _draft.estado == null
                ? null
                : (municipality) => setState(() {
                    _draft = _draft.copyWith(
                      municipio: municipality,
                      clearMunicipio: municipality == null,
                    );
                  }),
          ),
        ),
      ],
    );
  }

  void _apply() => Navigator.of(context).pop(_draft);

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
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
                    onPressed: () =>
                        setState(() => _draft = const CompanyFilters()),
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
                    SizedBox(height: 18.h),
                    Material(
                      color: Style.getCardColor(),
                      borderRadius: Style.getCircularBorderRadius(18),
                      clipBehavior: Clip.antiAlias,
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
                        onChanged: (value) => setState(
                          () => _draft = _draft.copyWith(soloFavoritas: value),
                        ),
                      ),
                    ),
                    SizedBox(height: 20.h),
                  ],
                ),
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
                label: 'Ver resultados',
                onPressed: _apply,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
