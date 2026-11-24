import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:shimmer/shimmer.dart';
import 'package:conecta_utsh/helpers/style.dart';
import 'package:conecta_utsh/modules/company/components/company_filters_sheet.dart';
import 'package:conecta_utsh/modules/company/components/company_search_filters.dart';
import 'package:conecta_utsh/modules/company/models/company_filters.dart';
import 'package:conecta_utsh/modules/company/models/company_model.dart';
import 'package:conecta_utsh/modules/company/screens/company_details_screen.dart';
import 'package:conecta_utsh/modules/company/services/company_service.dart';

class CompaniesScreen extends StatefulWidget {
  const CompaniesScreen({
    this.initialCompanies,
    this.initialQuery = '',
    this.companyService = const CompanyService(),
    this.currentUserCareer = CompanyService.mockUserCareer,
    this.onToggleSaved,
    super.key,
  });

  final List<CompanyModel>? initialCompanies;
  final String initialQuery;
  final CompanyService companyService;
  final String currentUserCareer;
  final ValueChanged<CompanyModel>? onToggleSaved;

  @override
  State<CompaniesScreen> createState() => _CompaniesScreenState();
}

class _CompaniesScreenState extends State<CompaniesScreen> {
  static const _pageSize = 20;

  late final TextEditingController _searchController;
  Timer? _searchDebounce;
  List<CompanyModel> _companies = [];
  List<CompanyModel>? _sourceCompanies;
  CompanyFilters _appliedFilters = const CompanyFilters();
  int _requestGeneration = 0;
  int _page = 1;
  int _total = 0;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = false;
  String? _error;
  String _searchQuery = '';
  final Set<String> _pendingFavoriteIds = {};

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialQuery);
    _searchQuery = widget.initialQuery.trim();
    if (widget.initialCompanies != null) {
      _sourceCompanies = List<CompanyModel>.from(widget.initialCompanies!);
    }
    _loadCompanies();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _requestGeneration++;
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCompanies({bool append = false}) async {
    _searchDebounce?.cancel();
    if (append && (_isLoadingMore || !_hasMore)) return;
    final requestGeneration = ++_requestGeneration;
    final requestedPage = append ? _page + 1 : 1;
    setState(() {
      if (append) {
        _isLoadingMore = true;
      } else {
        _isLoading = true;
        _error = null;
      }
    });
    try {
      final result = await widget.companyService.searchCompanies(
        query: _searchQuery,
        filters: _appliedFilters,
        page: requestedPage,
        limit: _pageSize,
        sourceCompanies: _sourceCompanies,
      );
      if (!mounted || requestGeneration != _requestGeneration) return;
      setState(() {
        _companies = append
            ? [..._companies, ...result.companies]
            : result.companies;
        _total = result.total;
        _page = result.page;
        _hasMore = _companies.length < result.total;
        _isLoading = false;
        _isLoadingMore = false;
      });
    } on Exception catch (error) {
      if (!mounted || requestGeneration != _requestGeneration) return;
      setState(() {
        _error = error.toString();
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  void _scheduleSearch(String value) {
    _searchQuery = value;
    _searchDebounce?.cancel();
    _requestGeneration++;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    _searchDebounce = Timer(
      const Duration(milliseconds: 400),
      () => _loadCompanies(),
    );
  }

  Future<void> _openFilters() async {
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
        initialFilters: _appliedFilters,
        query: _searchQuery,
        companyService: widget.companyService,
        sourceCompanies: _sourceCompanies,
      ),
    );
    if (selectedFilters == null || !mounted) return;
    setState(() => _appliedFilters = selectedFilters);
    _loadCompanies();
  }

  Future<void> _updateFavorite(String companyId, bool isFavorite) async {
    if (_pendingFavoriteIds.contains(companyId)) return;
    final matchingCompanies = _companies.where(
      (company) => company.id == companyId,
    );
    final previous = matchingCompanies.isEmpty ? null : matchingCompanies.first;
    if (previous == null) return;
    final updated = previous.copyWith(isFavorite: isFavorite);
    setState(() {
      _pendingFavoriteIds.add(companyId);
      _companies = _companies
          .map((company) => company.id == companyId ? updated : company)
          .toList();
      if (_sourceCompanies != null) {
        _sourceCompanies = _sourceCompanies!
            .map((company) => company.id == companyId ? updated : company)
            .toList();
      }
    });

    try {
      await widget.companyService.updateMockFavorite(companyId, isFavorite);
      widget.onToggleSaved?.call(updated);
      if (mounted) {
        setState(() => _pendingFavoriteIds.remove(companyId));
        _loadCompanies();
      }
    } on Exception {
      if (!mounted) return;
      setState(() {
        _pendingFavoriteIds.remove(companyId);
        _companies = _companies
            .map((company) => company.id == companyId ? previous : company)
            .toList();
        if (_sourceCompanies != null) {
          _sourceCompanies = _sourceCompanies!
              .map((company) => company.id == companyId ? previous : company)
              .toList();
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo actualizar la empresa favorita.'),
        ),
      );
    }
  }

  void _openCompanyDetail(CompanyModel company) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CompanyDetailScreen(
          company: company,
          onToggleSaved: (updated) =>
              unawaited(_updateFavorite(updated.id, updated.isFavorite)),
        ),
      ),
    );
  }

  void _removeFilter(String filterKey) {
    final filters = _appliedFilters;
    switch (filterKey) {
      case 'direccion':
        _appliedFilters = filters.copyWith(clearDireccion: true);
        break;
      case 'estado':
        _appliedFilters = filters.copyWith(
          clearEstado: true,
          clearMunicipio: true,
        );
        break;
      case 'municipio':
        _appliedFilters = filters.copyWith(clearMunicipio: true);
        break;
      case 'calificacion':
        _appliedFilters = filters.copyWith(clearCalificacionMin: true);
        break;
      case 'favoritas':
        _appliedFilters = filters.copyWith(soloFavoritas: false);
        break;
      default:
        if (filterKey.startsWith('carrera:')) {
          final career = filterKey.substring('carrera:'.length);
          _appliedFilters = filters.copyWith(
            carreras: filters.carreras.where((item) => item != career).toList(),
          );
        }
    }
    setState(() {});
    _loadCompanies();
  }

  List<({String key, String label})> get _appliedFilterItems {
    final filters = _appliedFilters;
    return [
      if (filters.direccion != null)
        (key: 'direccion', label: filters.direccion!),
      for (final career in filters.carreras)
        (key: 'carrera:$career', label: career),
      if (filters.estado != null) (key: 'estado', label: filters.estado!),
      if (filters.municipio != null)
        (key: 'municipio', label: filters.municipio!),
      if (filters.calificacionMin != null)
        (key: 'calificacion', label: '${filters.calificacionMin}+'),
      if (filters.soloFavoritas)
        (key: 'favoritas', label: 'Solo mis favoritas'),
    ];
  }

  void _clearFilters() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
      _appliedFilters = const CompanyFilters();
    });
    _loadCompanies();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

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
              hintText: 'Buscar empresa, sector o área',
              filtersActive: _appliedFilters.hasActiveFilters,
              onSearch: _scheduleSearch,
              onFilterPressed: _openFilters,
            ),
          ),
          if (_appliedFilterItems.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Wrap(
                  spacing: 6,
                  runSpacing: 2,
                  children: [
                    for (final filter in _appliedFilterItems)
                      _AppliedFilterChip(
                        label: filter.label,
                        onDeleted: () => _removeFilter(filter.key),
                      ),
                  ],
                ),
              ),
            ),
          if (!_isLoading && _error == null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '$_total empresas',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          Expanded(child: _buildBody(theme, colors)),
        ],
      ),
    );
  }

  Widget _buildBody(ThemeData theme, ColorScheme colors) {
    if (_isLoading) return _buildSkeleton(colors);

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded, size: 40, color: colors.error),
              const SizedBox(height: 8),
              Text(
                'No se pudieron cargar las empresas.',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              FilledButton.tonal(
                onPressed: _loadCompanies,
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    if (_companies.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
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
              if (_appliedFilters.hasActiveFilters ||
                  _searchQuery.isNotEmpty) ...[
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: _clearFilters,
                  child: const Text('Limpiar filtros'),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification.metrics.pixels >=
                notification.metrics.maxScrollExtent - 160 &&
            _hasMore &&
            !_isLoadingMore) {
          _loadCompanies(append: true);
        }
        return false;
      },
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        itemCount: _companies.length + (_isLoadingMore ? 1 : 0),
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          if (index >= _companies.length) {
            return const Center(child: CircularProgressIndicator());
          }
          final company = _companies[index];
          return _CompanyListTileCard(
            key: ValueKey(company.id),
            company: company,
            currentUserCareer: widget.currentUserCareer,
            favoritePending: _pendingFavoriteIds.contains(company.id),
            onTap: () => _openCompanyDetail(company),
            onToggleSaved: () =>
                unawaited(_updateFavorite(company.id, !company.isFavorite)),
          );
        },
      ),
    );
  }

  Widget _buildSkeleton(ColorScheme colors) => Shimmer.fromColors(
    baseColor: colors.surfaceContainerHighest,
    highlightColor: colors.surface,
    child: ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      itemCount: 4,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) => Container(
        height: 188,
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

class _CompanyListTileCard extends StatelessWidget {
  const _CompanyListTileCard({
    required this.company,
    required this.currentUserCareer,
    required this.favoritePending,
    required this.onTap,
    required this.onToggleSaved,
    super.key,
  });

  final CompanyModel company;
  final String currentUserCareer;
  final bool favoritePending;
  final VoidCallback onTap;
  final VoidCallback onToggleSaved;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final accentGreen = Theme.of(context).brightness == Brightness.dark
        ? Style.successDark
        : colors.primary;
    final areas = company.availableAreas.toSet().toList();
    final acceptsCareer =
        company.acceptedCareers.isEmpty ||
        company.acceptedCareers.contains(currentUserCareer);
    final compatibilityText = company.acceptedCareers.isEmpty
        ? 'Acepta todas las carreras'
        : acceptsCareer
        ? 'Acepta tu carrera'
        : [
            company.acceptedCareers.first,
            if (company.acceptedCareers.length > 1)
              '+${company.acceptedCareers.length - 1}',
          ].join(' ');
    final ratingText = company.totalReviews == 0
        ? 'Sin reseñas aún'
        : '${company.averageRating.toStringAsFixed(1)} · ${company.totalReviews} reseñas';
    final accessibilityLabel =
        '${company.name}, ${company.sector}, ${company.municipality}, '
        '${company.state}, $ratingText';

    return Semantics(
      container: true,
      label: accessibilityLabel,
      child: Card(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: colors.surfaceContainerLowest,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: Style.getCircularBorderRadius(20),
          side: BorderSide(color: colors.outlineVariant),
        ),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: colors.primaryContainer,
                        borderRadius: Style.getCircularBorderRadius(12),
                      ),
                      child: Text(
                        company.name.trim().isEmpty
                            ? 'E'
                            : company.name.trim().substring(0, 1).toUpperCase(),
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: colors.onPrimaryContainer,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            company.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: colors.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${company.sector} · ${company.municipality}, ${company.state}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: 44,
                      height: 44,
                      child: IconButton(
                        tooltip: company.isFavorite
                            ? 'Quitar de favoritas'
                            : 'Agregar a favoritas',
                        onPressed: favoritePending ? null : onToggleSaved,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints.tightFor(
                          width: 44,
                          height: 44,
                        ),
                        icon: Container(
                          width: 36,
                          height: 36,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: company.isFavorite
                                ? colors.primaryContainer
                                : colors.surfaceContainerHigh,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            company.isFavorite
                                ? Icons.bookmark_rounded
                                : Icons.bookmark_border_rounded,
                            color: company.isFavorite
                                ? accentGreen
                                : colors.onSurfaceVariant,
                            size: 19,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      company.totalReviews == 0
                          ? Icons.star_border_rounded
                          : Icons.star_rounded,
                      size: 18,
                      color: company.totalReviews == 0
                          ? colors.onSurfaceVariant
                          : accentGreen,
                    ),
                    const SizedBox(width: 5),
                    if (company.totalReviews > 0)
                      Text(
                        company.averageRating.toStringAsFixed(1),
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: colors.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    Text(
                      company.totalReviews == 0
                          ? 'Sin reseñas aún'
                          : ' · ${company.totalReviews} reseñas',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                if (areas.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      ...areas.take(3).map((area) => _InfoBadge(label: area)),
                      if (areas.length > 3)
                        _InfoBadge(label: '+${areas.length - 3}'),
                    ],
                  ),
                ],
                const Divider(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Icon(
                            acceptsCareer
                                ? Icons.check_circle_outline_rounded
                                : Icons.school_outlined,
                            color: acceptsCareer
                                ? accentGreen
                                : colors.onSurfaceVariant,
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              compatibilityText,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: acceptsCareer
                                    ? accentGreen
                                    : colors.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Ver detalles',
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: accentGreen,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 12,
                          color: accentGreen,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoBadge extends StatelessWidget {
  const _InfoBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: colors.onSurfaceVariant,
          fontWeight: FontWeight.normal,
        ),
      ),
    );
  }
}
