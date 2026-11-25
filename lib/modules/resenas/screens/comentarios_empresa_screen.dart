import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:conecta_utsh/helpers/style.dart';
import 'package:conecta_utsh/modules/resenas/components/comentario_card.dart';
import 'package:conecta_utsh/modules/resenas/components/resena_form_sheet.dart';
import 'package:conecta_utsh/modules/resenas/components/resumen_calificaciones.dart';
import 'package:conecta_utsh/modules/resenas/models/comentario_model.dart';
import 'package:conecta_utsh/modules/resenas/models/permiso_resena_model.dart';
import 'package:conecta_utsh/modules/resenas/models/resumen_model.dart';
import 'package:conecta_utsh/modules/resenas/services/resenas_service.dart';
import 'package:conecta_utsh/utils/widgets/dialogs.dart';

class ComentariosEmpresaScreen extends StatefulWidget {
  const ComentariosEmpresaScreen({
    required this.empresaId,
    required this.userRole,
    required this.service,
    super.key,
  });

  final String empresaId;
  final String userRole;
  final ResenasService service;

  @override
  State<ComentariosEmpresaScreen> createState() =>
      _ComentariosEmpresaScreenState();
}

class _ComentariosEmpresaScreenState extends State<ComentariosEmpresaScreen> {
  ResumenModel? _resumen;
  List<ComentarioModel> _comentarios = const [];
  PermisoResenaModel? _permiso;
  bool _isLoading = true;
  bool _hasLoaded = false;
  bool _creationConflict = false;
  String? _errorMessage;
  int _visibleCount = 5;

