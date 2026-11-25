import 'package:material_ui/material_ui.dart';
import 'package:conecta_utsh/helpers/style.dart';
import 'package:conecta_utsh/modules/company/models/company_model.dart';
import 'package:conecta_utsh/modules/favoritos/components/favorito_button.dart';

class FeaturedCompanyCard extends StatelessWidget {
  const FeaturedCompanyCard({
    required this.company,
    required this.onTap,
    super.key,
  });

  final CompanyModel company;
  final VoidCallback onTap;

  String get _name => _companyName(company);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final areas = company.availableAreas.toSet().take(3);

    return Material(
      color: colors.primary,
      borderRadius: Style.getCircularBorderRadius(22),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          children: [
            Positioned(
              top: 8,
              right: -9,
              child: _FeaturedDecorationIcon(
                icon: Icons.business_outlined,
                size: 82,
                angle: -0.18,
                color: colors.onPrimary.withValues(alpha: .09),
              ),
            ),
            Positioned(
              top: 66,
              right: 51,
              child: _FeaturedDecorationIcon(
                icon: Icons.handshake_outlined,
                size: 55,
                angle: 0.2,
                color: colors.onPrimary.withValues(alpha: .09),
              ),
            ),
            Positioned(
              bottom: 8,
              right: 7,
              child: _FeaturedDecorationIcon(
                icon: Icons.school_outlined,
                size: 66,
                angle: 0.16,
                color: colors.onPrimary.withValues(alpha: .09),
              ),
            ),
            Positioned(
              top: 18,
              right: 104,
              child: _FeaturedDecorationIcon(
                icon: Icons.assignment_turned_in_outlined,
                size: 46,
                angle: -0.22,
                color: colors.onPrimary.withValues(alpha: .09),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _Initial(company: company, size: 36, featured: true),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: colors.onPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              _optionalText(company.sector) ??
                                  'Sector no especificado',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: colors.onPrimary.withValues(alpha: .78),
                              ),
                            ),
                          ],
                        ),
                      ),
                      FavoritoButton(
                        company: company,
                        inactiveColor: colors.onPrimary,
                      ),
                    ],
                  ),
                  if (areas.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 5,
                      runSpacing: 4,
                      children: areas
                          .map((area) => _FeaturedAreaChip(label: area))
                          .toList(),
                    ),
                  ],
                  const Spacer(),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 15,
                        color: colors.onPrimary,
                      ),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          _companyLocation(company).isEmpty
                              ? 'Ubicación no especificada'
                              : _companyLocation(company),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colors.onPrimary,
                          ),
                        ),
                      ),
                    ],
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

class CompanyCard extends StatelessWidget {
  const CompanyCard({
    required this.company,
    this.onTap,
    this.showCareerSummary = false,
    super.key,
  });

