import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:conecta_utsh/modules/resenas/components/estrellas.dart';
import 'package:conecta_utsh/modules/resenas/models/comentario_model.dart';

class ComentarioCard extends StatelessWidget {
  const ComentarioCard({
    required this.comentario,
    this.mostrarEmpresa = false,
    this.onEditar,
    this.onEliminar,
    super.key,
  });

  final ComentarioModel comentario;
  final bool mostrarEmpresa;
  final VoidCallback? onEditar;
  final VoidCallback? onEliminar;

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
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        comentario.estudiante.nombreCompleto.isEmpty
                            ? 'Estudiante'
                            : comentario.estudiante.nombreCompleto,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          Estrellas(
                            calificacion: comentario.calificacion.toDouble(),
                            size: 17,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            DateFormat('dd/MM/yyyy')
                                .format(comentario.fechaRegistro.toLocal()),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (!comentario.visible)
                  Padding(
                    padding: const EdgeInsets.only(right: 4, top: 2),
                    child: Chip(
                      label: const Text('Oculta'),
                      visualDensity: VisualDensity.compact,
                      backgroundColor: colors.errorContainer,
                      labelStyle: theme.textTheme.labelSmall?.copyWith(
                        color: colors.onErrorContainer,
                      ),
                    ),
                  ),
                if (onEditar != null || onEliminar != null)
                  PopupMenuButton<_ComentarioAction>(
                    tooltip: 'Opciones de reseña',
                    onSelected: (action) => action == _ComentarioAction.edit
                        ? onEditar?.call()
                        : onEliminar?.call(),
                    itemBuilder: (context) => [
                      if (onEditar != null)
                        const PopupMenuItem(
                          value: _ComentarioAction.edit,
                          child: Text('Editar'),
                        ),
                      if (onEliminar != null)
                        const PopupMenuItem(
                          value: _ComentarioAction.delete,
                          child: Text('Eliminar'),
                        ),
                    ],
                  ),
              ],
            ),
            if (mostrarEmpresa && comentario.empresa.nombre.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                comentario.empresa.nombre,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            if (comentario.comentario.trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                comentario.comentario,
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

enum _ComentarioAction { edit, delete }
