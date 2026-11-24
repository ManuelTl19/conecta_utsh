import 'dart:ui';

import 'package:material_ui/material_ui.dart';

class QuickMenu extends StatelessWidget {
  const QuickMenu({
    required this.selectedIndex,
    required this.onSelected,
    super.key,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  static const _items = [
    (icon: Icons.calendar_month_outlined, label: 'Calendario'),
    (icon: Icons.home_outlined, label: 'Inicio'),
    (icon: Icons.settings_outlined, label: 'Ajustes'),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final bottomPadding = MediaQuery.paddingOf(context).bottom + 12;
    return Padding(
      padding: EdgeInsets.fromLTRB(18, 8, 18, bottomPadding),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            height: 72,
            decoration: BoxDecoration(
              color: colors.surface.withValues(alpha: .42),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: colors.outline.withValues(alpha: .30)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                for (var index = 0; index < _items.length; index++)
                  _QuickMenuItem(
                    icon: _items[index].icon,
                    label: _items[index].label,
                    selected: index == selectedIndex,
                    onTap: () => onSelected(index),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickMenuItem extends StatelessWidget {
  const _QuickMenuItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        label: label,
        child: InkWell(
          onTap: onTap,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeInOut,
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: selected
                        ? colors.primary.withValues(alpha: .12)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: AnimatedScale(
                    scale: selected ? 1.12 : 1,
                    duration: const Duration(milliseconds: 260),
                    curve: Curves.easeOutBack,
                    child: Icon(
                      icon,
                      size: 23,
                      color: selected
                          ? colors.primary
                          : colors.onSurface.withValues(alpha: .48),
                    ),
                  ),
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeInOut,
                  child: selected
                      ? Text(
                          label,
                          maxLines: 1,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: colors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                        )
                      : const SizedBox(height: 0),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
