import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:conecta_utsh/helpers/apis.dart';
import 'package:conecta_utsh/modules/app/services/auth_service.dart';
import 'package:conecta_utsh/modules/app/services/token_store.dart';
import 'package:conecta_utsh/modules/notifications/models/notificacion.dart';
import 'package:conecta_utsh/modules/notifications/models/notificaciones_page.dart';

class NotificacionesService {
  NotificacionesService({
    required AuthService authService,
    this.onUnauthorized,
    Uri? notificationsEndpoint,
    Uri? unreadEndpoint,
    Uri? markAllReadEndpoint,
  }) : _authService = authService,
       _notificationsEndpoint = notificationsEndpoint ?? Apis.notifications,
       _unreadEndpoint = unreadEndpoint ?? Apis.unreadNotifications,
       _markAllReadEndpoint =
           markAllReadEndpoint ?? Apis.markAllNotificationsRead;

  static final _idPattern = RegExp(r'^[0-9a-fA-F]{24}$');

  final AuthService _authService;
  final Future<void> Function()? onUnauthorized;
  final Uri _notificationsEndpoint;
  final Uri _unreadEndpoint;
  final Uri _markAllReadEndpoint;
  Future<void>? _unauthorizedTask;

  Future<NotificacionesPage> listar({
    bool? leida,
    int pagina = 1,
    int limite = 20,
  }) async {
    final queryParameters = <String, String>{
      'pagina': '$pagina',
      'limite': '$limite',
      if (leida != null) 'leida': '$leida',
    };
    final response = await _request(
      'GET',
      _notificationsEndpoint.replace(queryParameters: queryParameters),
    );
    final decoded = _decodeMap(
      response,
      'No se pudieron leer las notificaciones.',
    );
    late final NotificacionesPage page;
    try {
      page = NotificacionesPage.fromJson(decoded);
    } on FormatException {
      throw const NotificationApiException(
        message: 'No se pudieron leer las notificaciones.',
      );
    }
    final sortedNotifications = [...page.notificaciones]
      ..sort((first, second) {
        return second.fechaRegistro.compareTo(first.fechaRegistro);
      });
    return NotificacionesPage(
      total: page.total,
      totalNoLeidas: page.totalNoLeidas,
      pagina: page.pagina,
      limite: page.limite,
      totalPaginas: page.totalPaginas,
      notificaciones: sortedNotifications,
    );
  }

  Future<int> contarNoLeidas() async {
    final response = await _request('GET', _unreadEndpoint);
    final decoded = _decodeMap(response, 'No se pudo consultar el contador.');
    final count = decoded['totalNoLeidas'];
    if (count is int) return count;
    final parsed = int.tryParse(count?.toString() ?? '');
    if (parsed == null) {
      throw const NotificationApiException(
        message: 'No se pudo consultar el contador de notificaciones.',
      );
    }
    return parsed;
  }

  Future<int> marcarTodasLeidas() async {
    final response = await _request('PATCH', _markAllReadEndpoint);
    final decoded = _decodeMap(
      response,
      'No se pudieron marcar las notificaciones como leídas.',
    );
    final updatedCount = decoded['totalActualizadas'];
    if (updatedCount is int) return updatedCount;
    final parsed = int.tryParse(updatedCount?.toString() ?? '');
    if (parsed == null) {
      throw const NotificationApiException(
        message: 'No se pudieron marcar las notificaciones como leídas.',
      );
    }
    return parsed;
  }

  Future<Notificacion> obtenerPorId(String id) async {
    final response = await _request('GET', _uriForId(id));
    final decoded = _decodeMap(response, 'No se pudo abrir la notificación.');
    final rawNotification = decoded.containsKey('_id')
        ? decoded
        : decoded['notificacion'];
    if (rawNotification is! Map<String, dynamic>) {
      throw const NotificationApiException(
        message: 'No se pudo abrir la notificación.',
      );
    }
    try {
      return Notificacion.fromJson(rawNotification);
    } on FormatException {
      throw const NotificationApiException(
        message: 'No se pudo abrir la notificación.',
      );
    }
  }

  Future<void> marcarLeida(String id) async {
    await _request('PATCH', _uriForId(id, suffix: 'leida'));
  }

  Future<void> eliminar(String id) async {
    await _request('DELETE', _uriForId(id));
  }

  Uri _uriForId(String id, {String? suffix}) {
    if (!_idPattern.hasMatch(id)) {
      throw const NotificationApiException(
        message: 'No se pudo procesar la solicitud.',
      );
    }
    final segments = [..._notificationsEndpoint.pathSegments, id];
    if (suffix != null) segments.add(suffix);
    return _notificationsEndpoint.replace(pathSegments: segments);
  }

  Future<String> _request(String method, Uri endpoint) async {
    try {
      return await _authService.authenticatedRequest(
        method: method,
        endpoint: endpoint,
      );
    } on AuthApiException catch (error) {
      if (error.statusCode == HttpStatus.unauthorized) {
        await _handleUnauthorized();
      }
      final serverMessage = error.message.trim();
      throw NotificationApiException(
        statusCode: error.statusCode,
        message: serverMessage.isNotEmpty
            ? serverMessage
            : _messageForStatus(error.statusCode),
      );
    } on StateError {
      await _handleUnauthorized();
      throw const NotificationApiException(
        statusCode: HttpStatus.unauthorized,
        message: 'Tu sesión terminó. Inicia sesión para continuar.',
      );
    } on SocketException {
      throw const NotificationApiException(
        message: 'No hay conexión. Revisa tu internet.',
      );
    } on TimeoutException {
      throw const NotificationApiException(
        message: 'El servidor tardó demasiado. Intenta de nuevo.',
      );
    } on FormatException {
      throw const NotificationApiException(
        message: 'No se pudo procesar la respuesta del servidor.',
      );
    } on HttpException {
      throw const NotificationApiException(
        message: 'No se pudo completar la solicitud.',
      );
    } on TokenStorageException {
      throw const NotificationApiException(
        message: 'No se pudo acceder a tu sesión de forma segura.',
      );
    }
  }

  Future<void> _handleUnauthorized() async {
    final callback = onUnauthorized;
    if (callback == null) return;
    final activeTask = _unauthorizedTask;
    if (activeTask != null) return activeTask;

    final task = Future<void>.sync(callback);
    _unauthorizedTask = task;
    try {
      await task;
    } finally {
      _unauthorizedTask = null;
    }
  }

  String _messageForStatus(int statusCode) => switch (statusCode) {
    HttpStatus.badRequest => 'No se pudo procesar la solicitud.',
    HttpStatus.unauthorized =>
      'Tu sesión terminó. Inicia sesión para continuar.',
    HttpStatus.notFound => 'Esta notificación ya no existe.',
    HttpStatus.internalServerError =>
      'Hubo un problema en el servidor. Intenta más tarde.',
    _ => 'No se pudo completar la solicitud. Intenta de nuevo.',
  };

  Map<String, dynamic> _decodeMap(String response, String errorMessage) {
    try {
      final decoded = jsonDecode(response);
      if (decoded is Map<String, dynamic>) return decoded;
    } on FormatException {
      throw NotificationApiException(message: errorMessage);
    }
    throw NotificationApiException(message: errorMessage);
  }
}

class NotificationApiException implements Exception {
  const NotificationApiException({this.statusCode, required this.message});

  final int? statusCode;
  final String message;

  @override
  String toString() => message;
}
