import 'package:material_ui/material_ui.dart';
import 'package:conecta_utsh/modules/app/components/home_components.dart';

class UserDrawer extends StatelessWidget {
  const UserDrawer({
    required this.name,
    required this.role,
    required this.onClose,
    required this.onSettings,
    required this.onLogout,
    required this.onOption,
    super.key,
  });

  final String name;
  final String role;
  final VoidCallback onClose;
  final VoidCallback onSettings;
  final VoidCallback onLogout;
  final ValueChanged<String> onOption;

  static const _options = [
    ('Información personal', Icons.badge_outlined),
    ('Aplicantes', Icons.assignment_ind_outlined),
    ('Proposals', Icons.assignment_outlined),
    ('Resumen', Icons.description_outlined),
    ('Portafolio', Icons.work_outline_rounded),
    ('Cover Letters', Icons.article_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.surface,
      child: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                tooltip: 'Cerrar menú',
                onPressed: onClose,
                icon: Icon(Icons.close, color: colors.onSurface),
              ),
            ),
            const SizedBox(height: 8),
            UserAvatar(name: name, size: 76),
            const SizedBox(height: 10),
            Text(
              name,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: colors.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 3),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  role,
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(color: colors.onSurfaceVariant),
                ),
                const SizedBox(width: 4),
                Icon(Icons.verified_rounded, size: 14, color: colors.primary),
              ],
            ),
            TextButton(
              onPressed: () => onOption('Ver perfil'),
              child: Text(
                'Ver perfil',
                style: Theme.of(context).textTheme.labelLarge
                    ?.copyWith(color: colors.primary),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                children: [
                  for (final (label, icon) in _options)
                    _DrawerItem(
                      label: label,
                      icon: icon,
                      onTap: () => onOption(label),
                    ),
                  _DrawerItem(
                    label: 'Configuración',
                    icon: Icons.settings_outlined,
                    onTap: onSettings,
                  ),
                  _DrawerItem(
                    label: 'Cerrar sesión',
                    icon: Icons.logout_rounded,
                    color: colors.error,
                    onTap: onLogout,
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

class _DrawerItem extends StatelessWidget {
  const _DrawerItem({
    required this.label,
    required this.icon,
    required this.onTap,
    this.color,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final itemColor = color ?? colors.onSurface;
    return Tooltip(
      message: label,
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
        leading: Icon(icon, size: 20, color: color ?? colors.onSurfaceVariant),
        title: Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium
              ?.copyWith(color: itemColor, fontWeight: FontWeight.w500),
        ),
        onTap: onTap,
      ),
    );
  }
}