  final CompanyModel company;
  final VoidCallback? onTap;
  final bool showCareerSummary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final area = company.availableAreas.isEmpty
        ? null
        : company.availableAreas.first;
    final careers = company.acceptedCareers;
    final careerSummary = careers.isEmpty
        ? 'Acepta todas las carreras'
        : [
            careers.first,
            if (careers.length > 1) '+${careers.length - 1}',
          ].join(' ');

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: colors.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: Style.getCircularBorderRadius(18),
        side: BorderSide(color: colors.primary.withValues(alpha: .28)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          children: [
            Positioned(
              top: 0,
              right: -8,
              child: _FeaturedDecorationIcon(
                icon: Icons.business_outlined,
                size: 62,
                angle: -0.18,
                color: colors.primary.withValues(alpha: .07),
              ),
            ),
            Positioned(
              bottom: 18,
              right: 12,
              child: _FeaturedDecorationIcon(
                icon: Icons.badge_outlined,
                size: 48,
                angle: 0.2,
                color: colors.primary.withValues(alpha: .06),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _Initial(company: company, size: 40),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _companyName(company),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: colors.onSurface,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              _optionalText(company.sector) ??
                                  'Sector no especificado',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      FavoritoButton(company: company),
                    ],
                  ),
                  const Spacer(),
                  if (area != null && area.trim().isNotEmpty) ...[
                    _AreaChip(label: area),
                    const SizedBox(height: 8),
                  ],
                  if (showCareerSummary) ...[
                    Row(
                      children: [
                        Icon(
                          careers.isEmpty
                              ? Icons.check_circle_outline_rounded
                              : Icons.school_outlined,
                          color: colors.primary,
                          size: 15,
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            careerSummary,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                  ],
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 14,
                        color: colors.onSurfaceVariant,
                      ),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          _companyLocation(company).isEmpty
                              ? 'Ubicación no especificada'
                              : _companyLocation(company),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
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

class CompanyListCard extends StatelessWidget {
  const CompanyListCard({
    required this.company,
    required this.onTap,
    super.key,
  });

  final CompanyModel company;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final accent = Theme.of(context).brightness == Brightness.dark
        ? Style.successDark
        : colors.primary;
    final areas = company.availableAreas.toSet().toList();
    final careers = company.acceptedCareers;
    final careerSummary = careers.isEmpty
        ? 'Acepta todas las carreras'
        : [
            careers.first,
            if (careers.length > 1) '+${careers.length - 1}',
          ].join(' ');

    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: [
        _companyName(company),
        _optionalText(company.sector),
        _companyLocation(company),
      ].whereType<String>().join(', '),
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
                    _Initial(company: company, size: 48),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _companyName(company),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: colors.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            [
                              _optionalText(company.sector),
                              _companyLocation(company),
                            ].whereType<String>().join(' · '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    FavoritoButton(company: company),
                  ],
                ),
                if (areas.isNotEmpty) ...[
                  const SizedBox(height: 12),
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
                    Icon(
                      careers.isEmpty
                          ? Icons.check_circle_outline_rounded
                          : Icons.school_outlined,
                      color: accent,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        careerSummary,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: accent,
                        ),
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
                            color: accent,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 12,
                          color: accent,
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

class _Initial extends StatelessWidget {
  const _Initial({
    required this.company,
    required this.size,
    this.featured = false,
  });

  final CompanyModel company;
  final double size;
  final bool featured;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final initial = _companyName(company).substring(0, 1).toUpperCase();
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: featured ? colors.onPrimary : colors.primaryContainer,
        borderRadius: Style.getCircularBorderRadius(12),
      ),
      child: Text(
        initial,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: featured ? colors.primary : colors.onPrimaryContainer,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _FeaturedDecorationIcon extends StatelessWidget {
  const _FeaturedDecorationIcon({
    required this.icon,
    required this.size,
    required this.angle,
    required this.color,
  });

  final IconData icon;
  final double size;
  final double angle;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ExcludeSemantics(
        child: Transform.rotate(
          angle: angle,
          child: Icon(icon, size: size, color: color),
        ),
      ),
    );
  }
}

class _FeaturedAreaChip extends StatelessWidget {
  const _FeaturedAreaChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: colors.onPrimary.withValues(alpha: .16),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelSmall
            ?.copyWith(color: colors.onPrimary, fontWeight: FontWeight.w500),
      ),
    );
  }
}

class _AreaChip extends StatelessWidget {
  const _AreaChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: .08),
        border: Border.all(color: colors.primary.withValues(alpha: .16)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.work_outline_rounded, size: 12, color: colors.primary),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: colors.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
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

String _companyName(CompanyModel company) =>
    _optionalText(company.name) ?? 'Empresa sin nombre';

String? _optionalText(String? value) {
  final trimmed = value?.trim();
  return trimmed == null || trimmed.isEmpty ? null : trimmed;
}

String _companyLocation(CompanyModel company) => [
  _optionalText(company.location.municipality),
  _optionalText(company.location.state),
].whereType<String>().join(', ');
