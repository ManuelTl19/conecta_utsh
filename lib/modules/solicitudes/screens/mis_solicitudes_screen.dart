import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:conecta_utsh/helpers/style.dart';
import 'package:conecta_utsh/modules/resenas/services/resenas_service.dart';
import 'package:conecta_utsh/modules/solicitudes/components/solicitud_card.dart';
import 'package:conecta_utsh/modules/solicitudes/models/solicitud_model.dart';
import 'package:conecta_utsh/modules/solicitudes/models/resumen_solicitudes_model.dart';
import 'package:conecta_utsh/modules/solicitudes/services/solicitudes_service.dart';
import 'package:conecta_utsh/modules/solicitudes/screens/solicitud_detalle_screen.dart';
import 'package:conecta_utsh/utils/widgets/dialogs.dart';

class MisSolicitudesScreen extends StatefulWidget {
  const MisSolicitudesScreen({
    required this.service,
    required this.resenasService,
    required this.userRole,
    this.onSolicitudesUpdated,
    super.key,
  });

  final SolicitudesService service;
  final ResenasService resenasService;
  final String userRole;
  final Future<void> Function()? onSolicitudesUpdated;

  @override
  State<MisSolicitudesScreen> createState() => _MisSolicitudesScreenState();
}

class _MisSolicitudesScreenState extends State<MisSolicitudesScreen> {
  SolicitudCollectionModel? _data;
  String? _errorMessage;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final result = await widget.service.misSolicitudes();
      if (!mounted) return;
      setState(() {
        _data = result;
        _isLoading = false;
      });
    } on SolicitudesApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.message;
        _isLoading = false;
      });
    }
  }

  Future<void> _openDetail(SolicitudModel solicitud) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => SolicitudDetalleScreen(
          solicitudId: solicitud.id,
          service: widget.service,
          resenasService: widget.resenasService,
          userRole: widget.userRole,
        ),
      ),
    );
    if (mounted) await _load();
  }

  Future<void> _cancel(SolicitudModel solicitud) async {
    final confirmed = await Dialogs.showConfirmDialogDelete(
      context,
      title: 'Cancelar solicitud',
      message:
          '¿Deseas cancelar la solicitud para ${solicitud.empresa.name ?? 'esta empresa'}?',
      icon: Icons.cancel_outlined,
      confirmText: 'Cancelar solicitud',
      cancelText: 'Volver',
      confirmColor: Theme.of(context).colorScheme.error,
      cancelColor: Theme.of(context).colorScheme.surfaceContainerHigh,
    );
    if (confirmed != true) return;
    try {
      final result = await widget.service.cancelar(solicitud.id);
      await _load();
      await widget.onSolicitudesUpdated?.call();
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(result.message)));
    } on SolicitudesApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(error.message)));
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        title: const Text('Mis solicitudes'),
        backgroundColor: colors.surface,
        foregroundColor: colors.onSurface,
        surfaceTintColor: Colors.transparent,
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    if (_isLoading && _data == null) {
      return Center(child: CircularProgressIndicator(color: colors.primary));
    }
    if (_errorMessage != null && _data == null) {
      return _buildError(context, _errorMessage!);
    }

    final data = _data;
    final requests = data?.solicitudes ?? const <SolicitudModel>[];
    final active = requests.where((item) => item.estado.esActiva).toList();
    final history = requests.where((item) => item.estado.esHistorial).toList();
    final summary = data?.resumen;

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
        children: [
          if (_isLoading) const LinearProgressIndicator(),
          if (_errorMessage != null)
            _InlineError(message: _errorMessage!, onRetry: _load),
          if (summary != null) ...[
            _SummaryCard(summary: summary),
            const SizedBox(height: 18),
          ],
          if (requests.isEmpty && !_isLoading)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 44),
              child: Column(
                children: [
                  Icon(
                    Icons.assignment_outlined,
                    size: 46,
                    color: colors.onSurfaceVariant,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Aún no tienes solicitudes',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          if (active.isNotEmpty) ...[
            Text(
              'Activas',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            for (final request in active) ...[
              SolicitudCard(
                solicitud: request,
                onTap: () => _openDetail(request),
                onCancelar: request.estado.puedeCancelarEstudiante
                    ? () => _cancel(request)
                    : null,
              ),
              const SizedBox(height: 10),
            ],
          ],
          if (history.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Historial',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            for (final request in history) ...[
              SolicitudCard(
                solicitud: request,
                onTap: () => _openDetail(request),
              ),
              const SizedBox(height: 10),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildError(BuildContext context, String message) {
    final colors = Theme.of(context).colorScheme;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: Style.getPaddingSymmetric(horizontal: 28, vertical: 36),
      children: [
        SizedBox(height: 90),
        Icon(Icons.error_outline_rounded, color: colors.error, size: 42),
        const SizedBox(height: 12),
        Text(
          'No se pudieron cargar tus solicitudes.',
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

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.summary});

  final ResumenSolicitudesModel summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Card(
      elevation: 0,
      color: colors.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${summary.totalActivas} de ${summary.limiteSolicitudes} empresas activas',
              style: theme.textTheme.titleMedium?.copyWith(
                color: colors.onPrimaryContainer,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${summary.espaciosDisponibles} espacios disponibles',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onPrimaryContainer,
              ),
            ),
            if (summary.tieneEmpresaConfirmada) ...[
              const SizedBox(height: 8),
              Text(
                'Ya tienes una empresa confirmada.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onPrimaryContainer,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
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
