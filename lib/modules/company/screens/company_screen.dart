import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:conecta_utsh/helpers/style.dart';
import 'package:conecta_utsh/modules/company/components/company_cards.dart';
import 'package:conecta_utsh/modules/company/components/company_filters_sheet.dart';
import 'package:conecta_utsh/modules/company/components/company_search_filters.dart';
import 'package:conecta_utsh/modules/company/models/company_filters.dart';
import 'package:conecta_utsh/modules/company/models/company_model.dart';
import 'package:conecta_utsh/modules/company/providers/company_controller.dart';
import 'package:conecta_utsh/modules/company/screens/company_details_screen.dart';

class CompaniesScreen extends StatefulWidget {
  const CompaniesScreen({this.initialQuery = '', super.key});

  final String initialQuery;

  @override
  State<CompaniesScreen> createState() => _CompaniesScreenState();
}

class _CompaniesScreenState extends State<CompaniesScreen> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialQuery);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openFilters(CompanyController controller) async {
    final selectedFilters = await showModalBottomSheet<CompanyFilters>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      barrierColor: Theme.of(context).colorScheme.scrim.withValues(alpha: .5),
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Style.getCircularBorderRadius(24).topLeft,
        ),
      ),
      builder: (context) => CompanyFiltersSheet(
        initialFilters: controller.filters,
        options: controller.filterOptions,
      ),
    );
    if (selectedFilters != null) controller.setFilters(selectedFilters);
  }

  void _openCompanyDetail(CompanyModel company) {
    FocusManager.instance.primaryFocus?.unfocus();
    Navigator.of(context)
        .push(
          MaterialPageRoute<void>(
            builder: (_) => CompanyDetailScreen(company: company),
          ),
        )
        .then((_) {
          if (mounted) FocusScope.of(context).unfocus();
        });
  }

  void _removeFilter(CompanyController controller, String filterKey) {
    final filters = controller.filters;
    switch (filterKey) {
      case 'direccion':
        controller.setFilters(filters.copyWith(clearDireccionAcademica: true));
        break;
      case 'carrera':
        controller.setFilters(filters.copyWith(clearCarrera: true));
        break;
      case 'estado':
        controller.setFilters(
          filters.copyWith(clearEstado: true, clearMunicipio: true),
        );
        break;
      case 'municipio':
        controller.setFilters(filters.copyWith(clearMunicipio: true));
        break;
      case 'favoritas':
        controller.setFilters(filters.copyWith(soloFavoritas: false));
        break;
    }
  }

  List<({String key, String label})> _appliedFilters(
    CompanyFilters filters,
  ) => [
    if (filters.direccionAcademica != null)
      (key: 'direccion', label: filters.direccionAcademica!),
    if (filters.carrera != null) (key: 'carrera', label: filters.carrera!),
    if (filters.estado != null) (key: 'estado', label: filters.estado!),
    if (filters.municipio != null)
      (key: 'municipio', label: filters.municipio!),
    if (filters.soloFavoritas) (key: 'favoritas', label: 'Solo mis favoritas'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final controller = context.watch<CompanyController>();
    final appliedFilters = _appliedFilters(controller.filters);

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        backgroundColor: colors.surface,
        elevation: 0,
        leading: IconButton(
          tooltip: 'Regresar',
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        titleSpacing: 0,
        title: Text(
          'Directorio de empresas',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: CompanySearchFilters(
              controller: _searchController,
              hintText: 'Buscar empresa por nombre',
              filtersActive: controller.filters.hasActiveFilters,
              onSearch: controller.setQuery,
              onFilterPressed: () => _openFilters(controller),
            ),
          ),
          if (appliedFilters.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Wrap(
                  spacing: 6,
                  runSpacing: 2,
                  children: [
                    for (final filter in appliedFilters)
                      _AppliedFilterChip(
                        label: filter.label,
                        onDeleted: () => _removeFilter(controller, filter.key),
                      ),
                  ],
                ),
              ),
            ),
          if (!controller.isLoading && controller.error == null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${controller.total} empresas',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: controller.refresh,
              child: _buildBody(controller, theme, colors),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(
    CompanyController controller,
    ThemeData theme,
    ColorScheme colors,
  ) {
    if (controller.isLoading) return _buildSkeleton(colors);

    if (controller.error != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 80),
          Icon(Icons.error_outline_rounded, size: 40, color: colors.error),
          const SizedBox(height: 8),
          Text(
            'No se pudieron cargar las empresas.',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleSmall,
          ),
          const SizedBox(height: 4),
          Text(
            controller.error!,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: FilledButton.tonal(
              onPressed: controller.refresh,
              child: const Text('Reintentar'),
            ),
          ),
        ],
      );
    }

    if (controller.companies.isEmpty) {
      final hasCriteria =
          controller.filters.hasActiveFilters || controller.query.isNotEmpty;
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 80),
          Icon(
            Icons.business_center_outlined,
            size: 44,
            color: colors.onSurfaceVariant,
          ),
          const SizedBox(height: 10),
          Text(
            'No encontramos empresas',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          if (hasCriteria) ...[
            const SizedBox(height: 12),
            Center(
              child: FilledButton(
                onPressed: () {
                  _searchController.clear();
                  controller.setQuery('');
                  controller.setFilters(const CompanyFilters());
                },
                child: const Text('Limpiar filtros'),
              ),
            ),
          ],
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      itemCount: controller.companies.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final company = controller.companies[index];
        return CompanyListCard(
          key: ValueKey(company.id),
          company: company,
          onTap: () => _openCompanyDetail(company),
        );
      },
    );
  }

  Widget _buildSkeleton(ColorScheme colors) => Shimmer.fromColors(
    baseColor: colors.surfaceContainerHighest,
    highlightColor: colors.surface,
    child: ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      itemCount: 4,
      itemBuilder: (context, index) => Container(
        height: 188,
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: colors.surfaceContainerHighest,
          borderRadius: Style.getCircularBorderRadius(20),
        ),
      ),
    ),
  );
}

class _AppliedFilterChip extends StatelessWidget {
  const _AppliedFilterChip({required this.label, required this.onDeleted});

  final String label;
  final VoidCallback onDeleted;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: 'Filtro aplicado: $label. Toca para quitarlo.',
      child: InputChip(
        label: Text(label),
        onDeleted: onDeleted,
        deleteButtonTooltipMessage: 'Quitar filtro $label',
        deleteIcon: const Icon(Icons.close_rounded, size: 16),
        materialTapTargetSize: MaterialTapTargetSize.padded,
        backgroundColor: colors.surfaceContainerLow,
        labelStyle: Theme.of(context).textTheme.labelSmall
            ?.copyWith(color: colors.onSurfaceVariant),
        side: BorderSide(color: colors.outlineVariant),
        shape: const StadiumBorder(),
      ),
    );
  }
}
