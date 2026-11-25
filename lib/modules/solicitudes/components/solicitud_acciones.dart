import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:conecta_utsh/modules/company/models/company_model.dart';
import 'package:conecta_utsh/modules/solicitudes/models/solicitud_estado.dart';
import 'package:conecta_utsh/modules/solicitudes/models/solicitud_model.dart';
import 'package:conecta_utsh/modules/solicitudes/models/resumen_solicitudes_model.dart';
import 'package:conecta_utsh/modules/solicitudes/services/solicitudes_service.dart';

class SolicitudAcciones extends StatefulWidget {
  const SolicitudAcciones({
    required this.company,
    required this.service,
    required this.userRole,
    this.onSolicitudesUpdated,
    super.key,
  });

  final CompanyModel company;
  final SolicitudesService service;
  final String userRole;
  final Future<void> Function()? onSolicitudesUpdated;

  @override
  State<SolicitudAcciones> createState() => _SolicitudAccionesState();
}

class _SolicitudAccionesState extends State<SolicitudAcciones> {
  ResumenSolicitudesModel? _resumen;
  List<SolicitudModel> _solicitudes = const [];
  String? _errorMessage;
  bool _isLoading = true;
  bool _isSubmitting = false;

  bool get _isStudent => widget.userRole.trim().toLowerCase() == 'estudiante';

  @override
  void initState() {
    super.initState();
    if (_isStudent) unawaited(_load());
  }

  @override
  void didUpdateWidget(covariant SolicitudAcciones oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.company.id != widget.company.id && _isStudent) {
      unawaited(_load());
    }
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
        _resumen = result.resumen;
        _solicitudes = result.solicitudes;
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

  bool get _hasActiveRequestForCompany => _solicitudes.any(
    (request) =>
        request.empresa.id == widget.company.id && request.estado.esActiva,
  );

  String? _disabledReason(SolicitudOrigen origin) {
    final summary = _resumen;
    if (summary == null) {
      return _isLoading
          ? 'Consultando disponibilidad…'
          : 'No se pudo consultar la disponibilidad.';
    }
    if (summary.tieneEmpresaConfirmada) {
      return 'Ya tienes una empresa confirmada.';
    }
    if (_hasActiveRequestForCompany) {
      return 'Ya tienes una solicitud activa para esta empresa.';
    }
    if (origin == SolicitudOrigen.catalogo && !summary.puedeCrearSolicitud) {
      if (summary.totalActivas >= summary.limiteSolicitudes ||
          summary.espaciosDisponibles == 0) {
        return 'Ya alcanzaste el límite de ${summary.limiteSolicitudes} solicitudes activas.';
      }
      return 'No puedes crear otra solicitud en este momento.';
    }
    if (origin == SolicitudOrigen.propia &&
        !summary.puedeRegistrarEmpresaPropia) {
      return 'No puedes registrar una empresa propia en este momento.';
    }
    return null;
  }

  Future<bool> _confirmOwnCompany() async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Registrar empresa propia'),
          content: const Text(
            'Esto indica que la empresa ya te aceptó. Se cancelarán tus otras solicitudes pendientes y pasarás a documentación pendiente.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Volver'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Confirmar'),
            ),
          ],
        ),
      ) ??
      false;

  Future<void> _create(SolicitudOrigen origin) async {
    if (_isSubmitting || _disabledReason(origin) != null) return;
    if (origin == SolicitudOrigen.propia && !await _confirmOwnCompany()) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });
    try {
      final result = await widget.service.crear(
        empresaId: widget.company.id,
        origen: origin,
      );
      await _load();
      await widget.onSolicitudesUpdated?.call();
      if (!mounted) return;
      final message = result.totalCanceladas > 0
          ? '${result.message}\nSe cancelaron ${result.totalCanceladas} solicitudes pendientes'
          : result.message;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
    } on SolicitudesApiException catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = error.message);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(error.message)));
      await _load();
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isStudent) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final catalogReason = _disabledReason(SolicitudOrigen.catalogo);
    final ownReason = _disabledReason(SolicitudOrigen.propia);

    return Card(
      elevation: 0,
      color: colors.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Solicitar estadía en esta empresa',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            if (_isLoading) ...[
              const SizedBox(height: 10),
              const LinearProgressIndicator(),
            ],
            if (_errorMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                style: theme.textTheme.bodySmall?.copyWith(color: colors.error),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _isLoading ? null : _load,
                  child: const Text('Reintentar'),
                ),
              ),
            ],
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _isSubmitting || catalogReason != null
                    ? null
                    : () => _create(SolicitudOrigen.catalogo),
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.business_center_outlined),
                label: const Text('Elegir esta empresa'),
              ),
            ),
            if (catalogReason != null)
              _ReasonText(
                message: catalogReason,
                color: colors.onSurfaceVariant,
              ),
            const SizedBox(height: 6),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isSubmitting || ownReason != null
                    ? null
                    : () => _create(SolicitudOrigen.propia),
                icon: const Icon(Icons.verified_outlined),
                label: const Text('Ya me aceptaron aquí'),
              ),
            ),
            if (ownReason != null)
              _ReasonText(message: ownReason, color: colors.onSurfaceVariant),
            if (_resumen case final summary?)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  '${summary.totalActivas} de ${summary.limiteSolicitudes} empresas activas · ${summary.espaciosDisponibles} espacios disponibles',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ReasonText extends StatelessWidget {
  const _ReasonText({required this.message, required this.color});

  final String message;
  final Color color;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 3),
    child: Text(
      message,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color),
    ),
  );
}
