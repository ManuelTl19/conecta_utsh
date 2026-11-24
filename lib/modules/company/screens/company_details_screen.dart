import 'package:material_ui/material_ui.dart';
import 'package:conecta_utsh/modules/company/models/company_model.dart';

class CompanyDetailScreen extends StatefulWidget {
  const CompanyDetailScreen({
    required this.company,
    this.onToggleSaved,
    super.key,
  });

  final CompanyModel company;
  final ValueChanged<CompanyModel>? onToggleSaved;

  @override
  State<CompanyDetailScreen> createState() => _CompanyDetailScreenState();
}

class _CompanyDetailScreenState extends State<CompanyDetailScreen> {
  static const Color _brandGreen = Color(0xFF0A7C1D);

  late bool _isSaved;
  int _selectedTabIndex = 1; // Inicia en "Requisitos" como en el diseño

  final List<String> _tabs = const [
    'Descripción',
    'Requisitos',
    'Acerca de',
    'Reseñas',
  ];

  @override
  void initState() {
    super.initState();
    _isSaved = widget.company.isSaved;
  }

  void _toggleSave() {
    setState(() {
      _isSaved = !_isSaved;
    });
    widget.onToggleSaved?.call(widget.company.copyWith(isSaved: _isSaved));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final company = widget.company;

    // Construimos las 3 píldoras exactamente como en la imagen
    final pills = <String>[
      if (company.tags.isNotEmpty) company.tags.first else 'General',
      company.employmentType,
      company.level,
    ];

    return Scaffold(
      backgroundColor: colors.surface,
      body: Column(
        children: [
          // =========================================================
          // 1. ENCABEZADO VERDE CON PATRÓN Y ESQUINAS REDONDEADAS
          // =========================================================
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(32),
            ),
            child: Container(
              width: double.infinity,
              color: _brandGreen,
              child: Stack(
                children: [
                  // Patrón geométrico sutil de fondo
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _DoodlePatternPainter(),
                    ),
                  ),
                  SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 26),
                      child: Column(
                        children: [
                          // Barra superior: Regresar y Bookmark+
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                onPressed: () => Navigator.of(context).pop(),
                                icon: const Icon(
                                  Icons.arrow_back_ios_new_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              IconButton(
                                onPressed: _toggleSave,
                                icon: Icon(
                                  _isSaved
                                      ? Icons.bookmark_added_rounded
                                      : Icons.bookmark_add_outlined,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                            ],
                          ),

                          // Logo circular blanco centrado
                          Container(
                            width: 78,
                            height: 78,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              company.name.isNotEmpty
                                  ? company.name.substring(0, 1).toUpperCase()
                                  : 'E',
                              style: theme.textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: _brandGreen,
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Puesto y Empresa
                          Text(
                            company.position,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            company.name,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withValues(alpha: 0.75),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // 3 Píldoras translúcidas (Tag, EmploymentType, Level)
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
                                      color:
                                          Colors.white.withValues(alpha: 0.16),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      label,
                                      style:
                                          theme.textTheme.labelMedium?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                          const SizedBox(height: 22),

                          // Fila inferior: Salario y Ubicación
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '\$${company.salary.toStringAsFixed(2)}',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Flexible(
                                  child: Text(
                                    company.location,
                                    textAlign: TextAlign.right,
                                    overflow: TextOverflow.ellipsis,
                                    style:
                                        theme.textTheme.titleMedium?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // =========================================================
          // 2. BARRA DE PESTAÑAS (Descripción, Requisitos, Acerca de, Reseñas)
          // =========================================================
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(_tabs.length, (index) {
                final isSelected = _selectedTabIndex == index;
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
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected
                            ? colors.onSurface
                            : colors.onSurfaceVariant.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),

          // =========================================================
          // 3. CONTENIDO DE LA PESTAÑA ACTIVA
          // =========================================================
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: _buildTabContent(theme, colors),
            ),
          ),

          // =========================================================
          // 4. BOTÓN INFERIOR VERDE ("Guardar")
          // =========================================================
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: _brandGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: _toggleSave,
                  child: Text(
                    _isSaved ? 'Guardado' : 'Guardar',
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

  Widget _buildTabContent(ThemeData theme, ColorScheme colors) {
    final company = widget.company;

    switch (_selectedTabIndex) {
      case 0: // Descripción
        return Text(
          'Buscamos talento para integrarse como ${company.position} en ${company.name} '
          '(${company.location}). Modalidad ${company.employmentType} para perfil nivel '
          '${company.level}, colaborando en proyectos clave con compensación de '
          '${company.currency} \$${company.salary} / ${company.period}.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colors.onSurfaceVariant,
            height: 1.55,
          ),
        );

      case 1: // Requisitos (Lista con viñetas como en la imagen)
        final requisitos = [
          'Formación o carrera afín en ${company.tags.isNotEmpty ? company.tags.join(", ") : "el área solicitada"}.',
          'Conocimientos sólidos acordes al nivel ${company.level} en ${company.position}.',
          'Capacidad para liderar y conceptualizar soluciones desde cero, aplicando buenas prácticas.',
          'Habilidades de comunicación efectiva y trabajo colaborativo con equipos multidisciplinarios.',
          'Excelente capacidad de resolución de problemas y adaptación a requerimientos técnicos.',
          'Portafolio o evidencias de proyectos previos desarrollados.',
        ];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: requisitos
              .map(
                (req) => Padding(
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
                          req,
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

      case 2: // Acerca de
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              company.name,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ubicación: ${company.location}\n'
              'Tipo de contratación: ${company.employmentType}\n'
              'Áreas clave: ${company.tags.join(", ")}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
                height: 1.6,
              ),
            ),
          ],
        );

      default: // Reseñas
        return Text(
          'Aún no hay reseñas publicadas para ${company.name}.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colors.onSurfaceVariant,
          ),
        );
    }
  }
}

/// Dibuja las figuras geométricas sutiles en el fondo verde del encabezado
class _DoodlePatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // Círculos, cruces y líneas decorativas distribuidas
    canvas.drawCircle(Offset(size.width * 0.15, size.height * 0.25), 14, paint);
    canvas.drawCircle(Offset(size.width * 0.85, size.height * 0.20), 18, paint);
    canvas.drawCircle(Offset(size.width * 0.32, size.height * 0.42), 10, paint);

    // Cruces (+)
    _drawPlus(canvas, Offset(size.width * 0.45, size.height * 0.82), 12, paint);
    _drawPlus(canvas, Offset(size.width * 0.90, size.height * 0.50), 10, paint);
    _drawPlus(canvas, Offset(size.width * 0.12, size.height * 0.72), 10, paint);

    // Líneas diagonales
    canvas.drawLine(
      Offset(size.width * 0.65, size.height * 0.15),
      Offset(size.width * 0.72, size.height * 0.22),
      paint,
    );
    canvas.drawLine(
      Offset(size.width * 0.22, size.height * 0.88),
      Offset(size.width * 0.28, size.height * 0.94),
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