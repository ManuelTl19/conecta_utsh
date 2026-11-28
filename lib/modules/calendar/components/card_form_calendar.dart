import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:conecta_utsh/helpers/style.dart';
import 'package:conecta_utsh/modules/app/components/step_indicator.dart';
import 'package:conecta_utsh/utils/widgets/dialogs.dart';
import 'package:conecta_utsh/modules/calendar/models/appointment_model.dart';
import 'package:conecta_utsh/modules/calendar/models/availability_model.dart';
import 'package:conecta_utsh/modules/calendar/service/citas_service.dart';

class CardFormCalendar extends StatefulWidget {
  const CardFormCalendar({
    super.key,
    required this.citasService,
    this.startHour = 9,
    this.endHour = 14,
    this.intervalMinutes = 10,
  });

  final CitasService citasService;
  final int startHour;
  final int endHour;
  final int intervalMinutes;

  @override
  State<CardFormCalendar> createState() => _CardFormCalendarState();
}

class _CardFormCalendarState extends State<CardFormCalendar> {
  Color get _brandGreen => Style.getPrimaryColor();

  static const Map<String, int> _diaAWeekday = {
    'lunes': DateTime.monday,
    'martes': DateTime.tuesday,
    'miércoles': DateTime.wednesday,
    'miercoles': DateTime.wednesday,
    'jueves': DateTime.thursday,
    'viernes': DateTime.friday,
    'sábado': DateTime.saturday,
    'sabado': DateTime.saturday,
    'domingo': DateTime.sunday,
  };

  bool _isLoadingOpciones = true;
  String? _opcionesError;

  String? _selectedDireccion;
  DirectionAvailabilityModel _currentAvailability = DirectionAvailabilityModel(
    direccion: '',
    hasAttention: false,
    attentionSchedule: 'Cargando horarios...',
    availableDates: [],
  );

