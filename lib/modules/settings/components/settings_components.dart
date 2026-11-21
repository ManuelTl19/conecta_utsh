import 'package:material_ui/material_ui.dart';
import 'package:conecta_utsh/modules/settings/models/settings_option_model.dart';

class SettingsSectionCard extends StatelessWidget {
  const SettingsSectionCard({
    required this.title,
    required this.options,
    required this.values,
    required this.onToggle,
    required this.onOptionPressed,
    super.key,
  });

  final String title;
  final List<SettingsOptionModel> options;
  final Map<String, bool> values;
  final ValueChanged<SettingsOptionModel> onToggle;
  final ValueChanged<SettingsOptionModel> onOptionPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: colors.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
          decoration: BoxDecoration(
            color: colors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(17),
          ),
          child: Column(
            children: [
              for (var index = 0; index < options.length; index++) ...[
                SettingsOptionTile(
                  option: options[index],
                  value: values[options[index].id] ?? false,
                  onToggle: () => onToggle(options[index]),
                  onPressed: () => onOptionPressed(options[index]),
                ),
                if (index < options.length - 1)
                  Divider(
                    height: 1,
                    thickness: .5,
                    indent: 2,
                    color: colors.outline.withValues(alpha: .5),
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class SettingsOptionTile extends StatelessWidget {
  const SettingsOptionTile({
    required this.option,
    required this.value,
    required this.onToggle,
    required this.onPressed,
    this.destructive = false,
    super.key,
  });

  final SettingsOptionModel option;
  final bool value;
  final VoidCallback onToggle;
  final VoidCallback onPressed;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final color = destructive ? colors.error : colors.onSurfaceVariant;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 48),
      child: Row(
        children: [
          if (option.type != SettingsOptionType.toggle) ...[
            Icon(option.icon, size: 18, color: color),
            const SizedBox(width: 11),
          ],
          Expanded(
            child: InkWell(
              onTap: option.type == SettingsOptionType.toggle
                  ? onToggle
                  : onPressed,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  option.label,
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(color: color, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
          if (option.subtitle != null)
            Text(
              option.subtitle!,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: colors.onSurfaceVariant.withValues(alpha: .72),
              ),
            ),
          if (option.type == SettingsOptionType.toggle)
            Switch(
              value: value,
              onChanged: (_) => onToggle(),
              activeThumbColor: colors.primary,
              activeTrackColor: colors.primary.withValues(alpha: .3),
            )
          else if (!destructive)
            Icon(
              Icons.chevron_right_rounded,
              color: colors.onSurfaceVariant,
              size: 20,
            ),
        ],
      ),
    );
  }
}
