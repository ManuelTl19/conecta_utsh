import 'dart:async';

import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:conecta_utsh/modules/resenas/screens/comentarios_empresa_screen.dart';
import 'package:conecta_utsh/modules/resenas/services/resenas_service.dart';
import 'package:conecta_utsh/modules/solicitudes/components/solicitud_estado_chip.dart';
import 'package:conecta_utsh/modules/solicitudes/components/solicitud_progress.dart';
import 'package:conecta_utsh/modules/solicitudes/models/solicitud_estado.dart';
import 'package:conecta_utsh/modules/solicitudes/models/solicitud_model.dart';
import 'package:conecta_utsh/modules/solicitudes/services/solicitudes_service.dart';

class SolicitudDetalleScreen extends StatefulWidget {
  const SolicitudDetalleScreen({
    required this.solicitudId,
    required this.service,
    required this.resenasService,
    required this.userRole,
    super.key,
  });

  final String solicitudId;
  final SolicitudesService service;
  final ResenasService resenasService;
  final String userRole;

  @override
  State<SolicitudDetalleScreen> createState() => _SolicitudDetalleScreenState();
}

class _SolicitudDetalleScreenState extends State<SolicitudDetalleScreen> {
  SolicitudModel? _solicitud;
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
      final request = await widget.service.obtenerPorId(widget.solicitudId);
      if (!mounted) return;
      setState(() {
        _solicitud = request;
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

  Future<void> _openReview(SolicitudModel request) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => Scaffold(
          appBar: AppBar(
            title: Text('Reseñas de ${request.empresa.name ?? 'la empresa'}'),
          ),
          body: ComentariosEmpresaScreen(
            empresaId: request.empresa.id,
            userRole: widget.userRole,
            service: widget.resenasService,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        title: const Text('Detalle de solicitud'),
        backgroundColor: colors.surface,
        foregroundColor: colors.onSurface,
        surfaceTintColor: Colors.transparent,
      ),
      body: _isLoading && _solicitud == null
          ? Center(child: CircularProgressIndicator(color: colors.primary))
          : _errorMessage != null && _solicitud == null
          ? _buildError(context)
          : _solicitud == null
          ? const SizedBox.shrink()
          : _buildRequest(context, _solicitud!),
    );
  }

  Widget _buildError(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, color: colors.error, size: 42),
            const SizedBox(height: 12),
            Text(_errorMessage ?? 'No se pudo abrir la solicitud.'),
            const SizedBox(height: 12),
            FilledButton.tonal(
              onPressed: _load,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequest(BuildContext context, SolicitudModel request) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final company = request.empresa;
    final registrar = request.registradoPor;
    final registrarLabel = registrar == null
        ? 'No disponible'
        : const {
            'admin',
            'administrador',
          }.contains(registrar.rol?.toLowerCase())
        ? 'Registrada por el área de estadías'
        : registrar.nombreCompleto.isEmpty
        ? 'No disponible'
        : registrar.nombreCompleto;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
      children: [
        if (_isLoading) const LinearProgressIndicator(),
        Card(
          elevation: 0,
          color: colors.surfaceContainerLow,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  company.name?.trim().isNotEmpty == true
                      ? company.name!
                      : 'Empresa no disponible',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                SolicitudEstadoChip(estado: request.estado),
                const SizedBox(height: 14),
                if (company.description?.trim().isNotEmpty == true)
                  Text(
                    company.description!,
                    style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
                  ),
                if (company.requirements.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Text(
                    'Requisitos',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  for (final requirement in company.requirements)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text('•  $requirement'),
                    ),
                ],
                if (company.contact.email?.isNotEmpty == true)
                  _DetailValue(label: 'Correo', value: company.contact.email!),
                if (company.contact.phone?.isNotEmpty == true)
                  _DetailValue(
                    label: 'Teléfono',
                    value: company.contact.phone!,
                  ),
                if (company.location.address?.isNotEmpty == true)
                  _DetailValue(
                    label: 'Dirección',
                    value: company.location.address!,
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Card(
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Proceso de estadía',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                SolicitudProgress(estado: request.estado),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        _DetailValue(
          label: 'Origen',
          value: request.origen?.etiqueta ?? 'No especificado',
        ),
        _DetailValue(label: 'Registrada por', value: registrarLabel),
        _DetailValue(
          label: 'Fecha de registro',
          value: DateFormat('dd/MM/yyyy HH:mm')
              .format(request.fechaRegistro.toLocal()),
        ),
        _DetailValue(
          label: 'Última actualización',
          value: DateFormat('dd/MM/yyyy HH:mm')
              .format(request.fechaActualizacion.toLocal()),
        ),
        if (request.observaciones.trim().isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            'Observaciones',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(request.observaciones),
        ],
        if (request.estado == SolicitudEstado.finalizada) ...[
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: () => _openReview(request),
            icon: const Icon(Icons.star_outline_rounded),
            label: const Text('Calificar empresa'),
          ),
        ],
      ],
    );
  }
}

class _DetailValue extends StatelessWidget {
  const _DetailValue({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 10),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 130,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(child: Text(value)),
      ],
    ),
  );
}
