import 'package:material_ui/material_ui.dart';

class UserAvatar extends StatelessWidget {
  const UserAvatar({
    required this.name,
    this.size = 42,
    this.showNotification = false,
    this.onTap,
    super.key,
  });

  final String name;
  final double size;
  final bool showNotification;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final initials = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();
    return Tooltip(
      message: 'Ver perfil',
      child: Semantics(
        button: onTap != null,
        label: 'Abrir menú de usuario',
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              CircleAvatar(
                radius: size / 2,
                backgroundColor: colors.primary.withValues(alpha: .12),
                child: Text(
                  initials,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: colors.primary,
                    fontSize: size * .29,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (showNotification)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    width: size * .23,
                    height: size * .23,
                    decoration: BoxDecoration(
                      color: colors.error,
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

class HomeSearchBar extends StatelessWidget {
  const HomeSearchBar({
    required this.onSearch,
    required this.onFilterPressed,
    super.key,
  });

  final ValueChanged<String> onSearch;
  final VoidCallback onFilterPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 46,
            decoration: BoxDecoration(
              color: colors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(13),
            ),
            child: TextField(
              onChanged: onSearch,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: colors.onSurface),
              decoration: InputDecoration(
                hintText: 'Buscar empresas',
                hintStyle: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(color: colors.onSurfaceVariant),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: colors.onSurfaceVariant,
                  size: 20,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 13),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 46,
          height: 46,
          child: Material(
            color: colors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(13),
            child: IconButton(
              tooltip: 'Filtros',
              onPressed: onFilterPressed,
              icon: Icon(Icons.tune_rounded, color: colors.tertiary, size: 20),
            ),
          ),
        ),
      ],
    );
  }
}

class HomeSectionHeading extends StatelessWidget {
  const HomeSectionHeading({
    required this.title,
    required this.onViewAll,
    super.key,
  });

  final String title;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: colors.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        TextButton(
          onPressed: onViewAll,
          style: TextButton.styleFrom(
            minimumSize: Size.zero,
            padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 3),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            'Ver todo',
            style: Theme.of(context).textTheme.labelSmall
                ?.copyWith(color: colors.onSurfaceVariant),
          ),
        ),
      ],
    );
  }
}
