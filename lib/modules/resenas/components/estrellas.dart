import 'package:material_ui/material_ui.dart';

class Estrellas extends StatelessWidget {
  const Estrellas({required this.calificacion, this.size = 20, super.key});

  final double calificacion;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.tertiary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final value = index + 1;
        final icon = calificacion >= value
            ? Icons.star_rounded
            : calificacion >= value - 0.5
            ? Icons.star_half_rounded
            : Icons.star_outline_rounded;
        return Icon(icon, size: size, color: color);
      }),
    );
  }
}

class SelectorEstrellas extends StatelessWidget {
  const SelectorEstrellas({
    required this.calificacion,
    required this.onChanged,
    this.enabled = true,
    this.size = 36,
    super.key,
  });

  final int calificacion;
  final ValueChanged<int> onChanged;
  final bool enabled;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.tertiary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final value = index + 1;
        return IconButton(
          tooltip: '$value ${value == 1 ? 'estrella' : 'estrellas'}',
          onPressed: enabled ? () => onChanged(value) : null,
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          constraints: BoxConstraints.tightFor(width: size, height: size),
          icon: Icon(
            calificacion >= value
                ? Icons.star_rounded
                : Icons.star_outline_rounded,
            size: size,
            color: color,
          ),
        );
      }),
    );
  }
}
