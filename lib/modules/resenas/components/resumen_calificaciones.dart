import 'package:material_ui/material_ui.dart';
import 'package:conecta_utsh/modules/resenas/components/estrellas.dart';
import 'package:conecta_utsh/modules/resenas/models/resumen_model.dart';

class ResumenCalificaciones extends StatelessWidget {
  const ResumenCalificaciones({required this.resumen, super.key});

  final ResumenModel resumen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final maxCount = resumen.distribucion.values.fold<int>(
      0,
      (maximum, count) => count > maximum ? count : maximum,
    );

    return Card(
      elevation: 0,
      color: colors.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 104,
              child: Column(
                children: [
                  Text(
                    resumen.promedio.toStringAsFixed(1),
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colors.onSurface,
                    ),
                  ),
                  Estrellas(calificacion: resumen.promedio, size: 18),
                  const SizedBox(height: 4),
                  Text(
                    '${resumen.totalCalificaciones} ${resumen.totalCalificaciones == 1 ? 'reseña' : 'reseñas'}',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                children: [
                  for (var rating = 5; rating >= 1; rating--)
                    _DistributionRow(
                      rating: rating,
                      count: resumen.distribucion[rating] ?? 0,
                      maxCount: maxCount,
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

class _DistributionRow extends StatelessWidget {
  const _DistributionRow({
    required this.rating,
    required this.count,
    required this.maxCount,
  });

  final int rating;
  final int count;
  final int maxCount;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text('$rating', style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(width: 4),
          Icon(Icons.star_rounded, size: 13, color: colors.tertiary),
          const SizedBox(width: 7),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                minHeight: 7,
                value: maxCount == 0 ? 0 : count / maxCount,
                backgroundColor: colors.surfaceContainerHighest,
                color: colors.primary,
              ),
            ),
          ),
          const SizedBox(width: 7),
          SizedBox(
            width: 20,
            child: Text(
              '$count',
              textAlign: TextAlign.end,
              style: Theme.of(context).textTheme.labelSmall
                  ?.copyWith(color: colors.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}
