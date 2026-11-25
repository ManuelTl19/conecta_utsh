import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:conecta_utsh/modules/resenas/components/estrellas.dart';
import 'package:conecta_utsh/modules/resenas/models/comentario_model.dart';
import 'package:conecta_utsh/modules/resenas/services/resenas_service.dart';

class ResenaFormSheet extends StatefulWidget {
  const ResenaFormSheet({
    required this.service,
    required this.empresaId,
    this.initialComentario,
    this.onConflict,
    super.key,
  });

  final ResenasService service;
  final String empresaId;
  final ComentarioModel? initialComentario;
  final VoidCallback? onConflict;

  static Future<ComentarioModel?> show(
    BuildContext context, {
    required ResenasService service,
    required String empresaId,
    ComentarioModel? initialComentario,
    VoidCallback? onConflict,
  }) => showModalBottomSheet<ComentarioModel>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    builder: (_) => ResenaFormSheet(
      service: service,
      empresaId: empresaId,
      initialComentario: initialComentario,
      onConflict: onConflict,
    ),
  );

  @override
  State<ResenaFormSheet> createState() => _ResenaFormSheetState();
}

class _ResenaFormSheetState extends State<ResenaFormSheet> {
  late final TextEditingController _commentController;
  late int _rating;
  bool _isSaving = false;
  String? _errorMessage;

  bool get _isEditing => widget.initialComentario != null;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialComentario;
    _rating = initial?.calificacion ?? 0;
    _commentController = TextEditingController(text: initial?.comentario ?? '');
    _commentController.addListener(_clearError);
  }

  @override
  void dispose() {
    _commentController
      ..removeListener(_clearError)
      ..dispose();
    super.dispose();
  }

  void _clearError() {
    if (_errorMessage != null && mounted) {
      setState(() => _errorMessage = null);
    }
  }

  Future<void> _submit() async {
    final comment = _commentController.text;
    if (_rating < 1 || _rating > 5) {
      setState(() => _errorMessage = 'Selecciona una calificación de 1 a 5.');
      return;
    }
    if (comment.length > 1000) {
      setState(
        () => _errorMessage = 'El comentario no puede superar 1000 caracteres.',
      );
      return;
    }
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });
    try {
      final result = _isEditing
          ? await widget.service.actualizar(
              comentarioId: widget.initialComentario!.id,
              calificacion: _rating,
              comentario: comment,
            )
          : await widget.service.crear(
              empresaId: widget.empresaId,
              calificacion: _rating,
              comentario: comment,
            );
      if (mounted) Navigator.of(context).pop(result);
    } on ResenasApiException catch (error) {
      if (error.statusCode == 409) widget.onConflict?.call();
      if (mounted) setState(() => _errorMessage = error.message);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        8,
        20,
        MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isEditing ? 'Editar reseña' : 'Dejar reseña',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 14),
            Center(
              child: SelectorEstrellas(
                calificacion: _rating,
                enabled: !_isSaving,
                onChanged: (rating) => setState(() {
                  _rating = rating;
                  _errorMessage = null;
                }),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _commentController,
              enabled: !_isSaving,
              maxLength: 1000,
              maxLengthEnforcement: MaxLengthEnforcement.enforced,
              minLines: 3,
              maxLines: 6,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Comentario (opcional)',
                hintText: 'Comparte tu experiencia con esta empresa',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 4),
              Text(
                _errorMessage!,
                style: theme.textTheme.bodySmall?.copyWith(color: colors.error),
              ),
            ],
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _isSaving ? null : _submit,
                child: _isSaving
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colors.onPrimary,
                        ),
                      )
                    : Text(_isEditing ? 'Guardar cambios' : 'Publicar reseña'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