  int _currentStep = 0; // 0: Fecha y Hora, 1: Motivo y Resumen
  int _selectedDateIndex = 0;
  int _selectedTimeIndex = -1;
  int _selectedHourFilter = 9;
  bool _isLoadingAvailability = false;
  String? _availabilityError;
  int _availabilityRequestVersion = 0;
  bool _isSubmitting = false;
  bool _motivoInvalid = false;
  final TextEditingController _motivoController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedHourFilter = widget.startHour;
    unawaited(_cargarOpcionesAcademicas());
  }

  Future<void> _cargarOpcionesAcademicas() async {
    setState(() {
      _isLoadingOpciones = true;
      _opcionesError = null;
    });

    try {
      final opciones = await widget.citasService.obtenerOpcionesAcademicas();
      if (!mounted) return;

      setState(() {
        _isLoadingOpciones = false;
      });

      if (opciones.isNotEmpty) {
        _seleccionarDireccion(opciones.first);
      } else {
        setState(() {
          _currentAvailability = DirectionAvailabilityModel(
            direccion: '',
            hasAttention: false,
            attentionSchedule: '',
            noAttentionMessage:
                'Tu dirección académica no tiene agenda activa en este momento.',
            availableDates: [],
          );
        });
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _opcionesError = error.toString();
        _isLoadingOpciones = false;
      });
    }
  }

  void _seleccionarDireccion(OpcionAcademicaModel opcion) {
    final dates = _proximasFechasParaDias(opcion.diasSemana);
    setState(() {
      _selectedDireccion = opcion.direccion;
      _selectedDateIndex = 0;
      _selectedTimeIndex = -1;
      _currentAvailability = DirectionAvailabilityModel(
        direccion: opcion.direccion,
        hasAttention: dates.isNotEmpty,
        attentionSchedule: opcion.descripcionHorario,
        noAttentionMessage:
            'Tu dirección académica no tiene días de atención configurados.',
        availableDates: dates,
      );
    });

    if (dates.isNotEmpty) {
      unawaited(_loadAvailabilityFor(0));
    }
  }

  List<AvailableDateModel> _proximasFechasParaDias(List<String> diasSemana) {
    final weekdaysPermitidos = diasSemana
        .map((d) => _diaAWeekday[d.toLowerCase().trim()])
        .whereType<int>()
        .toSet();

    if (weekdaysPermitidos.isEmpty) return [];

    final now = DateTime.now();
    var date = DateTime(now.year, now.month, now.day);
    final dates = <AvailableDateModel>[];

    for (int i = 0; i < 60 && dates.length < 5; i++) {
      if (weekdaysPermitidos.contains(date.weekday)) {
        final rawDate =
            '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        dates.add(
          AvailableDateModel.fromJson({'fecha': rawDate, 'horarios': []}),
        );
      }
      date = date.add(const Duration(days: 1));
    }
    return dates;
  }

  Future<void> _loadAvailabilityFor(int dateIndex) async {
    if (dateIndex < 0 ||
        dateIndex >= _currentAvailability.availableDates.length) {
      return;
    }

    final requestVersion = ++_availabilityRequestVersion;
    final date = _currentAvailability.availableDates[dateIndex];
    final parts = date.rawDate.split('-');
    final requestedDate = DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
    setState(() {
      _isLoadingAvailability = true;
      _availabilityError = null;
      _selectedTimeIndex = -1;
    });

    try {
      final result = await widget.citasService.obtenerHorariosDisponibles(
        requestedDate,
        direccion: _selectedDireccion,
      );
      if (!mounted || requestVersion != _availabilityRequestVersion) return;
      final dates = [..._currentAvailability.availableDates];
      dates[dateIndex] = result;
      setState(() {
        _currentAvailability = DirectionAvailabilityModel(
          direccion: _currentAvailability.direccion,
          hasAttention: _currentAvailability.hasAttention,
          attentionSchedule: _currentAvailability.attentionSchedule,
          noAttentionMessage: _currentAvailability.noAttentionMessage,
          availableDates: dates,
        );
        _selectedTimeIndex = result.slots.indexWhere(
          (slot) => slot.isAvailable,
        );
        if (_selectedTimeIndex >= 0) {
          final hour = int.tryParse(
            result.slots[_selectedTimeIndex].time.split(':').first,
          );
          if (hour != null) _selectedHourFilter = hour;
        } else if (result.slots.isNotEmpty) {
          final firstHour = int.tryParse(
            result.slots.first.time.split(':').first,
          );
          if (firstHour != null) _selectedHourFilter = firstHour;
        }
        _isLoadingAvailability = false;
      });
    } catch (error) {
      if (!mounted || requestVersion != _availabilityRequestVersion) return;
      setState(() {
        _availabilityError = error.toString();
        _isLoadingAvailability = false;
      });
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
    final timeParts = slotObj.time.split(':');
    final fechaHora = DateTime(
      int.parse(fechaObj.rawDate.substring(0, 4)),
      int.parse(fechaObj.rawDate.substring(5, 7)),
      int.parse(fechaObj.rawDate.substring(8, 10)),
      int.parse(timeParts[0]),
      int.parse(timeParts[1]),
    );
    final motivo = _motivoController.text.trim();

    if (motivo.isEmpty) {
      setState(() => _motivoInvalid = true);
      await Dialogs.showInfoDialog(
        context,
        title: 'Completa los campos',
        message: 'Escribe el motivo de atención para poder solicitar la cita.',
        icon: Icons.error_outline_rounded,
        color: Style.getErrorColor(),
      );
      return;
    }
    if (_motivoInvalid) setState(() => _motivoInvalid = false);
    if (!fechaHora.isAfter(DateTime.now())) {
      await Dialogs.showInfoDialog(
        context,
        title: 'Selecciona otro horario',
        message: 'La fecha y hora de la cita deben ser futuras.',
        icon: Icons.event_busy_outlined,
        color: Style.getErrorColor(),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    late final AppointmentModel nuevaCita;
    try {
      nuevaCita = await widget.citasService.crearCita(
        fechaHora: fechaHora,
        motivo: motivo,
        direccion: _selectedDireccion,
      );
    } catch (error) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo agendar la cita: $error')),
        );
      }
      return;
    }

    if (!mounted) return;
    await Dialogs.showSimpleDialog(
      context,
      title: '¡Solicitud enviada!',
      message:
          'Tu cita para ${nuevaCita.date} a las ${nuevaCita.time} h ha sido registrada.',
      icon: Icons.check_circle_outline_rounded,
      color: Style.getSuccessColor(),
    );

    if (mounted) {
      Navigator.of(context).pop(nuevaCita);
    }
  }

  String get _stepSubtitle {
    switch (_currentStep) {
      case 0:
        return 'Paso 1 de 2 · Elige fecha y horario';
      default:
        return 'Paso 2 de 2 · Confirma los detalles';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final hasDates =
        _currentAvailability.hasAttention &&
        _currentAvailability.availableDates.isNotEmpty;

    final selectedDateObj = hasDates
        ? _currentAvailability.availableDates[_selectedDateIndex]
        : null;
    final currentSlots = selectedDateObj?.slots ?? [];
    final selectedSlotObj =
        (_selectedTimeIndex >= 0 && _selectedTimeIndex < currentSlots.length)
        ? currentSlots[_selectedTimeIndex]
        : null;

    final bool canGoNext = _currentStep == 0
        ? (hasDates &&
            !_isLoadingOpciones &&
            selectedDateObj != null &&
            selectedSlotObj != null)
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
                      style: Style.getHeaderOne(
                        color: Style.getTextColor(),
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _stepSubtitle,
                      style: Style.getTextStyle(
                        color: Style.getObscureTextColor(),
                        fontSize: 10,
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

            StepIndicator(step: _currentStep, stepCount: 2),
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
                          borderRadius: Style.getButtonBorderRadius(),
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
                        borderRadius: Style.getButtonBorderRadius(),
                      ),
                    ),
                    onPressed: canGoNext && !_isSubmitting
                        ? () {
                            if (_currentStep < 1) {
                              setState(() => _currentStep++);
                            } else {
                              _confirmarCita();
                            }
                          }
                        : null,
                    child: _isSubmitting
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Style.getInverseTextColor(),
                            ),
                          )
                        : Text(
                            _currentStep < 1 ? 'Siguiente' : 'Confirmar cita',
                            style: Style.getHeaderThree(
                              color: Style.getInverseTextColor(),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
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
    // PASO 1: FECHA Y HORARIO (CON DIRECCIÓN ASIGNADA INFORMATIVA)
    if (_currentStep == 0) {
      if (_isLoadingOpciones) {
        return const Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        );
      }

      if (_opcionesError != null) {
        return Column(
          children: [
            Text(
              'No se pudo cargar tu agenda académica: $_opcionesError',
              style: Style.getTextStyle(
                color: Style.getErrorColor(),
                fontSize: 11,
              ),
            ),
            TextButton(
              onPressed: () => unawaited(_cargarOpcionesAcademicas()),
              child: const Text('Intentar de nuevo'),
            ),
          ],
        );
      }

      if (!hasDates) {
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colors.errorContainer.withValues(alpha: 0.35),
            borderRadius: Style.getCircularBorderRadius(12),
            border: Border.all(
              color: colors.error.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.event_busy_rounded,
                color: colors.error,
                size: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _currentAvailability.noAttentionMessage ??
                      'Sin fechas disponibles para tu dirección académica.',
                  style: Style.getTextStyle(
                    color: Style.getTextColor(),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        );
      }

      final dynamicHours = currentSlots
          .map((s) => int.tryParse(s.time.split(':').first))
          .whereType<int>()
          .toSet()
          .toList()
        ..sort();

      final hours = dynamicHours.isNotEmpty
          ? dynamicHours
          : List.generate(
              widget.endHour - widget.startHour,
              (i) => widget.startHour + i,
            );

      final effectiveHourFilter = hours.contains(_selectedHourFilter)
          ? _selectedHourFilter
          : hours.first;

      final hourPrefix = '${effectiveHourFilter.toString().padLeft(2, '0')}:';
      final filteredSlots = currentSlots
          .asMap()
          .entries
          .where((entry) => entry.value.time.startsWith(hourPrefix))
          .toList();

      final rangoTexto = hours.isNotEmpty
          ? '${hours.first.toString().padLeft(2, '0')}:00 - ${(hours.last + 1).toString().padLeft(2, '0')}:00'
          : '${widget.startHour}:00 - ${widget.endHour}:00';

      return Column(
        key: const ValueKey('step_0'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Banner informativo de la dirección asignada al usuario
          if (_selectedDireccion != null && _selectedDireccion!.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: _brandGreen.withValues(alpha: 0.08),
                borderRadius: Style.getCircularBorderRadius(12),
                border: Border.all(
                  color: _brandGreen.withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.school_outlined,
                    color: _brandGreen,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedDireccion!,
                          style: Style.getHeaderThree(
                            color: Style.getTextColor(),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (_currentAvailability.attentionSchedule.isNotEmpty)
                          Text(
                            _currentAvailability.attentionSchedule,
                            style: Style.getTextStyle(
                              color: Style.getObscureTextColor(),
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],

          Text(
            '1. Fecha disponible · ${_currentAvailability.availableDates.isEmpty ? DateTime.now().year : _currentAvailability.availableDates[_selectedDateIndex].rawDate.substring(0, 4)}',
            style: Style.getHeaderThree(
              color: Style.getTextColor(),
              fontSize: 13,
              fontWeight: FontWeight.w700,
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
                      right:
                          index < _currentAvailability.availableDates.length - 1
                          ? 10
                          : 0,
                    ),
                    child: InkWell(
                      borderRadius: Style.getCircularBorderRadius(12),
                      onTap: () {
                        setState(() {
                          _selectedDateIndex = index;
                          _selectedTimeIndex = -1;
                        });
                        unawaited(_loadAvailabilityFor(index));
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? _brandGreen
                              : colors.surfaceContainerLowest,
                          borderRadius: Style.getCircularBorderRadius(12),
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
                              style: Style.getHeaderThree(
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                                color: isSelected
                                    ? Style.getInverseTextColor()
                                    : Style.getTextColor(),
                              ),
                            ),
                            Text(
                              item.dayName,
                              style: Style.getHeaderThree(
                                fontSize: 9,
                                color: isSelected
                                    ? Style.getInverseTextColor().withValues(
                                        alpha: 0.9,
                                      )
                                    : Style.getObscureTextColor(),
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
                '2. Hora ($rangoTexto)',
                style: Style.getHeaderThree(
                  color: Style.getTextColor(),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (selectedSlotObj != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: _brandGreen.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Elegido: ${selectedSlotObj.time} h',
                    style: Style.getHeaderThree(
                      fontWeight: FontWeight.w700,
                      color: _brandGreen,
                      fontSize: 10,
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
                final isHourSelected = effectiveHourFilter == hour;
                final label = '${hour.toString().padLeft(2, '0')}:00';

                final prefix = '${hour.toString().padLeft(2, '0')}:';
                final hasFreeSlot = currentSlots.any(
                  (s) => s.time.startsWith(prefix) && s.isAvailable,
                );

                return ChoiceChip(
                  label: Text(label),
                  selected: isHourSelected,
                  selectedColor: _brandGreen,
                  labelStyle: Style.getHeaderThree(
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                    color: isHourSelected
                        ? Style.getInverseTextColor()
                        : hasFreeSlot
                        ? Style.getTextColor()
                        : Style.getObscureTextColor().withValues(alpha: 0.4),
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
          if (_isLoadingAvailability)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_availabilityError != null)
            Column(
              children: [
                Text(
                  'No se pudieron cargar los horarios: $_availabilityError',
                  style: Style.getTextStyle(
                    color: Style.getErrorColor(),
                    fontSize: 11,
                  ),
                ),
                TextButton(
                  onPressed: () =>
                      unawaited(_loadAvailabilityFor(_selectedDateIndex)),
                  child: const Text('Intentar de nuevo'),
                ),
              ],
            )
          else if (currentSlots.isEmpty)
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text('No hay horarios disponibles para esta fecha.'),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: filteredSlots.map((entry) {
                final globalIndex = entry.key;
                final slot = entry.value;
                final isSelected = _selectedTimeIndex == globalIndex;

                return InkWell(
                  borderRadius: Style.getCircularBorderRadius(10),
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
                      borderRadius: Style.getCircularBorderRadius(10),
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
                          style: Style.getHeaderThree(
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                            decoration: !slot.isAvailable
                                ? TextDecoration.lineThrough
                                : null,
                            color: !slot.isAvailable
                                ? colors.onSurfaceVariant.withValues(
                                    alpha: 0.45,
                                  )
                                : isSelected
                                ? Style.getInverseTextColor()
                                : _brandGreen,
                          ),
                        ),
                        Text(
                          !slot.isAvailable ? 'Ocupado' : 'Disponible',
                          style: Style.getHeaderThree(
                            fontSize: 9,
                            color: !slot.isAvailable
                                ? colors.onSurfaceVariant.withValues(
                                    alpha: 0.45,
                                  )
                                : isSelected
                                ? Style.getInverseTextColor().withValues(
                                    alpha: 0.9,
                                  )
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

    // PASO 2: MOTIVO Y RESUMEN DE CONFIRMACIÓN
    return Column(
      key: const ValueKey('step_1'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colors.surfaceContainerLow,
            borderRadius: Style.getCircularBorderRadius(12),
            border: Border.all(color: colors.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Resumen de la solicitud',
                style: Style.getHeaderThree(
                  fontWeight: FontWeight.w700,
                  color: _brandGreen,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 8),
              if (_selectedDireccion != null &&
                  _selectedDireccion!.isNotEmpty) ...[
                Text(
                  _selectedDireccion!,
                  style: Style.getHeaderThree(
                    fontWeight: FontWeight.w700,
                    color: Style.getTextColor(),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
              ],
              if (selectedDateObj != null && selectedSlotObj != null)
                Text(
                  '${selectedDateObj.dayName} ${selectedDateObj.labelDate} · ${selectedSlotObj.time} h',
                  style: Style.getTextStyle(
                    color: Style.getObscureTextColor(),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'Motivo de atención',
          style: Style.getHeaderThree(
            color: Style.getTextColor(),
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _motivoController,
          maxLines: 4,
          maxLength: 250,
          onChanged: (_) {
            if (_motivoInvalid && _motivoController.text.trim().isNotEmpty) {
              setState(() => _motivoInvalid = false);
            }
          },
          decoration: InputDecoration(
            hintText: 'Describe brevemente el motivo de tu cita...',
            hintStyle: Style.getTextStyle(
              color: Style.getObscureTextColor(),
              fontSize: 11,
            ),
            filled: true,
            fillColor: colors.surfaceContainerLowest,
            errorText: _motivoInvalid
                ? 'Este campo es obligatorio'
                : null,
            border: OutlineInputBorder(
              borderRadius: Style.getCircularBorderRadius(12),
              borderSide: BorderSide(
                color: colors.outlineVariant.withValues(alpha: 0.6),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: Style.getCircularBorderRadius(12),
              borderSide: BorderSide(
                color: colors.outlineVariant.withValues(alpha: 0.6),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: Style.getCircularBorderRadius(12),
              borderSide: BorderSide(color: _brandGreen, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}