import 'package:material_ui/material_ui.dart';
import 'package:intl/intl.dart';
import 'package:conecta_utsh/modules/company/components/company_logo.dart';
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
    final colors = Theme.of(context).colorScheme;
    final white = colors.onPrimary;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: colors.primary.withValues(alpha: .22),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colors.primary,
                Color.lerp(colors.primary, colors.surface, .18)!,
              ],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -24,
                top: -38,
                child: _DecorationCircle(color: white.withValues(alpha: .08)),
              ),
              Positioned(
                right: 68,
                bottom: -62,
                child: _DecorationCircle(color: white.withValues(alpha: .06)),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(17, 15, 17, 15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: colors.surface,
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: colors.shadow.withValues(alpha: .16),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: CompanyLogo(
                            logoKey: company.logoKey,
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 11),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                company.position,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(
                                      color: white,
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                company.name,
                                style: Theme.of(context).textTheme.labelMedium
                                    ?.copyWith(
                                      color: white.withValues(alpha: .76),
                                    ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: company.isSaved
                              ? 'Quitar de guardados'
                              : 'Guardar',
                          onPressed: onSave,
                          visualDensity: VisualDensity.compact,
                          icon: Icon(
                            company.isSaved
                                ? Icons.bookmark_rounded
                                : Icons.bookmark_add_outlined,
                            color: white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: company.tags.take(3).map((tag) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: white.withValues(alpha: .14),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: white.withValues(alpha: .12),
                                ),
                              ),
                              child: Text(
                                tag,
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(color: white),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${company.currency}${NumberFormat.decimalPattern('es_MX').format(company.salary)} ${company.period}',
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(
                                  color: white,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                        ),
                        const SizedBox(width: 7),
                        Icon(
                          Icons.location_on_outlined,
                          size: 15,
                          color: white.withValues(alpha: .8),
                        ),
                        Flexible(
                          child: Text(
                            company.location,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.end,
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(color: white),
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
      ),
    );
  }
}

class _DecorationCircle extends StatelessWidget {
  const _DecorationCircle({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: 140,
    height: 140,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}

class CompanyCard extends StatelessWidget {
  const CompanyCard({required this.company, super.key});

  final CompanyModel company;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      constraints: const BoxConstraints(minHeight: 160),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 13),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: .12),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CompanyLogo(logoKey: company.logoKey, size: 36),
          const SizedBox(height: 9),
          Text(
            company.position,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: colors.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            company.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: colors.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          Text(
            '${company.currency}${NumberFormat.decimalPattern('es_MX').format(company.salary)}/${company.period == 'al año' ? 'año' : 'mes'}',
            style: Theme.of(context).textTheme.labelMedium
                ?.copyWith(color: colors.onSurface),
          ),
        ],
      ),
    );
  }
}
