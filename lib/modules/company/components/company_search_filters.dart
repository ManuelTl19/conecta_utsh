import 'package:material_ui/material_ui.dart';
import 'package:conecta_utsh/helpers/style.dart';

class CompanySearchFilters extends StatelessWidget {
  const CompanySearchFilters({
    required this.controller,
    required this.onSearch,
    required this.onFilterPressed,
    this.filtersActive = false,
    this.hintText = 'Buscar empresas',
    super.key,
  });

  final TextEditingController controller;
  final ValueChanged<String> onSearch;
  final VoidCallback onFilterPressed;
  final bool filtersActive;
  final String hintText;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: CompanySearchField(
            controller: controller,
            hintText: hintText,
            onChanged: onSearch,
          ),
        ),
        const SizedBox(width: 10),
        CompanyFilterButton(
          filtersActive: filtersActive,
          onPressed: onFilterPressed,
        ),
      ],
    );
  }
}

class CompanySearchField extends StatelessWidget {
  const CompanySearchField({
    required this.controller,
    required this.onChanged,
    this.hintText = 'Buscar empresas',
    super.key,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String hintText;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(13),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: Theme.of(context).textTheme.bodyMedium
            ?.copyWith(color: colors.onSurface),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: Theme.of(context).textTheme.labelMedium
              ?.copyWith(color: colors.onSurfaceVariant),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: colors.onSurfaceVariant,
            size: 20,
          ),
          suffixIcon: controller.text.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Limpiar búsqueda',
                  onPressed: () {
                    controller.clear();
                    onChanged('');
                  },
                  icon: const Icon(Icons.close_rounded, size: 18),
                ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 13),
        ),
      ),
    );
  }
}

class CompanyFilterButton extends StatelessWidget {
  const CompanyFilterButton({
    required this.filtersActive,
    required this.onPressed,
    super.key,
  });

  final bool filtersActive;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final accentGreen = Theme.of(context).brightness == Brightness.dark
        ? Style.successDark
        : colors.primary;
    return SizedBox(
      width: 44,
      height: 44,
      child: Material(
        color: colors.surfaceContainerLow,
        shape: const CircleBorder(),
        child: Semantics(
          button: true,
          label: filtersActive ? 'Filtros, hay filtros activos' : 'Filtros',
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                tooltip: filtersActive ? 'Filtros activos' : 'Filtros',
                constraints: const BoxConstraints.tightFor(
                  width: 44,
                  height: 44,
                ),
                padding: EdgeInsets.zero,
                onPressed: onPressed,
                icon: Icon(Icons.tune_rounded, color: accentGreen, size: 20),
              ),
              if (filtersActive)
                Positioned(
                  top: 3,
                  right: 3,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: accentGreen,
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

