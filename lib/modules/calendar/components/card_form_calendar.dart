import 'package:material_ui/material_ui.dart';
import 'package:conecta_utsh/utils/widgets/dialogs.dart'; // Asegúrate de que aquí esté exportada la clase Dialogs
import 'package:conecta_utsh/modules/calendar/models/appointment_model.dart';
import 'package:conecta_utsh/modules/calendar/models/availability_model.dart';

class CardFormCalendar extends StatefulWidget {
  const CardFormCalendar({
    super.key,
    this.startHour = 9,
    this.endHour = 17,
    this.intervalMinutes = 10,
  });

  final int startHour;
  final int endHour;
  final int intervalMinutes;

  @override
  State<CardFormCalendar> createState() => _CardFormCalendarState();
}

class _CardFormCalendarState extends State<CardFormCalendar> {
  static const Color _brandGreen = Color(0xFF007A1C);

  final List<String> _direcciones = [
    'Tecnologías de la información',
    'Ciencias Económico Administrativas',
    'Ciencias Naturales e Ingeniería',
    'Ciencias Exactas',
    'Ciencias de la Salud',
  ];

  String _selectedDireccion = 'Tecnologías de la información';
  DirectionAvailabilityModel _currentAvailability = DirectionAvailabilityModel(
    direccion: 'Tecnologías de la información',
    hasAttention: false,
    attentionSchedule: 'Cargando horarios...',
    availableDates: [],
  );

