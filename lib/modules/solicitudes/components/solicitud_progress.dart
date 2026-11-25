import 'package:material_ui/material_ui.dart';
import 'package:conecta_utsh/modules/solicitudes/models/solicitud_estado.dart';

class SolicitudProgress extends StatelessWidget {
  const SolicitudProgress({required this.estado, super.key});

  final SolicitudEstado estado;

  static const _steps = [
    SolicitudEstado.registrada,
    SolicitudEstado.enProceso,
    SolicitudEstado.aceptada,
    SolicitudEstado.documentacionPendiente,
    SolicitudEstado.estadiaEnCurso,
    SolicitudEstado.finalizada,
  ];

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final currentIndex = _steps.indexOf(estado);
    final terminal =
        estado == SolicitudEstado.rechazada ||
        estado == SolicitudEstado.cancelada;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var index = 0; index < _steps.length; index++)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 24,
                child: Column(
                  children: [
                    Icon(
                      index < currentIndex
                          ? Icons.check_circle
                          : index == currentIndex
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                      size: 19,
                      color: index <= currentIndex
                          ? colors.primary
                          : colors.outlineVariant,
                    ),
                    if (index < _steps.length - 1)
                      Container(
                        width: 2,
                        height: 20,
                        color: index < currentIndex
                            ? colors.primary
                            : colors.outlineVariant,
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(top: 1),
                child: Text(
                  _steps[index].etiqueta,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: index <= currentIndex
                        ? colors.onSurface
                        : colors.onSurfaceVariant,
                    fontWeight: index == currentIndex
                        ? FontWeight.w700
                        : FontWeight.normal,
                  ),
                ),
              ),
            ],
          ),
        if (terminal) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                estado == SolicitudEstado.rechazada
                    ? Icons.cancel_outlined
                    : Icons.block_outlined,
                size: 19,
                color: colors.error,
              ),
              const SizedBox(width: 8),
              Text(
                estado.etiqueta,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colors.error,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
