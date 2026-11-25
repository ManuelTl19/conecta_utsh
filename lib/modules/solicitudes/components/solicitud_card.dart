import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:conecta_utsh/modules/solicitudes/components/solicitud_estado_chip.dart';
import 'package:conecta_utsh/modules/solicitudes/models/solicitud_model.dart';

class SolicitudCard extends StatelessWidget {
  const SolicitudCard({
    required this.solicitud,
    this.onTap,
    this.onCancelar,
    super.key,
  });

  final SolicitudModel solicitud;
  final VoidCallback? onTap;
  final VoidCallback? onCancelar;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: colors.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: colors.outlineVariant),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      solicitud.empresa.name?.trim().isNotEmpty == true
                          ? solicitud.empresa.name!
                          : 'Empresa no disponible',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  SolicitudEstadoChip(estado: solicitud.estado),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                solicitud.origen?.etiqueta ?? 'Origen no especificado',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              if (solicitud.observaciones.trim().isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  solicitud.observaciones,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Text(
                'Registrada el ${DateFormat('dd/MM/yyyy').format(solicitud.fechaRegistro.toLocal())}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              if (onCancelar != null) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: onCancelar,
                    icon: const Icon(Icons.cancel_outlined),
                    label: const Text('Cancelar solicitud'),
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
