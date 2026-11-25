import 'package:flutter/widgets.dart';

import 'package:conecta_utsh/modules/notifications/models/notificacion.dart';
import 'package:conecta_utsh/modules/notifications/models/notificaciones_page.dart';
import 'package:conecta_utsh/modules/notifications/services/notificaciones_service.dart';

enum NotificacionesFilter { todas, noLeidas, leidas }

class NotificacionesController extends ChangeNotifier
    with WidgetsBindingObserver {
  NotificacionesController({required NotificacionesService service})
    : _service = service {
    WidgetsBinding.instance.addObserver(this);
    refreshCount();
  }

  final NotificacionesService _service;
  final List<Notificacion> _notifications = [];
  NotificacionesFilter _filter = NotificacionesFilter.todas;
  int _total = 0;
  int _unreadCount = 0;
  int _page = 1;
  int _totalPages = 1;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _errorMessage;
  String? _actionError;
  bool _disposed = false;
  int _loadGeneration = 0;
  final Set<String> _mutatingIds = {};

  List<Notificacion> get notifications => List.unmodifiable(_notifications);
  NotificacionesFilter get filter => _filter;
  int get total => _total;
  int get unreadCount => _unreadCount;
  int get page => _page;
  int get totalPages => _totalPages;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _page < _totalPages;
  String? get errorMessage => _errorMessage;
  String? get actionError => _actionError;

  String? consumeActionError() {
    final error = _actionError;
    _actionError = null;
    return error;
  }

  bool? get _readFilter => switch (_filter) {
    NotificacionesFilter.todas => null,
    NotificacionesFilter.noLeidas => false,
    NotificacionesFilter.leidas => true,
  };

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) refreshCount();
  }

  Future<void> refreshCount() async {
    try {
      _unreadCount = await _service.contarNoLeidas();
      _actionError = null;
      _notifyIfAlive();
    } on NotificationApiException catch (error) {
      _actionError = error.message;
      _notifyIfAlive();
    }
  }

  Future<void> loadFirstPage() async {
    final generation = ++_loadGeneration;
    _page = 1;
    _isLoading = true;
    _isLoadingMore = false;
    _errorMessage = null;
    _notifyIfAlive();

    try {
      final result = await _service.listar(leida: _readFilter);
      if (_disposed || generation != _loadGeneration) return;
      _replacePage(result);
      _isLoading = false;
      _errorMessage = null;
      _notifyIfAlive();
    } on NotificationApiException catch (error) {
      if (_disposed || generation != _loadGeneration) return;
      _isLoading = false;
      _errorMessage = error.message;
      _notifyIfAlive();
    }
  }

  Future<void> setFilter(NotificacionesFilter filter) async {
    if (_filter == filter) return;
    _filter = filter;
    _notifications.clear();
    await loadFirstPage();
  }

  Future<void> refresh() async {
    await Future.wait([loadFirstPage(), refreshCount()]);
  }

  Future<void> loadNextPage() async {
    if (_isLoading || _isLoadingMore || !hasMore) return;
    final generation = _loadGeneration;
    final nextPage = _page + 1;
    _isLoadingMore = true;
    _notifyIfAlive();
    try {
      final result = await _service.listar(
        leida: _readFilter,
        pagina: nextPage,
      );
      if (_disposed || generation != _loadGeneration) return;
      _appendPage(result);
      _isLoadingMore = false;
      _notifyIfAlive();
    } on NotificationApiException catch (error) {
      if (_disposed || generation != _loadGeneration) return;
      _isLoadingMore = false;
      _actionError = error.message;
      _notifyIfAlive();
    }
  }

  Future<bool> markAsRead(Notificacion notification) async {
    if (notification.leida || !_mutatingIds.add(notification.id)) return true;
    final oldIndex = _notifications.indexWhere(
      (item) => item.id == notification.id,
    );
    if (oldIndex < 0) {
      _mutatingIds.remove(notification.id);
      return false;
    }
    final oldCount = _unreadCount;
    _unreadCount = (_unreadCount - 1).clamp(0, _unreadCount);
    if (_filter == NotificacionesFilter.noLeidas) {
      _notifications.removeAt(oldIndex);
    } else {
      _notifications[oldIndex] = notification.copyWith(
        leida: true,
        fechaLectura: DateTime.now(),
      );
    }
    _notifyIfAlive();

    try {
      await _service.marcarLeida(notification.id);
      _actionError = null;
      return true;
    } on NotificationApiException catch (error) {
      if (error.statusCode == 404) {
        _notifications.removeWhere((item) => item.id == notification.id);
      } else {
        _unreadCount = oldCount;
        if (!_notifications.any((item) => item.id == notification.id)) {
          _notifications.insert(oldIndex, notification);
        } else {
          final currentIndex = _notifications.indexWhere(
            (item) => item.id == notification.id,
          );
          _notifications[currentIndex] = notification;
        }
      }
      _actionError = error.message;
      return false;
    } finally {
      _mutatingIds.remove(notification.id);
      _notifyIfAlive();
    }
  }

  Future<Notificacion> obtenerPorId(String id) => _service.obtenerPorId(id);

  int removeLocally(Notificacion notification) {
    final index = _notifications.indexWhere(
      (item) => item.id == notification.id,
    );
    if (index < 0) return -1;
    _notifications.removeAt(index);
    if (!notification.leida) {
      _unreadCount = (_unreadCount - 1).clamp(0, _unreadCount);
    }
    _notifyIfAlive();
    return index;
  }

  void restoreLocally(Notificacion notification, int index) {
    if (_notifications.any((item) => item.id == notification.id)) return;
    final insertionIndex = index.clamp(0, _notifications.length);
    _notifications.insert(insertionIndex, notification);
    if (!notification.leida) _unreadCount++;
    _notifyIfAlive();
  }

  Future<String?> deletePermanently(
    Notificacion notification,
    int oldIndex,
  ) async {
    try {
      await _service.eliminar(notification.id);
      return null;
    } on NotificationApiException catch (error) {
      if (error.statusCode != 404) {
        restoreLocally(notification, oldIndex);
      }
      _actionError = error.message;
      _notifyIfAlive();
      return error.message;
    }
  }

  Future<int?> markAllAsRead() async {
    try {
      final updatedCount = await _service.marcarTodasLeidas();
      final readAt = DateTime.now();
      for (var index = 0; index < _notifications.length; index++) {
        _notifications[index] = _notifications[index].copyWith(
          leida: true,
          fechaLectura: readAt,
        );
      }
      if (_filter == NotificacionesFilter.noLeidas) {
        _notifications.clear();
        _total = 0;
        _page = 1;
        _totalPages = 1;
      }
      _unreadCount = 0;
      _actionError = null;
      _notifyIfAlive();
      return updatedCount;
    } on NotificationApiException catch (error) {
      _actionError = error.message;
      _notifyIfAlive();
      return null;
    }
  }

  void clearData() {
    _loadGeneration++;
    _notifications.clear();
    _mutatingIds.clear();
    _filter = NotificacionesFilter.todas;
    _total = 0;
    _unreadCount = 0;
    _page = 1;
    _totalPages = 1;
    _isLoading = false;
    _isLoadingMore = false;
    _errorMessage = null;
    _actionError = null;
    _notifyIfAlive();
  }

  void removeIfNotFound(String id) {
    final index = _notifications.indexWhere((item) => item.id == id);
    if (index < 0) return;
    final notification = _notifications.removeAt(index);
    if (!notification.leida) {
      _unreadCount = (_unreadCount - 1).clamp(0, _unreadCount);
    }
    _notifyIfAlive();
  }

  void _replacePage(NotificacionesPage result) {
    _notifications
      ..clear()
      ..addAll(result.notificaciones);
    _total = result.total;
    _unreadCount = result.totalNoLeidas;
    _page = result.pagina;
    _totalPages = result.totalPaginas;
  }

  void _appendPage(NotificacionesPage result) {
    final existingIds = _notifications.map((item) => item.id).toSet();
    _notifications.addAll(
      result.notificaciones.where((item) => existingIds.add(item.id)),
    );
    _total = result.total;
    _unreadCount = result.totalNoLeidas;
    _page = result.pagina;
    _totalPages = result.totalPaginas;
  }

  void _notifyIfAlive() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
