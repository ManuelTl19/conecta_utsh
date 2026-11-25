import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:conecta_utsh/modules/company/models/company_model.dart';
import 'package:conecta_utsh/modules/favoritos/components/favorito_button.dart';

class CompanyDetailScreen extends StatefulWidget {
  const CompanyDetailScreen({required this.company, super.key});

  final CompanyModel company;

  @override
  State<CompanyDetailScreen> createState() => _CompanyDetailScreenState();
}

class _CompanyDetailScreenState extends State<CompanyDetailScreen> {
  int _selectedTabIndex = 1;

  static const _tabs = ['Descripción', 'Requisitos', 'Contacto'];

  String get _companyName {
    final name = widget.company.name?.trim();
    return name == null || name.isEmpty ? 'Empresa sin nombre' : name;
  }

  String? get _primaryContact =>
      _usable(widget.company.contact.email) ??
      _usable(widget.company.contact.phone);

  Future<void> _copy(String value, String label) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('$label copiado.')));
  }

  Future<void> _performPrimaryAction() async {
    final contact = _primaryContact;
    if (contact == null) {
      Navigator.of(context).pop();
      return;
    }
    await _copy(
      contact,
      contact == _usable(widget.company.contact.email) ? 'Correo' : 'Teléfono',
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final company = widget.company;
    final location = _companyLocation;
    final pills = <String>{
      if (_usable(company.sector) != null) _usable(company.sector)!,
      ...company.availableAreas.take(2),
    }.where((label) => label.trim().isNotEmpty).toList();

    return Scaffold(
      backgroundColor: colors.surface,
      body: Column(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(32),
            ),
            child: Container(
              width: double.infinity,
              color: colors.primary,
              child: Stack(
                children: [
                  const Positioned.fill(
                    child: CustomPaint(painter: _DoodlePatternPainter()),
                  ),
                  SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 26),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                tooltip: 'Regresar',
                                onPressed: () => Navigator.of(context).pop(),
                                icon: const Icon(
                                  Icons.arrow_back_ios_new_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  FavoritoButton(
                                    company: company,
                                    inactiveColor: colors.onPrimary,
                                  ),
                                  if (_primaryContact != null)
                                    IconButton(
                                      tooltip: 'Copiar contacto',
                                      onPressed: _performPrimaryAction,
                                      icon: const Icon(
                                        Icons.copy_rounded,
                                        color: Colors.white,
                                        size: 22,
                                      ),
                                    )
                                  else
                                    const SizedBox(width: 48),
                                ],
                              ),
                            ],
                          ),
                          Container(
                            width: 78,
                            height: 78,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              _companyName.substring(0, 1).toUpperCase(),
                              style: theme.textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colors.primary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            _companyName,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _usable(company.sector) ?? 'Empresa',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withValues(alpha: 0.75),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (pills.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            Wrap(
                              spacing: 10,
                              runSpacing: 8,
                              alignment: WrapAlignment.center,
                              children: pills
                                  .map(
                                    (label) => Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 18,
                                        vertical: 7,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(
                                          alpha: 0.16,
                                        ),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        label,
                                        style: theme.textTheme.labelMedium
                                            ?.copyWith(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w500,
                                            ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ],
                          const SizedBox(height: 22),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on_outlined,
                                color: colors.onPrimary,
                                size: 18,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  location.isEmpty
                                      ? 'Ubicación no especificada'
                                      : location,
                                  textAlign: TextAlign.right,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(_tabs.length, (index) {
                final selected = _selectedTabIndex == index;
                return GestureDetector(
                  onTap: () => setState(() => _selectedTabIndex = index),
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 6,
                    ),
                    child: Text(
                      _tabs[index],
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: selected
                            ? FontWeight.bold
                            : FontWeight.w500,
                        color: selected
                            ? colors.onSurface
                            : colors.onSurfaceVariant.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: _buildTabContent(theme, colors),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: colors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: _performPrimaryAction,
                  child: Text(
                    _primaryContact == null
                        ? 'Volver al directorio'
                        : 'Copiar contacto',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String get _companyLocation => [
    _usable(widget.company.location.municipality),
    _usable(widget.company.location.state),
  ].whereType<String>().join(', ');

  Widget _buildTabContent(ThemeData theme, ColorScheme colors) {
    final company = widget.company;
    switch (_selectedTabIndex) {
      case 0:
        return Text(
          _usable(company.description) ?? 'No hay descripción disponible.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colors.onSurfaceVariant,
            height: 1.55,
          ),
        );
      case 1:
        if (company.requirements.isEmpty) {
          return Text(
            'No se especificaron requisitos.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: company.requirements
              .map(
                (requirement) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '•  ',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          requirement,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colors.onSurfaceVariant,
                            height: 1.45,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
        );
      case 2:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_usable(company.contact.email) != null)
              _ContactValue(
                label: 'Correo',
                value: company.contact.email!,
                onCopy: () => _copy(company.contact.email!, 'Correo'),
              ),
            if (_usable(company.contact.phone) != null)
              _ContactValue(
                label: 'Teléfono',
                value: company.contact.phone!,
                onCopy: () => _copy(company.contact.phone!, 'Teléfono'),
              ),
            if (_usable(company.location.address) != null)
              _ContactValue(
                label: 'Dirección',
                value: company.location.address!,
              ),
            if (_usable(company.location.mapUrl) != null)
              _ContactValue(
                label: 'Enlace del mapa',
                value: company.location.mapUrl!,
                onCopy: () => _copy(company.location.mapUrl!, 'Enlace'),
              ),
            if (_primaryContact == null &&
                _usable(company.location.address) == null &&
                _usable(company.location.mapUrl) == null)
              Text(
                'No hay datos de contacto disponibles.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

class _ContactValue extends StatelessWidget {
  const _ContactValue({required this.label, required this.value, this.onCopy});

  final String label;
  final String value;
  final VoidCallback? onCopy;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelMedium
                      ?.copyWith(color: colors.onSurfaceVariant),
                ),
                const SizedBox(height: 4),
                SelectableText(value),
              ],
            ),
          ),
          if (onCopy != null)
            IconButton(
              tooltip: 'Copiar $label',
              onPressed: onCopy,
              icon: const Icon(Icons.copy_rounded),
            ),
        ],
      ),
    );
  }
}

class _DoodlePatternPainter extends CustomPainter {
  const _DoodlePatternPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawCircle(Offset(size.width * .15, size.height * .25), 14, paint);
    canvas.drawCircle(Offset(size.width * .85, size.height * .20), 18, paint);
    canvas.drawCircle(Offset(size.width * .32, size.height * .42), 10, paint);
    _drawPlus(canvas, Offset(size.width * .45, size.height * .82), 12, paint);
    _drawPlus(canvas, Offset(size.width * .90, size.height * .50), 10, paint);
    _drawPlus(canvas, Offset(size.width * .12, size.height * .72), 10, paint);
    canvas.drawLine(
      Offset(size.width * .65, size.height * .15),
      Offset(size.width * .72, size.height * .22),
      paint,
    );
    canvas.drawLine(
      Offset(size.width * .22, size.height * .88),
      Offset(size.width * .28, size.height * .94),
      paint,
    );
  }

  void _drawPlus(Canvas canvas, Offset center, double radius, Paint paint) {
    canvas.drawLine(
      Offset(center.dx - radius, center.dy),
      Offset(center.dx + radius, center.dy),
      paint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy - radius),
      Offset(center.dx, center.dy + radius),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

String? _usable(String? value) {
  final trimmed = value?.trim();
  return trimmed == null || trimmed.isEmpty ? null : trimmed;
}