  bool get _isStudent => widget.userRole.trim().toLowerCase() == 'estudiante';

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<PermisoResenaModel?> _loadPermission() async {
    try {
      return await widget.service.puedeCalificar(widget.empresaId);
    } on ResenasApiException {
      return null;
    }
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }
    final permissionFuture = _loadPermission();
    try {
      final results = await Future.wait<Object>([
        widget.service.resumen(widget.empresaId),
        widget.service.listar(empresaId: widget.empresaId),
      ]);
      final permission = await permissionFuture;
      if (!mounted) return;
      setState(() {
        _resumen = results[0] as ResumenModel;
        _comentarios = (results[1] as ComentarioListResponse).comentarios;
        _permiso = permission;
        _hasLoaded = true;
        _isLoading = false;
        _visibleCount = 5;
      });
    } on ResenasApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = error.message;
      });
    }
  }

  Future<void> _openForm({ComentarioModel? comentario}) async {
    final result = await ResenaFormSheet.show(
      context,
      service: widget.service,
      empresaId: widget.empresaId,
      initialComentario: comentario,
      onConflict: () {
        if (mounted) {
          setState(() => _creationConflict = true);
          unawaited(_load());
        }
      },
    );
    if (result == null || !mounted) return;
    setState(() => _creationConflict = false);
    await _load();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          comentario == null ? 'Reseña publicada.' : 'Reseña actualizada.',
        ),
      ),
    );
  }

  Future<void> _delete(ComentarioModel comentario) async {
    final confirmed = await Dialogs.showConfirmDialogDelete(
      context,
      title: 'Eliminar reseña',
      message: 'Tu reseña dejará de estar visible. No podrás publicar otra para esta empresa.',
      icon: Icons.delete_outline_rounded,
      confirmText: 'Eliminar',
      cancelText: 'Cancelar',
      confirmColor: Theme.of(context).colorScheme.error,
      cancelColor: Theme.of(context).colorScheme.surfaceContainerHigh,
    );
    if (confirmed != true) return;
    try {
      await widget.service.eliminar(comentario.id);
      if (!mounted) return;
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Reseña eliminada.')));
    } on ResenasApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    if (_isLoading && !_hasLoaded) {
      return Center(child: CircularProgressIndicator(color: colors.primary));
    }
    if (_errorMessage != null && !_hasLoaded) {
      return _buildError(context, _errorMessage!);
    }

    final permiso = _permiso;
    final ownReview = permiso?.comentarioId == null
        ? null
        : _findOwnReview(permiso!.comentarioId!);
    final otherReviews = _comentarios
        .where((review) => review.id != permiso?.comentarioId)
        .toList(growable: false);
    final shownReviews = otherReviews.take(_visibleCount).toList();
    final hasMore = shownReviews.length < otherReviews.length;

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
        children: [
          if (_isLoading) const LinearProgressIndicator(),
          if (_errorMessage != null)
            _InlineError(message: _errorMessage!, onRetry: _load),
          if (_resumen != null) ResumenCalificaciones(resumen: _resumen!),
          if (_resumen == null && _hasLoaded)
            Text(
              'No hay calificaciones disponibles.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          if (_isStudent) ...[
            const SizedBox(height: 12),
            _buildAction(context, permiso),
          ],
          const SizedBox(height: 14),
          if (ownReview != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ComentarioCard(
                comentario: ownReview,
                onEditar: ownReview.visible
                    ? () => _openForm(comentario: ownReview)
                    : null,
                onEliminar: ownReview.visible ? () => _delete(ownReview) : null,
              ),
            ),
          if (otherReviews.isEmpty && ownReview == null && _hasLoaded)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 22),
              child: Text(
                'Aún no hay reseñas',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ),
          for (final review in shownReviews) ...[
            ComentarioCard(comentario: review),
            const SizedBox(height: 12),
          ],
          if (hasMore)
            Center(
              child: TextButton(
                onPressed: () => setState(() => _visibleCount += 5),
                child: const Text('Ver más'),
              ),
            ),
        ],
      ),
    );
  }

  ComentarioModel? _findOwnReview(String id) {
    for (final review in _comentarios) {
      if (review.id == id) return review;
    }
    return null;
  }

  Widget _buildAction(BuildContext context, PermisoResenaModel? permiso) {
    final colors = Theme.of(context).colorScheme;
    if (_creationConflict) {
      return _InfoMessage(
        message: 'Ya tienes una reseña para esta empresa.',
        color: colors.errorContainer,
      );
    }
    if (permiso == null) return const SizedBox.shrink();
    if (permiso.tieneResena) {
      if (permiso.visible == false) {
        return _InfoMessage(
          message: [
            'Tu reseña está oculta.',
            if (permiso.motivo?.trim().isNotEmpty == true) permiso.motivo!,
          ].join('\n'),
          color: colors.errorContainer,
        );
      }
      if (permiso.visible == true) return const SizedBox.shrink();
      return const _InfoMessage(
        message: 'Ya tienes una reseña para esta empresa.',
      );
    }
    if (!permiso.estadiaFinalizada) {
      return const _InfoMessage(
        message: 'Podrás calificar cuando termines tu estadía',
      );
    }
    if (permiso.puedeCalificar) {
      return SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: () => _openForm(),
          icon: const Icon(Icons.rate_review_outlined),
          label: const Text('Dejar reseña'),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildError(BuildContext context, String message) {
    final colors = Theme.of(context).colorScheme;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: Style.getPaddingSymmetric(horizontal: 28, vertical: 36),
      children: [
        const SizedBox(height: 70),
        Icon(Icons.error_outline_rounded, color: colors.error, size: 42),
        const SizedBox(height: 12),
        Text(
          'No se pudieron cargar las reseñas.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 6),
        Text(message, textAlign: TextAlign.center),
        const SizedBox(height: 12),
        Center(
          child: FilledButton.tonal(
            onPressed: _load,
            child: const Text('Reintentar'),
          ),
        ),
      ],
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.errorContainer,
        borderRadius: Style.getCircularBorderRadius(12),
      ),
      child: Row(
        children: [
          Expanded(child: Text(message)),
          TextButton(onPressed: onRetry, child: const Text('Reintentar')),
        ],
      ),
    );
  }
}

class _InfoMessage extends StatelessWidget {
  const _InfoMessage({required this.message, this.color});

  final String message;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color ?? colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        message,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: color == null
              ? colors.onSurfaceVariant
              : colors.onErrorContainer,
        ),
      ),
    );
  }
}
