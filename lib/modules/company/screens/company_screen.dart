import 'package:material_ui/material_ui.dart';
import 'package:conecta_utsh/modules/company/models/company_model.dart';
import 'package:conecta_utsh/modules/company/screens/company_details_screen.dart';
import 'package:conecta_utsh/modules/company/services/company_service.dart';

class CompaniesScreen extends StatefulWidget {
  const CompaniesScreen({
    this.initialCompanies,
    this.companyService = const CompanyService(),
    this.onlyFeatured = false,
    this.onToggleSaved,
    super.key,
  });

  final List<CompanyModel>? initialCompanies;
  final CompanyService companyService;
  final bool onlyFeatured;
  final ValueChanged<CompanyModel>? onToggleSaved;

  @override
  State<CompaniesScreen> createState() => _CompaniesScreenState();
}

class _CompaniesScreenState extends State<CompaniesScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<CompanyModel> _allCompanies = [];
  bool _isLoading = true;
  String? _error;
  String _searchQuery = '';
  String _selectedFilter = 'Todas';

  @override
  void initState() {
    super.initState();
    if (widget.onlyFeatured) {
      _selectedFilter = 'Destacadas';
    }
    if (widget.initialCompanies != null && widget.initialCompanies!.isNotEmpty) {
      _allCompanies = List<CompanyModel>.from(widget.initialCompanies!);
      _isLoading = false;
    } else {
      _loadCompanies();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCompanies() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final result = await widget.companyService.getCompanies();
      if (!mounted) return;
      setState(() {
        _allCompanies = result;
        _isLoading = false;
      });
    } on Exception catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _handleToggleSaved(CompanyModel selected) {
    setState(() {
      _allCompanies = _allCompanies
          .map(
            (c) => c.id == selected.id ? c.copyWith(isSaved: !c.isSaved) : c,
          )
          .toList();
    });
    widget.onToggleSaved?.call(selected);
  }

  void _openCompanyDetail(CompanyModel company) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CompanyDetailScreen(
          company: company,
          onToggleSaved: (_) => _handleToggleSaved(company),
        ),
      ),
    );
  }

  List<String> get _filterOptions {
    final types = _allCompanies.map((c) => c.employmentType).toSet().toList();
    return ['Todas', 'Destacadas', 'Guardadas', ...types];
  }

  List<CompanyModel> get _filteredCompanies {
    return _allCompanies.where((company) {
      if (_selectedFilter == 'Destacadas' && !company.isFeatured) return false;
      if (_selectedFilter == 'Guardadas' && !company.isSaved) return false;
      if (_selectedFilter != 'Todas' &&
          _selectedFilter != 'Destacadas' &&
          _selectedFilter != 'Guardadas' &&
          company.employmentType != _selectedFilter) {
        return false;
      }

      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return company.name.toLowerCase().contains(q) ||
          company.position.toLowerCase().contains(q) ||
          company.location.toLowerCase().contains(q) ||
          company.tags.any((tag) => tag.toLowerCase().contains(q));
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final filtered = _filteredCompanies;

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        backgroundColor: colors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        titleSpacing: 0,
        title: Text(
          widget.onlyFeatured ? 'Empresas destacadas' : 'Catálogo de empresas',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchQuery = value.trim()),
              decoration: InputDecoration(
                hintText: 'Buscar por empresa, puesto o tecnología...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: colors.surfaceContainerLowest,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: colors.outlineVariant),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: colors.outlineVariant.withValues(alpha: 0.6),
                  ),
                ),
              ),
            ),
          ),
          if (!_isLoading && _error == null && _allCompanies.isNotEmpty)
            SizedBox(
              height: 38,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _filterOptions.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final filter = _filterOptions[index];
                  final isSelected = _selectedFilter == filter;
                  return ChoiceChip(
                    label: Text(filter),
                    selected: isSelected,
                    selectedColor: colors.primary,
                    labelStyle: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      color: isSelected ? colors.onPrimary : colors.onSurface,
                    ),
                    backgroundColor: colors.surfaceContainerLowest,
                    side: BorderSide(
                      color: isSelected
                          ? colors.primary
                          : colors.outlineVariant.withValues(alpha: 0.5),
                    ),
                    onSelected: (_) => setState(() => _selectedFilter = filter),
                  );
                },
              ),
            ),
          const SizedBox(height: 12),
          Expanded(
            child: _buildBody(theme, colors, filtered),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(
    ThemeData theme,
    ColorScheme colors,
    List<CompanyModel> filtered,
  ) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

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

    if (filtered.isEmpty) {
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
                'No se encontraron vacantes con esos criterios.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      itemCount: filtered.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final company = filtered[index];
        return _CompanyListTileCard(
          company: company,
          onTap: () => _openCompanyDetail(company),
          onToggleSaved: () => _handleToggleSaved(company),
        );
      },
    );
  }
}

class _CompanyListTileCard extends StatelessWidget {
  const _CompanyListTileCard({
    required this.company,
    required this.onTap,
    required this.onToggleSaved,
  });

  final CompanyModel company;
  final VoidCallback onTap;
  final VoidCallback onToggleSaved;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: colors.surfaceContainerLowest,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: company.isFeatured
              ? colors.primary.withValues(alpha: 0.45)
              : colors.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Fila superior: Avatar/Logo + Nombre y Puesto + Botón Guardar
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: colors.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      company.name.isNotEmpty
                          ? company.name.substring(0, 1).toUpperCase()
                          : 'E',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colors.onPrimaryContainer,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                company.position,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (company.isFeatured) ...[
                              const SizedBox(width: 6),
                              Icon(
                                Icons.verified_rounded,
                                size: 16,
                                color: colors.primary,
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${company.name} • ${company.location}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed: onToggleSaved,
                    icon: Icon(
                      company.isSaved
                          ? Icons.bookmark_rounded
                          : Icons.bookmark_border_rounded,
                      color: company.isSaved
                          ? colors.primary
                          : colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Etiquetas (EmploymentType, Level y Tags)
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _InfoBadge(
                    label: company.employmentType,
                    bgColor: colors.secondaryContainer,
                    textColor: colors.onSecondaryContainer,
                  ),
                  _InfoBadge(
                    label: company.level,
                    bgColor: colors.surfaceContainerHigh,
                    textColor: colors.onSurface,
                  ),
                  ...company.tags.map(
                    (tag) => _InfoBadge(
                      label: tag,
                      bgColor: colors.surfaceContainerLow,
                      textColor: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const Divider(height: 20),

              // Fila inferior: Salario y Ver detalles
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${company.currency} \$${company.salary} / ${company.period}',
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colors.primary,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Ver detalles',
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colors.primary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 12,
                        color: colors.primary,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoBadge extends StatelessWidget {
  const _InfoBadge({
    required this.label,
    required this.bgColor,
    required this.textColor,
  });

  final String label;
  final Color bgColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
      ),
    );
  }
}