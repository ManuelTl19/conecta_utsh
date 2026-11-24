import 'package:material_ui/material_ui.dart';
import 'package:conecta_utsh/helpers/style.dart';
import 'package:conecta_utsh/modules/app/models/education_catalog.dart';
import 'package:conecta_utsh/modules/company/models/company_filters.dart';
import 'package:conecta_utsh/modules/company/models/company_model.dart';

class CompanySearchFilters extends StatelessWidget {
  const CompanySearchFilters({
    required this.controller,
    required this.onSearch,
    required this.onFilterPressed,
    this.filtersActive = false,
    this.hintText = 'Buscar empresas',
    super.key,
  });

  final TextEditingController controller;
  final ValueChanged<String> onSearch;
  final VoidCallback onFilterPressed;
  final bool filtersActive;
  final String hintText;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: CompanySearchField(
            controller: controller,
            hintText: hintText,
            onChanged: onSearch,
          ),
        ),
        const SizedBox(width: 10),
        CompanyFilterButton(
          filtersActive: filtersActive,
          onPressed: onFilterPressed,
        ),
      ],
    );
  }
}

class CompanySearchField extends StatelessWidget {
  const CompanySearchField({
    required this.controller,
    required this.onChanged,
    this.hintText = 'Buscar empresas',
    super.key,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String hintText;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(13),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: Theme.of(context).textTheme.bodyMedium
            ?.copyWith(color: colors.onSurface),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: Theme.of(context).textTheme.labelMedium
              ?.copyWith(color: colors.onSurfaceVariant),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: colors.onSurfaceVariant,
            size: 20,
          ),
          suffixIcon: controller.text.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Limpiar búsqueda',
                  onPressed: () {
                    controller.clear();
                    onChanged('');
                  },
                  icon: const Icon(Icons.close_rounded, size: 18),
                ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 13),
        ),
      ),
    );
  }
}

class CompanyFilterButton extends StatelessWidget {
  const CompanyFilterButton({
    required this.filtersActive,
    required this.onPressed,
    super.key,
  });

  final bool filtersActive;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final accentGreen = Theme.of(context).brightness == Brightness.dark
        ? Style.successDark
        : colors.primary;
    return SizedBox(
      width: 44,
      height: 44,
      child: Material(
        color: colors.surfaceContainerLow,
        shape: const CircleBorder(),
        child: Semantics(
          button: true,
          label: filtersActive ? 'Filtros, hay filtros activos' : 'Filtros',
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                tooltip: filtersActive ? 'Filtros activos' : 'Filtros',
                constraints: const BoxConstraints.tightFor(
                  width: 44,
                  height: 44,
                ),
                padding: EdgeInsets.zero,
                onPressed: onPressed,
                icon: Icon(Icons.tune_rounded, color: accentGreen, size: 20),
              ),
              if (filtersActive)
                Positioned(
                  top: 3,
                  right: 3,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: accentGreen,
                      shape: BoxShape.circle,
                      border: Border.all(color: colors.surface, width: 2),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<String?> showCompanyCategoryFilterSheet(
  BuildContext context, {
  required List<String> options,
  required String selectedFilter,
}) {
  final colors = Theme.of(context).colorScheme;
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: colors.surface,
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filtrar empresas',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: colors.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * .55,
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final option = options[index];
                  final isSelected = option == selectedFilter;
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(option),
                    selected: isSelected,
                    selectedColor: colors.primary,
                    trailing: isSelected
                        ? Icon(
                            Icons.check_circle_rounded,
                            color: colors.primary,
                          )
                        : null,
                    onTap: () => Navigator.of(context).pop(option),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

List<String> companyFilterOptions(List<CompanyModel> companies) {
  final sectors =
      companies
          .map((company) => company.sector)
          .where((sector) => sector.isNotEmpty && sector != 'Todas')
          .toSet()
          .toList()
        ..sort();
  return ['Todas', 'Favoritas', ...sectors];
}

List<CompanyModel> filterCompanies(
  List<CompanyModel> companies, {
  required String searchQuery,
  required String selectedFilter,
  CompanyFilters filters = const CompanyFilters(),
}) {
  final query = _normalizeCompanyText(searchQuery.trim());
  final careers = filters.carreras.isNotEmpty
      ? filters.carreras.toSet()
      : filters.direccion == null
      ? <String>{}
      : (educationCatalog[filters.direccion] ?? const <String>[]).toSet();
  return companies.where((company) {
    if (!company.active) return false;
    if (selectedFilter == 'Favoritas' && !company.isFavorite) return false;
    if (selectedFilter != 'Todas' &&
        selectedFilter != 'Favoritas' &&
        company.sector != selectedFilter) {
      return false;
    }
    if (careers.isNotEmpty &&
        company.acceptedCareers.isNotEmpty &&
        !company.acceptedCareers.any(careers.contains)) {
      return false;
    }
    if (filters.estado != null && company.state != filters.estado) {
      return false;
    }
    if (filters.municipio != null &&
        company.municipality != filters.municipio) {
      return false;
    }
    if (filters.calificacionMin != null &&
        (company.totalReviews == 0 ||
            company.averageRating < filters.calificacionMin!)) {
      return false;
    }
    if (filters.soloFavoritas && !company.isFavorite) return false;

    if (query.isEmpty) return true;
    final searchableText = [
      company.name,
      company.sector,
      company.municipality,
      company.state,
      ...company.availableAreas,
    ].join(' ');
    return _normalizeCompanyText(searchableText).contains(query);
  }).toList();
}

String _normalizeCompanyText(String value) {
  const accents = {
    'á': 'a',
    'é': 'e',
    'í': 'i',
    'ó': 'o',
    'ú': 'u',
    'ü': 'u',
    'ñ': 'n',
  };
  final lowerCase = value.toLowerCase();
  return accents.entries.fold(
    lowerCase,
    (result, accent) => result.replaceAll(accent.key, accent.value),
  );
}