  int _currentStep = 0; // 0: Dirección, 1: Fecha y Hora, 2: Motivo y Resumen
  int _selectedDateIndex = 0;
  int _selectedTimeIndex = -1;
  int _selectedHourFilter = 9;
  final TextEditingController _motivoController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedHourFilter = widget.startHour;
    _loadAvailabilityFor(_selectedDireccion);
  }

  List<TimeSlotModel> _generateSlots({Set<String> occupiedTimes = const {}}) {
    final List<TimeSlotModel> slots = [];
    final startTotalMinutes = widget.startHour * 60;
    final endTotalMinutes = widget.endHour * 60;

    for (int current = startTotalMinutes;
        current < endTotalMinutes;
        current += widget.intervalMinutes) {
      final next = current + widget.intervalMinutes;
      final startStr = _formatMinutes(current);
      final endStr = _formatMinutes(next);

      slots.add(
        TimeSlotModel(
          time: startStr,
          range: '$startStr–$endStr h',
          isAvailable: !occupiedTimes.contains(startStr),
        ),
      );
    }
    return slots;
  }

  String _formatMinutes(int totalMinutes) {
    final h = (totalMinutes ~/ 60).toString().padLeft(2, '0');
    final m = (totalMinutes % 60).toString().padLeft(2, '0');
    return '$h:$m';
  }

  void _loadAvailabilityFor(String direccion) {
    final startFormatted = '${widget.startHour.toString().padLeft(2, '0')}:00';
    final endFormatted = '${widget.endHour.toString().padLeft(2, '0')}:00';

    if (direccion == 'Ciencias de la Salud') {
      _currentAvailability = DirectionAvailabilityModel(
        direccion: direccion,
        hasAttention: false,
        attentionSchedule: 'Sin horarios asignados esta semana',
        noAttentionMessage:
            'Por el momento no hay fechas de atención disponibles para $direccion.',
        availableDates: [],
      );
    } else {
      _currentAvailability = DirectionAvailabilityModel(
        direccion: direccion,
        hasAttention: true,
        attentionSchedule:
            'Atención: miércoles · $startFormatted a $endFormatted h (citas de ${widget.intervalMinutes} min)',
        availableDates: [
          AvailableDateModel(
            rawDate: '2026-11-18',
            labelDate: '18 nov',
            dayName: 'Miércoles',
            slots: _generateSlots(
              occupiedTimes: {'09:10', '09:40', '10:00', '11:20', '14:00', '16:30'},
            ),
          ),
          AvailableDateModel(
            rawDate: '2026-11-25',
            labelDate: '25 nov',
            dayName: 'Miércoles',
            slots: _generateSlots(
              occupiedTimes: {'09:00', '10:30', '12:10', '15:00'},
            ),
          ),
        ],
      );
    }

    _selectedDateIndex = 0;
    if (_currentAvailability.hasAttention &&
        _currentAvailability.availableDates.isNotEmpty) {
      final firstSlots = _currentAvailability.availableDates.first.slots;
      _selectedTimeIndex = firstSlots.indexWhere((s) => s.isAvailable);
      if (_selectedTimeIndex >= 0) {
        final firstHour =
            int.tryParse(firstSlots[_selectedTimeIndex].time.split(':')[0]);
        if (firstHour != null) _selectedHourFilter = firstHour;
      }
    } else {
      _selectedTimeIndex = -1;
    }
  }

  @override
  void dispose() {
    _motivoController.dispose();
    super.dispose();
  }

  Future<void> _confirmarCita() async {
    final fechaObj = _currentAvailability.availableDates[_selectedDateIndex];
    final slotObj = fechaObj.slots[_selectedTimeIndex];

    final nuevaCita = AppointmentModel(
      title: 'Atención de Estadías',
      direccion: _selectedDireccion,
      date: fechaObj.labelDate,
      time: slotObj.time,
      range: slotObj.range,
      motivo: _motivoController.text.trim(),
      status: 'Confirmada',
    );

    // Muestra el diálogo animado de confirmación antes de cerrar el modal
    await Dialogs.showSimpleDialog(
      context,
      title: '¡Cita agendada!',
      message:
          'Tu cita para ${fechaObj.labelDate} a las ${slotObj.time} h ha sido registrada.',
      icon: Icons.check_circle_outline_rounded,
      color: _brandGreen,
    );

    if (mounted) {
      Navigator.of(context).pop(nuevaCita);
    }
  }

  String get _stepSubtitle {
    switch (_currentStep) {
      case 0:
        return 'Paso 1 de 3 · Selecciona tu dirección';
      case 1:
        return 'Paso 2 de 3 · Elige fecha y horario';
      default:
        return 'Paso 3 de 3 · Confirma los detalles';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final hasDates = _currentAvailability.hasAttention &&
        _currentAvailability.availableDates.isNotEmpty;

    final selectedDateObj =
        hasDates ? _currentAvailability.availableDates[_selectedDateIndex] : null;
    final currentSlots = selectedDateObj?.slots ?? [];
    final selectedSlotObj = (_selectedTimeIndex >= 0 &&
            _selectedTimeIndex < currentSlots.length)
        ? currentSlots[_selectedTimeIndex]
        : null;

    final bool canGoNext = _currentStep == 0
        ? hasDates
        : _currentStep == 1
            ? (selectedDateObj != null && selectedSlotObj != null)
            : true;

    return Material(
      color: colors.surface,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- ENCABEZADO FORMAL Y BARRA DE PROGRESO ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Agendar cita',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _stepSubtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                  tooltip: 'Cerrar',
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Indicador visual de 3 pasos
            Row(
              children: List.generate(3, (index) {
                final isCompletedOrCurrent = index <= _currentStep;
                return Expanded(
                  child: Container(
                    height: 4,
                    margin: EdgeInsets.only(right: index < 2 ? 6 : 0),
                    decoration: BoxDecoration(
                      color: isCompletedOrCurrent
                          ? _brandGreen
                          : colors.outlineVariant.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 14),

            // --- CONTENIDO DINÁMICO SEGÚN EL PASO ---
            Expanded(
              child: SingleChildScrollView(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: _buildCurrentStepContent(
                    theme: theme,
                    colors: colors,
                    hasDates: hasDates,
                    selectedDateObj: selectedDateObj,
                    currentSlots: currentSlots,
                    selectedSlotObj: selectedSlotObj,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // --- BOTONES DE NAVEGACIÓN INFERIORES ---
            Row(
              children: [
                if (_currentStep > 0) ...[
                  Expanded(
                    flex: 1,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        setState(() => _currentStep--);
                      },
                      child: const Text('Atrás'),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: _brandGreen,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: canGoNext
                        ? () {
                            if (_currentStep < 2) {
                              setState(() => _currentStep++);
                            } else {
                              _confirmarCita();
                            }
                          }
                        : null,
                    child: Text(
                      _currentStep < 2 ? 'Siguiente' : 'Confirmar cita',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentStepContent({
    required ThemeData theme,
    required ColorScheme colors,
    required bool hasDates,
    required AvailableDateModel? selectedDateObj,
    required List<TimeSlotModel> currentSlots,
    required TimeSlotModel? selectedSlotObj,
  }) {
    // PASO 1: DIRECCIÓN / CARRERA
    if (_currentStep == 0) {
      return Column(
        key: const ValueKey('step_0'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Dirección académica / carrera',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: colors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colors.outlineVariant.withValues(alpha: 0.6),
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedDireccion,
                isExpanded: true,
                icon: const Icon(Icons.keyboard_arrow_down_rounded),
                items: _direcciones.map((dir) {
                  return DropdownMenuItem<String>(
                    value: dir,
                    child: Text(
                      dir,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedDireccion = value;
                      _loadAvailabilityFor(value);
                    });
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: hasDates
                  ? _brandGreen.withValues(alpha: 0.08)
                  : colors.errorContainer.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: hasDates
                    ? _brandGreen.withValues(alpha: 0.3)
                    : colors.error.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  hasDates
                      ? Icons.info_outline_rounded
                      : Icons.event_busy_rounded,
                  color: hasDates ? _brandGreen : colors.error,
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    hasDates
                        ? _currentAvailability.attentionSchedule
                        : (_currentAvailability.noAttentionMessage ??
                            'Sin fechas disponibles.'),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurface,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    // PASO 2: FECHA Y HORARIO
    if (_currentStep == 1) {
      final hours = List.generate(
        widget.endHour - widget.startHour,
        (i) => widget.startHour + i,
      );

      final hourPrefix = '${_selectedHourFilter.toString().padLeft(2, '0')}:';
      final filteredSlots = currentSlots
          .asMap()
          .entries
          .where((entry) => entry.value.time.startsWith(hourPrefix))
          .toList();

      return Column(
        key: const ValueKey('step_1'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '1. Fecha disponible · 2026',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: List.generate(
              _currentAvailability.availableDates.length,
              (index) {
                final item = _currentAvailability.availableDates[index];
                final isSelected = _selectedDateIndex == index;

                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: index <
                              _currentAvailability.availableDates.length - 1
                          ? 10
                          : 0,
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        setState(() {
                          _selectedDateIndex = index;
                          _selectedTimeIndex =
                              item.slots.indexWhere((s) => s.isAvailable);
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? _brandGreen
                              : colors.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? _brandGreen
                                : colors.outlineVariant.withValues(alpha: 0.6),
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              item.labelDate,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: isSelected
                                    ? Colors.white
                                    : colors.onSurface,
                              ),
                            ),
                            Text(
                              item.dayName,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: isSelected
                                    ? Colors.white.withValues(alpha: 0.9)
                                    : colors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '2. Hora (${widget.startHour}:00 - ${widget.endHour}:00)',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (selectedSlotObj != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _brandGreen.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Elegido: ${selectedSlotObj.time} h',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: _brandGreen,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: hours.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final hour = hours[index];
                final isHourSelected = _selectedHourFilter == hour;
                final label = '${hour.toString().padLeft(2, '0')}:00';

                final prefix = '${hour.toString().padLeft(2, '0')}:';
                final hasFreeSlot = currentSlots
                    .any((s) => s.time.startsWith(prefix) && s.isAvailable);

                return ChoiceChip(
                  label: Text(label),
                  selected: isHourSelected,
                  selectedColor: _brandGreen,
                  labelStyle: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    color: isHourSelected
                        ? Colors.white
                        : hasFreeSlot
                            ? colors.onSurface
                            : colors.onSurfaceVariant.withValues(alpha: 0.4),
                  ),
                  backgroundColor: colors.surfaceContainerLowest,
                  side: BorderSide(
                    color: isHourSelected
                        ? _brandGreen
                        : colors.outlineVariant.withValues(alpha: 0.5),
                  ),
                  onSelected: (_) {
                    setState(() => _selectedHourFilter = hour);
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: filteredSlots.map((entry) {
              final globalIndex = entry.key;
              final slot = entry.value;
              final isSelected = _selectedTimeIndex == globalIndex;

              return InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: slot.isAvailable
                    ? () => setState(() => _selectedTimeIndex = globalIndex)
                    : null,
                child: Container(
                  width: (MediaQuery.of(context).size.width - 56) / 3,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: !slot.isAvailable
                        ? colors.surfaceContainerLow.withValues(alpha: 0.5)
                        : isSelected
                            ? _brandGreen
                            : colors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: !slot.isAvailable
                          ? colors.outlineVariant.withValues(alpha: 0.4)
                          : _brandGreen,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        slot.time,
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          decoration: !slot.isAvailable
                              ? TextDecoration.lineThrough
                              : null,
                          color: !slot.isAvailable
                              ? colors.onSurfaceVariant.withValues(alpha: 0.45)
                              : isSelected
                                  ? Colors.white
                                  : _brandGreen,
                        ),
                      ),
                      Text(
                        !slot.isAvailable ? 'Ocupado' : 'Disponible',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontSize: 10,
                          color: !slot.isAvailable
                              ? colors.onSurfaceVariant.withValues(alpha: 0.45)
                              : isSelected
                                  ? Colors.white.withValues(alpha: 0.9)
                                  : _brandGreen,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      );
    }

    // PASO 3: MOTIVO Y RESUMEN DE CONFIRMACIÓN
    return Column(
      key: const ValueKey('step_2'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Resumen de la solicitud',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: _brandGreen,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _selectedDireccion,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${selectedDateObj?.dayName ?? ''} ${selectedDateObj?.labelDate ?? ''} · ${selectedSlotObj?.range ?? ''}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'Motivo de la atención (opcional)',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _motivoController,
          maxLines: 2,
          decoration: InputDecoration(
            hintText: 'Ej. Revisión de carta de presentación o proyecto...',
            hintStyle: theme.textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceVariant.withValues(alpha: 0.7),
            ),
            filled: true,
            fillColor: colors.surfaceContainerLowest,
            contentPadding: const EdgeInsets.all(12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: colors.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: colors.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
          ),
        ),
      ],
    );
  }
}