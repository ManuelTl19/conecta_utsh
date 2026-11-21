import 'package:material_ui/material_ui.dart';

import 'package:conecta_utsh/helpers/style.dart';

class ThemeToggleButton extends StatelessWidget {
  const ThemeToggleButton({
    required this.onPressed,
    required this.isSaving,
    super.key,
  });

  final VoidCallback onPressed;
  final bool isSaving;

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Style.isDarkModeOn;
    return Material(
      color: Style.getCardColor(),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: IconButton(
        tooltip: isDarkMode ? 'Cambiar a modo claro' : 'Cambiar a modo oscuro',
        onPressed: isSaving ? null : onPressed,
        icon: isSaving
            ? const SizedBox(
                width: 19,
                height: 19,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(
                isDarkMode
                    ? Icons.light_mode_outlined
                    : Icons.dark_mode_outlined,
                color: Style.getPrimaryColor(),
                size: 19,
              ),
      ),
    );
  }
}
