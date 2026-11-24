import 'package:material_ui/material_ui.dart';
import 'package:conecta_utsh/helpers/style.dart';
import 'package:conecta_utsh/modules/company/models/company_model.dart';

class FeaturedCompanyCard extends StatelessWidget {
  const FeaturedCompanyCard({
    required this.company,
    required this.onSave,
    super.key,
  });

  final CompanyModel company;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final areas = company.availableAreas.toSet().take(3);

    return Container(
      decoration: BoxDecoration(
        color: colors.primary,
        borderRadius: Style.getCircularBorderRadius(22),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _FeaturedCompanyInitial(company: company),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      company.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: colors.onPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      company.sector,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colors.onPrimary.withValues(alpha: .78),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 40,
                height: 40,
                child: IconButton(
                  tooltip: company.isFavorite
                      ? 'Quitar de favoritas'
                      : 'Agregar a favoritas',
                  onPressed: onSave,
                  padding: EdgeInsets.zero,
                  icon: Icon(
                    company.isFavorite
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_border_rounded,
                    color: colors.onPrimary,
                    size: 20,
                  ),
                ),
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
                company.totalReviews == 0
                    ? Icons.star_border_rounded
                    : Icons.star_rounded,
                size: 15,
                color: colors.onPrimary,
              ),
              const SizedBox(width: 3),
              Expanded(
                child: Text(
                  company.totalReviews == 0
                      ? 'Sin reseñas aún'
                      : '${company.averageRating.toStringAsFixed(1)} · ${company.totalReviews} reseñas',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colors.onPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  '${company.municipality}, ${company.state}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colors.onPrimary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class CompanyCard extends StatelessWidget {
  const CompanyCard({required this.company, this.onTap, super.key});

  final CompanyModel company;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: colors.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: Style.getCircularBorderRadius(18),
        side: BorderSide(color: colors.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _CompanyInitial(company: company, size: 40),
                  const Spacer(),
                  Icon(
                    company.totalReviews == 0
                        ? Icons.star_border_rounded
                        : Icons.star_rounded,
                    color: company.totalReviews == 0
                        ? colors.onSurfaceVariant
                        : _accentGreen(context),
                    size: 16,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    company.totalReviews == 0
                        ? '—'
                        : company.averageRating.toStringAsFixed(1),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colors.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                company.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: colors.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                company.sector,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              if (company.availableAreas.isNotEmpty) ...[
                _AreaChip(label: company.availableAreas.first),
                const SizedBox(height: 7),
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
                      '${company.municipality}, ${company.state}',
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
      ),
    );
  }
}

class _CompanyInitial extends StatelessWidget {
  const _CompanyInitial({required this.company, required this.size});

  final CompanyModel company;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: Style.getCircularBorderRadius(12),
      ),
      child: Text(
        company.name.trim().isEmpty
            ? 'E'
            : company.name.trim().substring(0, 1).toUpperCase(),
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: colors.onPrimaryContainer,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _FeaturedCompanyInitial extends StatelessWidget {
  const _FeaturedCompanyInitial({required this.company});

  final CompanyModel company;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: 36,
      height: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colors.onPrimary,
        borderRadius: Style.getCircularBorderRadius(10),
      ),
      child: Text(
        company.name.trim().isEmpty
            ? 'E'
            : company.name.trim().substring(0, 1).toUpperCase(),
        style: Theme.of(context).textTheme.titleSmall
            ?.copyWith(color: colors.primary, fontWeight: FontWeight.w700),
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
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: colors.onSurfaceVariant,
          fontWeight: FontWeight.normal,
        ),
      ),
    );
  }
}

Color _accentGreen(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
    ? Style.successDark
    : Theme.of(context).colorScheme.primary;
