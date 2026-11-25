import 'package:material_ui/material_ui.dart';
import 'package:conecta_utsh/modules/solicitudes/models/solicitud_estado.dart';

class SolicitudEstadoChip extends StatelessWidget {
  const SolicitudEstadoChip({required this.estado, super.key});

  final SolicitudEstado estado;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final color = switch (estado) {
      SolicitudEstado.aceptada ||
      SolicitudEstado.finalizada ||
      SolicitudEstado.estadiaEnCurso => colors.primary,
      SolicitudEstado.rechazada => colors.error,
      SolicitudEstado.cancelada => colors.onSurfaceVariant,
      _ => colors.tertiary,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        estado.etiqueta,
        style: Theme.of(context).textTheme.labelSmall
            ?.copyWith(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}
