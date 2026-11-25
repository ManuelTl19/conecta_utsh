import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:resize/resize.dart';
import 'package:conecta_utsh/helpers/style.dart';
import 'package:conecta_utsh/modules/notifications/components/notificacion_card.dart';
import 'package:conecta_utsh/modules/notifications/models/notificacion.dart';
import 'package:conecta_utsh/modules/notifications/providers/notificaciones_controller.dart';
import 'package:conecta_utsh/modules/notifications/services/notificaciones_service.dart';
import 'package:conecta_utsh/modules/resenas/services/resenas_service.dart';
import 'package:conecta_utsh/modules/solicitudes/screens/solicitud_detalle_screen.dart';
import 'package:conecta_utsh/modules/solicitudes/services/solicitudes_service.dart';

class NotificacionesScreen extends StatefulWidget {
  const NotificacionesScreen({
    required this.solicitudesService,
    required this.resenasService,
    required this.onSolicitudesUpdated,
    this.userRole,
    super.key,
  });

  final String? userRole;
  final SolicitudesService solicitudesService;
  final ResenasService resenasService;
  final Future<void> Function() onSolicitudesUpdated;

  @override
  State<NotificacionesScreen> createState() => _NotificacionesScreenState();
}

class _NotificacionesScreenState extends State<NotificacionesScreen> {
  final ScrollController _scrollController = ScrollController();
  final Map<String, _PendingDelete> _pendingDeletes = {};
  bool _requestedInitialLoad = false;

