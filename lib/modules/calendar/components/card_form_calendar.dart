import 'package:material_ui/material_ui.dart';
import 'package:conecta_utsh/modules/calendar/models/appointment_model.dart';
import 'package:conecta_utsh/modules/calendar/models/availability_model.dart';

class CardFormCalendar extends StatefulWidget {
  const CardFormCalendar({super.key});

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

  int _selectedDateIndex = 0;
  int _selectedTimeIndex = -1;
  final TextEditingController _motivoController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadAvailabilityFor(_selectedDireccion);
  }

  void _loadAvailabilityFor(String direccion) {
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
        attentionSchedule: 'Atención: miércoles · 09:00 a 12:00 h',
        availableDates: [
          AvailableDateModel(
            rawDate: '2026-11-18',
            labelDate: '18 nov',
            dayName: 'Miércoles',
            slots: [
              TimeSlotModel(time: '09:00', range: '09:00–09:30 h', isAvailable: true),
              TimeSlotModel(time: '09:30', range: '09:30–10:00 h', isAvailable: false),
              TimeSlotModel(time: '10:00', range: '10:00–10:30 h', isAvailable: true),
              TimeSlotModel(time: '10:30', range: '10:30–11:00 h', isAvailable: false),
              TimeSlotModel(time: '11:00', range: '11:00–11:30 h', isAvailable: false),
              TimeSlotModel(time: '11:30', range: '11:30–12:00 h', isAvailable: true),
            ],
          ),
          AvailableDateModel(
            rawDate: '2026-11-25',
            labelDate: '25 nov',
            dayName: 'Miércoles',
            slots: [
              TimeSlotModel(time: '09:00', range: '09:00–09:30 h', isAvailable: true),
              TimeSlotModel(time: '10:00', range: '10:00–10:30 h', isAvailable: true),
              TimeSlotModel(time: '11:00', range: '11:00–11:30 h', isAvailable: true),
            ],
          ),
        ],
      );
    }

    _selectedDateIndex = 0;
    if (_currentAvailability.hasAttention &&
        _currentAvailability.availableDates.isNotEmpty) {
      final firstSlots = _currentAvailability.availableDates.first.slots;
      _selectedTimeIndex = firstSlots.indexWhere((s) => s.isAvailable);
    } else {
      _selectedTimeIndex = -1;
    }
  }

  @override
  void dispose() {
    _motivoController.dispose();
    super.dispose();
  }

  void _confirmarCita() {
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

    Navigator.of(context).pop(nuevaCita);
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

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        backgroundColor: colors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        titleSpacing: 0,
        title: Text(
          'Agendar cita',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Reserva tu atención de estadías.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 18),

              // 1. Dirección / carrera
              Text(
                'Dirección / carrera',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: colors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: colors.outlineVariant.withValues(alpha: 0.5),
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
              const SizedBox(height: 6),
              Text(
                _currentAvailability.attentionSchedule,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),

              if (!hasDates)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: colors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: colors.outlineVariant),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.event_busy_rounded,
                        size: 40,
                        color: colors.onSurfaceVariant,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _currentAvailability.noAttentionMessage ??
                            'No hay fechas disponibles por el momento.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                )
              else ...[
                // 2. Fecha disponible
                Text(
                  'Fecha disponible · 2026',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
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
                            borderRadius: BorderRadius.circular(14),
                            onTap: () {
                              setState(() {
                                _selectedDateIndex = index;
                                _selectedTimeIndex = item.slots
                                    .indexWhere((s) => s.isAvailable);
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? _brandGreen
                                    : colors.surfaceContainerLowest,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isSelected
                                      ? _brandGreen
                                      : colors.outlineVariant
                                          .withValues(alpha: 0.6),
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
                                  const SizedBox(height: 2),
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
                const SizedBox(height: 6),
                Text(
                  'Solo se muestran días de atención de tu dirección.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 20),

                // 3. Horario disponible
                Text(
                  'Horario disponible',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: currentSlots.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 1.75,
                  ),
                  itemBuilder: (context, index) {
                    final slot = currentSlots[index];
                    final isSelected = _selectedTimeIndex == index;

                    Color bgColor;
                    Color borderColor;
                    Color titleColor;
                    Color subColor;
                    String statusLabel;

                    if (!slot.isAvailable) {
                      bgColor = colors.surfaceContainerLowest;
                      borderColor = colors.outlineVariant.withValues(alpha: 0.5);
                      titleColor =
                          colors.onSurfaceVariant.withValues(alpha: 0.6);
                      subColor = colors.onSurfaceVariant.withValues(alpha: 0.6);
                      statusLabel = 'Ocupado';
                    } else if (isSelected) {
                      bgColor = _brandGreen;
                      borderColor = _brandGreen;
                      titleColor = Colors.white;
                      subColor = Colors.white.withValues(alpha: 0.9);
                      statusLabel = 'Seleccionado';
                    } else {
                      bgColor = colors.surfaceContainerLowest;
                      borderColor = _brandGreen;
                      titleColor = _brandGreen;
                      subColor = _brandGreen;
                      statusLabel = 'Libre';
                    }

                    return InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: slot.isAvailable
                          ? () => setState(() => _selectedTimeIndex = index)
                          : null,
                      child: Container(
                        decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: borderColor, width: 1.2),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              slot.time,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                decoration: !slot.isAvailable
                                    ? TextDecoration.lineThrough
                                    : null,
                                color: titleColor,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              statusLabel,
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.w500,
                                color: subColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 6),
                Text(
                  'Duración: 30 min · Los ocupados no se pueden elegir.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 20),

                // 4. Motivo (opcional)
                Text(
                  'Motivo (opcional)',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _motivoController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Escribe brevemente el motivo de tu cita...',
                    hintStyle: theme.textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant.withValues(alpha: 0.7),
                    ),
                    filled: true,
                    fillColor: colors.surfaceContainerLowest,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: colors.outlineVariant.withValues(alpha: 0.5),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: colors.outlineVariant.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // 5. Resumen inferior y botón Confirmar cita
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      selectedDateObj!.labelDate,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      selectedSlotObj?.range ?? '--:--',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 50,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: _brandGreen,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: selectedSlotObj != null ? _confirmarCita : null,
                    child: const Text(
                      'Confirmar cita',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}