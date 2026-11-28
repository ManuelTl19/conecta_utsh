import 'package:material_ui/material_ui.dart';
import 'package:conecta_utsh/helpers/style.dart';
import 'package:conecta_utsh/modules/app/components/quick_menu.dart';
import 'package:conecta_utsh/modules/calendar/components/card_form_calendar.dart';
import 'package:conecta_utsh/modules/calendar/models/appointment_model.dart';
import 'package:conecta_utsh/modules/calendar/models/availability_model.dart';
import 'package:conecta_utsh/modules/calendar/service/citas_service.dart';
import 'package:conecta_utsh/utils/widgets/dialogs.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen>
    with AutomaticKeepAliveClientMixin<CalendarScreen> {
  Color get _brandGreen => Style.getPrimaryColor();

  late DateTime _today;
  late DateTime _selectedDate;
  late DateTime _focusedMonth;
  String? _selectedSlot;
  late final CitasService _citasService;
  List<AppointmentModel> _myAppointments = [];
  final Set<String> _cancellingAppointmentIds = {};
  bool _isLoadingAppointments = true;
  String? _appointmentsError;

  // Horarios usando el modelo TimeSlotModel
  final _timeSlots = [
    TimeSlotModel(time: '09:00 AM', range: '09:00–09:30 AM', isAvailable: true),
    TimeSlotModel(
      time: '10:00 AM',
      range: '10:00–10:30 AM',
      isAvailable: false,
    ),
    TimeSlotModel(time: '11:00 AM', range: '11:00–11:30 AM', isAvailable: true),
    TimeSlotModel(
      time: '12:00 PM',
      range: '12:00–12:30 PM',
      isAvailable: false,
    ),
    TimeSlotModel(time: '01:00 PM', range: '01:00–01:30 PM', isAvailable: true),
    TimeSlotModel(time: '02:00 PM', range: '02:00–02:30 PM', isAvailable: true),
    TimeSlotModel(
      time: '03:00 PM',
      range: '03:00–03:30 PM',
      isAvailable: false,
    ),
    TimeSlotModel(time: '04:00 PM', range: '04:00–04:30 PM', isAvailable: true),
  ];

  /// Si la fecha cae en sábado o domingo, avanza al siguiente lunes hábil
  DateTime _nextBusinessDay(DateTime date) {
    var d = DateTime(date.year, date.month, date.day);
    while (d.weekday == DateTime.saturday || d.weekday == DateTime.sunday) {
      d = d.add(const Duration(days: 1));
    }
    return d;
  }

  @override
  void initState() {
    super.initState();
    _citasService = CitasService();
    _loadMyAppointments();
    final now = DateTime.now();
    _today = DateTime(now.year, now.month, now.day);
    _selectedDate = _nextBusinessDay(_today);
    _focusedMonth = DateTime(_selectedDate.year, _selectedDate.month, 1);
  }

  @override
  bool get wantKeepAlive => true;

  Future<void> _loadMyAppointments() async {
    try {
      final appointments = await _citasService.obtenerMisCitas();
      if (!mounted) return;
      setState(() {
        _myAppointments = appointments;
        _appointmentsError = null;
        _isLoadingAppointments = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _appointmentsError = error.toString();
        _isLoadingAppointments = false;
      });
    }
  }

  Future<void> _cancelAppointment(AppointmentModel appointment) async {
    final id = appointment.id;
    if (id == null) return;

    final confirmed = await Dialogs.showConfirmDialogDelete(
      context,
      title: 'Cancelar cita',
      message: '¿Quieres cancelar esta cita?',
      icon: Icons.event_busy_outlined,
      confirmText: 'Cancelar cita',
      cancelText: 'Volver',
      confirmColor: Style.getErrorColor(),
      cancelColor: Style.getSecondaryColor(),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _cancellingAppointmentIds.add(id));
    try {
      final cancelledAppointment = await _citasService.cancelarCita(id);
      if (!mounted) return;
      setState(() {
        final index = _myAppointments.indexWhere((item) => item.id == id);
        if (index >= 0) _myAppointments[index] = cancelledAppointment;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La cita se canceló correctamente.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo cancelar la cita: $error')),
      );
    } finally {
      if (mounted) setState(() => _cancellingAppointmentIds.remove(id));
    }
  }

  @override
  void dispose() {
    _citasService.close();
    super.dispose();
  }

  /// Convierte textos como '18 nov' o '25 nov' en un DateTime para marcarlo en el calendario
  DateTime? _parseAppointmentDate(String labelDate) {
    const meses = {
      'ene': 1,
      'feb': 2,
      'mar': 3,
      'abr': 4,
      'may': 5,
      'jun': 6,
      'jul': 7,
      'ago': 8,
      'sep': 9,
      'oct': 10,
      'nov': 11,
      'dic': 12,
    };

    final parts = labelDate.trim().toLowerCase().split(' ');
    if (parts.length < 2) return null;

    final day = int.tryParse(parts[0]);
    final month = meses[parts[1].substring(0, 3)];
    if (day == null || month == null) return null;

    return DateTime(_today.year, month, day);
  }

  /// Conjunto de fechas agendadas normalizadas (año, mes, día)
  Set<DateTime> get _scheduledDates {
    final dates = <DateTime>{};
    for (final cita in _myAppointments) {
      final parsed = cita.fechaHora == null
          ? _parseAppointmentDate(cita.date)
          : DateTime(
              cita.fechaHora!.year,
              cita.fechaHora!.month,
              cita.fechaHora!.day,
            );
      if (parsed != null) {
        dates.add(parsed);
      }
    }
    return dates;
  }

  Future<void> _openScheduleForm() async {
    final nuevaCita = await showModalBottomSheet<AppointmentModel>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      shape: RoundedRectangleBorder(
        borderRadius: Style.getVerticalBorderRadius(top: 24, bottom: 0),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: FractionallySizedBox(
            heightFactor: 0.84,
            child: CardFormCalendar(citasService: _citasService),
          ),
        );
      },
    );

    if (nuevaCita != null && mounted) {
      final parsedDate = _parseAppointmentDate(nuevaCita.date);
      setState(() {
        _myAppointments.insert(0, nuevaCita);
        if (parsedDate != null &&
            !parsedDate.isBefore(_today) &&
            parsedDate.weekday != DateTime.saturday &&
            parsedDate.weekday != DateTime.sunday) {
          _selectedDate = parsedDate;
          _focusedMonth = DateTime(parsedDate.year, parsedDate.month, 1);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final scheduledDates = _scheduledDates;

    return SizedBox.expand(
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Encabezado y acceso para agendar
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Calendario',
                      style: Style.getHeaderOne(
                        color: Style.getTextColor(),
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: _openScheduleForm,
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Agendar'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Style.getPrimaryColor(),
                      foregroundColor: Style.getInverseTextColor(),
                      textStyle: Style.getHeaderThree(
                        color: Style.getInverseTextColor(),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: Style.getButtonBorderRadius(),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 2. Calendario mensual con días pasados y fines de semana bloqueados
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: Style.getCircularBorderRadius(16),
                side: BorderSide(color: colors.outlineVariant),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    _MonthlyAppointmentCalendar(
                      today: _today,
                      selectedDate: _selectedDate,
                      focusedMonth: _focusedMonth,
                      scheduledDates: scheduledDates,
                      brandColor: _brandGreen,
                      onMonthChanged: (newMonth) {
                        setState(() => _focusedMonth = newMonth);
                      },
                      onDateSelected: (newDate) {
                        setState(() {
                          _selectedDate = newDate;
                          _selectedSlot = null;
                        });
                      },
                    ),
                    const Divider(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        _LegendDot(
                          color: colors.primary,
                          label: 'Seleccionado',
                        ),
                        const SizedBox(width: 14),
                        _LegendDot(color: _brandGreen, label: 'Con cita'),
                      ],
                    ),
                  ],
                ),
              ),
            ),



            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Divider(),
            ),

            // 4. Apartado "Mis citas"
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
              child: Text(
                'Mis citas',
                style: Style.getHeaderTwo(
                  color: Style.getTextColor(),
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (_isLoadingAppointments)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_appointmentsError != null)
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(
                      'No se pudieron cargar tus citas: $_appointmentsError',
                      textAlign: TextAlign.center,
                      style: Style.getTextStyle(
                        color: Style.getErrorColor(),
                        fontSize: 12,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _isLoadingAppointments = true;
                          _appointmentsError = null;
                        });
                        _loadMyAppointments();
                      },
                      child: const Text('Intentar de nuevo'),
                    ),
                  ],
                ),
              )
            else if (_myAppointments.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  children: [
                    Icon(
                      Icons.event_available_outlined,
                      size: 40,
                      color: colors.onSurfaceVariant,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No tienes citas agendadas.',
                      style: Style.getTextStyle(
                        color: Style.getObscureTextColor(),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _myAppointments.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final cita = _myAppointments[index];
                  final statusColor = switch (cita.status) {
                    'Confirmada' => Style.getSuccessColor(),
                    'Cancelada' => Style.getErrorColor(),
                    'Completada' => Style.getInfoColor(),
                    _ => Style.getWarningColor(),
                  };
                  final canCancel =
                      cita.id != null &&
                      (cita.status == 'Pendiente' ||
                          cita.status == 'Confirmada');
                  final isCancelling =
                      cita.id != null &&
                      _cancellingAppointmentIds.contains(cita.id);

                  return Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: Style.getCircularBorderRadius(14),
                      side: BorderSide(color: colors.outlineVariant),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                          leading: CircleAvatar(
                            backgroundColor: colors.primaryContainer,
                            child: Icon(
                              Icons.calendar_today_rounded,
                              size: 20,
                              color: colors.onPrimaryContainer,
                            ),
                          ),
                          title: Text(
                            cita.title,
                            style: Style.getHeaderThree(
                              color: Style.getTextColor(),
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          subtitle: Text(
                            '${cita.direccion} • ${cita.date} (${cita.time})',
                            style: Style.getTextStyle(
                              color: Style.getObscureTextColor(),
                              fontSize: 11,
                            ),
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.15),
                              borderRadius: Style.getCircularBorderRadius(20),
                            ),
                            child: Text(
                              cita.status,
                              style: Style.getHeaderThree(
                                fontWeight: FontWeight.w700,
                                color: statusColor,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ),
                        if (canCancel)
                          Align(
                            alignment: Alignment.centerRight,
                            child: Padding(
                              padding: const EdgeInsets.only(
                                right: 12,
                                bottom: 8,
                              ),
                              child: TextButton.icon(
                                onPressed: isCancelling
                                    ? null
                                    : () => _cancelAppointment(cita),
                                icon: isCancelling
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(Icons.event_busy_outlined),
                                label: Text(
                                  isCancelling
                                      ? 'Cancelando...'
                                      : 'Cancelar cita',
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            SizedBox(height: QuickMenu.reservedHeight(context) + 8),
          ],
        ),
      ),
    );
  }
}

class _MonthlyAppointmentCalendar extends StatelessWidget {
  const _MonthlyAppointmentCalendar({
    required this.today,
    required this.selectedDate,
    required this.focusedMonth,
    required this.scheduledDates,
    required this.brandColor,
    required this.onMonthChanged,
    required this.onDateSelected,
  });

  final DateTime today;
  final DateTime selectedDate;
  final DateTime focusedMonth;
  final Set<DateTime> scheduledDates;
  final Color brandColor;
  final ValueChanged<DateTime> onMonthChanged;
  final ValueChanged<DateTime> onDateSelected;

  static const _monthNames = [
    'Enero',
    'Febrero',
    'Marzo',
    'Abril',
    'Mayo',
    'Junio',
    'Julio',
    'Agosto',
    'Septiembre',
    'Octubre',
    'Noviembre',
    'Diciembre',
  ];

  static const _weekDays = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final firstDayOfMonth = DateTime(focusedMonth.year, focusedMonth.month, 1);
    final daysInMonth = DateTime(
      focusedMonth.year,
      focusedMonth.month + 1,
      0,
    ).day;
    final startOffset = firstDayOfMonth.weekday - 1;
    final totalCells = startOffset + daysInMonth;

    final canGoPrevMonth =
        focusedMonth.year > today.year ||
        (focusedMonth.year == today.year && focusedMonth.month > today.month);

    return Column(
      children: [
        // Navegación de Mes y Año
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${_monthNames[focusedMonth.month - 1]} ${focusedMonth.year}',
              style: Style.getHeaderTwo(
                color: Style.getTextColor(),
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left_rounded),
                  onPressed: canGoPrevMonth
                      ? () => onMonthChanged(
                          DateTime(
                            focusedMonth.year,
                            focusedMonth.month - 1,
                            1,
                          ),
                        )
                      : null,
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right_rounded),
                  onPressed: () => onMonthChanged(
                    DateTime(focusedMonth.year, focusedMonth.month + 1, 1),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 6),

        // Cabecera de días de la semana (L M M J V S D)
        Row(
          children: List.generate(_weekDays.length, (i) {
            final isWeekendHeader = i >= 5; // S y D
            return Expanded(
              child: Center(
                child: Text(
                  _weekDays[i],
                  style: Style.getHeaderThree(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: isWeekendHeader
                        ? colors.onSurfaceVariant.withValues(alpha: 0.45)
                        : colors.onSurfaceVariant,
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 8),

        // Cuadrícula de días
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: totalCells,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
          ),
          itemBuilder: (context, index) {
            if (index < startOffset) {
              return const SizedBox.shrink();
            }

            final dayNumber = index - startOffset + 1;
            final cellDate = DateTime(
              focusedMonth.year,
              focusedMonth.month,
              dayNumber,
            );

            final isPast = cellDate.isBefore(today);
            final isWeekend =
                cellDate.weekday == DateTime.saturday ||
                cellDate.weekday == DateTime.sunday;
            final isDisabled = isPast || isWeekend;

            final isToday = _isSameDay(cellDate, today);
            final isSelected = _isSameDay(cellDate, selectedDate);
            final hasAppointment = scheduledDates.any(
              (d) => _isSameDay(d, cellDate),
            );

            Color? bgColor;
            Color textColor = colors.onSurface;
            BoxBorder? border;

            if (isDisabled) {
              textColor = colors.onSurfaceVariant.withValues(alpha: 0.35);
            } else if (isSelected) {
              bgColor = colors.primary;
              textColor = colors.onPrimary;
            } else if (hasAppointment) {
              bgColor = brandColor.withValues(alpha: 0.16);
              textColor = brandColor;
              border = Border.all(color: brandColor, width: 1.3);
            } else if (isToday) {
              border = Border.all(color: colors.primary, width: 1.2);
              textColor = colors.primary;
            }

            return InkWell(
              borderRadius: Style.getCircularBorderRadius(10),
              onTap: isDisabled ? null : () => onDateSelected(cellDate),
              child: Container(
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: Style.getCircularBorderRadius(10),
                  border: border,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$dayNumber',
                      style: Style.getTextStyle(
                        fontSize: 12,
                        fontWeight: (isSelected || hasAppointment || isToday)
                            ? FontWeight.w700
                            : FontWeight.w400,
                        color: textColor,
                      ),
                    ),
                    if (hasAppointment)
                      Container(
                        margin: const EdgeInsets.only(top: 2),
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          color: isSelected ? colors.onPrimary : brandColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: Style.getHeaderThree(
            color: Style.getObscureTextColor(),
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}