  NotificacionesController get _controller =>
      context.read<NotificacionesController>();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_requestedInitialLoad) {
        _requestedInitialLoad = true;
        _controller.loadFirstPage();
      }
    });
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    for (final pending in _pendingDeletes.values.toList()) {
      pending.timer.cancel();
      unawaited(_deletePending(pending));
    }
    _pendingDeletes.clear();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.extentAfter < 240) {
      unawaited(_loadNextPage());
    }
  }

  Future<void> _loadNextPage() async {
    await _controller.loadNextPage();
    final error = _controller.consumeActionError();
    if (error != null && mounted) _showSnack(error);
  }

  Future<void> _openNotification(Notificacion notification) async {
    if (!notification.leida) {
      final marked = await _controller.markAsRead(notification);
      if (!marked) {
        final error = _controller.consumeActionError();
        if (error != null && mounted) _showSnack(error);
      }
    }
    if (!mounted) return;

    try {
      final current = await _controller.obtenerPorId(notification.id);
      if (!mounted) return;
      await navegarAReferencia(
        context,
        current,
        userRole: widget.userRole,
        solicitudesService: widget.solicitudesService,
        resenasService: widget.resenasService,
      );
    } on NotificationApiException catch (error) {
      if (error.statusCode == 404) {
        _controller.removeIfNotFound(notification.id);
        if (mounted) _showSnack(error.message);
      } else if (mounted) {
        _showSnack(error.message);
      }
    }
  }

  Future<void> _markAllAsRead() async {
    final updatedCount = await _controller.markAllAsRead();
    if (!mounted) return;
    if (updatedCount == null) {
      final error = _controller.consumeActionError();
      if (error != null) _showSnack(error);
      return;
    }
    _showSnack('Se marcaron $updatedCount notificaciones como leídas.');
  }

  void _scheduleDelete(Notificacion notification) {
    final index = _controller.removeLocally(notification);
    if (index < 0) return;
    final messenger = ScaffoldMessenger.of(context);
    late final _PendingDelete pending;
    pending = _PendingDelete(
      notification: notification,
      index: index,
      messenger: messenger,
      timer: Timer(const Duration(seconds: 4), () {
        unawaited(_deletePending(pending));
      }),
    );
    _pendingDeletes[notification.id] = pending;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: const Text('Notificación eliminada'),
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'Deshacer',
            onPressed: () => _undoDelete(pending),
          ),
        ),
      );
  }

  void _undoDelete(_PendingDelete pending) {
    if (!identical(_pendingDeletes.remove(pending.notification.id), pending)) {
      return;
    }
    pending.timer.cancel();
    _controller.restoreLocally(pending.notification, pending.index);
  }

  Future<void> _deletePending(_PendingDelete pending) async {
    if (!identical(_pendingDeletes.remove(pending.notification.id), pending)) {
      return;
    }
    pending.timer.cancel();
    final error = await _controller.deletePermanently(
      pending.notification,
      pending.index,
    );
    if (error != null && pending.messenger.mounted) {
      pending.messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(error)));
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) => Consumer<NotificacionesController>(
    builder: (context, controller, _) {
      final colors = Theme.of(context).colorScheme;
      return Scaffold(
        backgroundColor: colors.surface,
        appBar: AppBar(
          leading: IconButton(
            tooltip: 'Regresar',
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
          ),
          title: const Text('Notificaciones'),
          backgroundColor: colors.surface,
          foregroundColor: colors.onSurface,
          surfaceTintColor: Colors.transparent,
          actions: [
            if (controller.unreadCount > 0)
              TextButton.icon(
                onPressed: _markAllAsRead,
                icon: const Icon(Icons.done_all_rounded),
                label: const Text('Marcar todas como leídas'),
              ),
          ],
        ),
        body: Column(
          children: [
            _buildFilters(controller),
            Expanded(child: _buildContent(controller)),
          ],
        ),
      );
    },
  );

  Widget _buildFilters(NotificacionesController controller) {
    final colors = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: Style.getPaddingSymmetric(horizontal: 18, vertical: 8),
      child: Row(
        children: [
          _filterChip('Todas', NotificacionesFilter.todas, controller, colors),
          const SizedBox(width: 8),
          _filterChip(
            'No leídas',
            NotificacionesFilter.noLeidas,
            controller,
            colors,
          ),
          const SizedBox(width: 8),
          _filterChip(
            'Leídas',
            NotificacionesFilter.leidas,
            controller,
            colors,
          ),
        ],
      ),
    );
  }

  Widget _filterChip(
    String label,
    NotificacionesFilter filter,
    NotificacionesController controller,
    ColorScheme colors,
  ) {
    final selected = controller.filter == filter;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => controller.setFilter(filter),
      backgroundColor: colors.surfaceContainerLow,
      selectedColor: colors.primary.withValues(alpha: .14),
      side: BorderSide(
        color: selected ? colors.primary : colors.outlineVariant,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: Style.getCircularBorderRadius(20),
      ),
      labelStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
        color: selected ? colors.primary : colors.onSurfaceVariant,
        fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
      ),
    );
  }

  Widget _buildContent(NotificacionesController controller) {
    final notifications = controller.notifications;
    final Widget child;
    if (controller.isLoading && notifications.isEmpty) {
      child = _buildSkeletonList();
    } else if (controller.errorMessage != null && notifications.isEmpty) {
      child = _buildError(controller.errorMessage!, controller);
    } else if (notifications.isEmpty) {
      child = _buildEmptyState(controller.filter);
    } else {
      child = ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: Style.getPaddingSymmetric(horizontal: 18, vertical: 8),
        itemCount: notifications.length + (controller.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == notifications.length) {
            return _buildPaginationFooter(controller);
          }
          final notification = notifications[index];
          return Padding(
            key: ValueKey(notification.id),
            padding: const EdgeInsets.only(bottom: 10),
            child: Dismissible(
              key: ValueKey('dismiss-${notification.id}'),
              direction: DismissDirection.horizontal,
              background: _deleteBackground(alignment: Alignment.centerLeft),
              secondaryBackground: _deleteBackground(
                alignment: Alignment.centerRight,
              ),
              onDismissed: (_) => _scheduleDelete(notification),
              child: NotificacionCard(
                notification: notification,
                onTap: () => _openNotification(notification),
              ),
            ),
          );
        },
      );
    }
    return RefreshIndicator(onRefresh: controller.refresh, child: child);
  }

  Widget _buildSkeletonList() => ListView.builder(
    physics: const AlwaysScrollableScrollPhysics(),
    padding: Style.getPaddingSymmetric(horizontal: 18, vertical: 8),
    itemCount: 5,
    itemBuilder: (context, index) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        height: 112,
        padding: Style.getPaddingAll(14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          borderRadius: Style.getCircularBorderRadius(18),
        ),
        child: Row(
          children: [
            const CircleAvatar(radius: 20),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _skeletonLine(width: .65),
                  SizedBox(height: 10.h),
                  _skeletonLine(width: .9),
                  SizedBox(height: 7.h),
                  _skeletonLine(width: .3),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _skeletonLine({required double width}) => FractionallySizedBox(
    widthFactor: width,
    child: Container(
      height: 8,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: Style.getCircularBorderRadius(8),
      ),
    ),
  );

  Widget _buildError(String message, NotificacionesController controller) =>
      ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: Style.getPaddingAll(24),
        children: [
          SizedBox(height: 100.h),
          Icon(
            Icons.error_outline_rounded,
            color: Theme.of(context).colorScheme.error,
            size: 42,
          ),
          SizedBox(height: 12.h),
          Text(message, textAlign: TextAlign.center),
          TextButton(
            onPressed: controller.loadFirstPage,
            child: const Text('Reintentar'),
          ),
        ],
      );

  Widget _buildEmptyState(NotificacionesFilter filter) => ListView(
    physics: const AlwaysScrollableScrollPhysics(),
    padding: Style.getPaddingAll(24),
    children: [
      SizedBox(height: 120.h),
      Icon(
        Icons.notifications_none_rounded,
        size: 48,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      SizedBox(height: 10.h),
      Text(
        filter == NotificacionesFilter.noLeidas
            ? 'Estás al día'
            : 'No tienes notificaciones por ahora',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyMedium
            ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
    ],
  );

  Widget _buildPaginationFooter(NotificacionesController controller) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 18),
    child: Center(
      child: controller.isLoadingMore
          ? const CircularProgressIndicator()
          : TextButton(
              onPressed: _loadNextPage,
              child: const Text('Cargar más'),
            ),
    ),
  );

  Widget _deleteBackground({required Alignment alignment}) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.symmetric(horizontal: 20),
    alignment: alignment,
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.error,
      borderRadius: Style.getCircularBorderRadius(18),
    ),
    child: Icon(
      Icons.delete_outline_rounded,
      color: Style.getInverseTextColor(),
    ),
  );
}

Future<void> navegarAReferencia(
  BuildContext context,
  Notificacion notification, {
  String? userRole,
  required SolicitudesService solicitudesService,
  required ResenasService resenasService,
}) async {
  if (!context.mounted) return;
  final model = notification.referenciaModelo?.toLowerCase();
  final role = userRole?.toLowerCase();
  switch (model) {
    case 'cita':
      // TODO: Navegar al detalle de cita según el rol del usuario.
      if (role == 'admin' || role == 'administrador') return;
      return;
    case 'solicitud':
      final solicitudId = notification.referenciaId;
      if (solicitudId == null || solicitudId.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('La notificación no contiene una solicitud.'),
          ),
        );
        return;
      }
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => SolicitudDetalleScreen(
            solicitudId: solicitudId,
            service: solicitudesService,
            resenasService: resenasService,
            userRole: userRole ?? '',
          ),
        ),
      );
      return;
    case 'empresa':
      // TODO: Cargar la empresa con el servicio existente y abrir su detalle.
      return;
    default:
      return;
  }
}

class _PendingDelete {
  const _PendingDelete({
    required this.notification,
    required this.index,
    required this.messenger,
    required this.timer,
  });

  final Notificacion notification;
  final int index;
  final ScaffoldMessengerState messenger;
  final Timer timer;
}
