import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:conecta_utsh/modules/company/models/company_model.dart';
import 'package:conecta_utsh/modules/favoritos/models/favorito_item.dart';
import 'package:conecta_utsh/modules/favoritos/services/favoritos_service.dart';

enum FavoritosLoadStatus { initial, loading, loaded, error }

enum FavoritoToggleResult { added, removed, unchanged }

class FavoritosController extends ChangeNotifier with WidgetsBindingObserver {
  FavoritosController({
    required FavoritosService service,
    required String userRole,
  }) : _service = service,
       _userRole = userRole.trim().toLowerCase() {
    WidgetsBinding.instance.addObserver(this);
    if (!isStudent) {
      _status = FavoritosLoadStatus.loaded;
      _hasLoaded = true;
    }
  }

  final FavoritosService _service;
  final String _userRole;
  final List<FavoritoItem> _items = [];
  final Set<String> _companyIds = {};
  final Set<String> _pendingCompanyIds = {};
  final Map<String, CompanyModel> _pendingCompanies = {};
  final Map<String, Completer<void>> _pendingCompletions = {};
  final Map<String, bool> _verifiedOverrides = {};
  FavoritosLoadStatus _status = FavoritosLoadStatus.initial;
  String? _error;
  bool _hasLoaded = false;
  bool _disposed = false;
  int _loadGeneration = 0;
  int _clearGeneration = 0;
  Future<bool>? _loadTask;

  bool get isStudent => _userRole == 'estudiante';
  bool get hasLoaded => _hasLoaded;
  int get count => _items.length;
  List<FavoritoItem> get items => List.unmodifiable(_items);
  FavoritosLoadStatus get status => _status;
  String? get error => _error;

  bool isFavorite(String companyId) =>
      _verifiedOverrides[companyId] ?? _companyIds.contains(companyId);

  bool isPending(String companyId) => _pendingCompanyIds.contains(companyId);

  Future<bool> cargar({bool force = false}) {
    if (!isStudent) return Future.value(true);
    final runningTask = _loadTask;
    if (runningTask != null) return runningTask;
    if (!force && _status == FavoritosLoadStatus.loaded) {
      return Future.value(true);
    }

    final generation = ++_loadGeneration;
    _status = FavoritosLoadStatus.loading;
    _error = null;
    _notifyIfActive();
    final task = _loadFavorites(generation);
    _loadTask = task;
    return task;
  }

  Future<bool> recargar() async {
    final clearGeneration = _clearGeneration;
    while (_pendingCompletions.isNotEmpty) {
      await Future.wait(
        _pendingCompletions.values.map((completion) => completion.future),
      );
    }
    if (_disposed || clearGeneration != _clearGeneration) return false;
    return cargar(force: true);
  }

  Future<bool> _loadFavorites(int generation) async {
    try {
      final items = await _service.listar();
      if (_disposed || generation != _loadGeneration) return false;
      final pendingFavorites = {
        for (final companyId in _pendingCompanyIds)
          companyId:
              _verifiedOverrides[companyId] ?? _companyIds.contains(companyId),
      };
      _items
        ..clear()
        ..addAll(items);
      _companyIds
        ..clear()
        ..addAll(items.map((item) => item.empresa.id));
      _verifiedOverrides.clear();
      _hasLoaded = true;
      for (final entry in pendingFavorites.entries) {
        final company = _pendingCompanies[entry.key];
        if (company != null) {
          _setLocalFavorite(company, entry.value);
        }
      }
      _status = FavoritosLoadStatus.loaded;
      _error = null;
      _notifyIfActive();
      return true;
    } on FavoritosApiException catch (error) {
      if (_disposed || generation != _loadGeneration) return false;
      if (error.statusCode == 401) {
        limpiar();
        return false;
      }
      _status = FavoritosLoadStatus.error;
      _error = error.message;
      _notifyIfActive();
      return false;
    } on Exception catch (error) {
      if (_disposed || generation != _loadGeneration) return false;
      _status = FavoritosLoadStatus.error;
      _error = error.toString();
      _notifyIfActive();
      return false;
    } finally {
      if (!_disposed && generation == _loadGeneration) _loadTask = null;
    }
  }

  Future<FavoritoToggleResult> alternar(
    CompanyModel company, {
    Future<void> Function()? onCompanyUnavailable,
  }) async {
    if (!isStudent) return FavoritoToggleResult.unchanged;
    if (_pendingCompanyIds.contains(company.id)) {
      return FavoritoToggleResult.unchanged;
    }

    if (_status != FavoritosLoadStatus.loaded) {
      final loaded = await cargar();
      if (!loaded) {
        if (_status != FavoritosLoadStatus.error) {
          return FavoritoToggleResult.unchanged;
        }
        final verified = await _service.verificar(company.id);
        _verifiedOverrides[company.id] = verified;
        _notifyIfActive();
      }
    }

    if (_pendingCompanyIds.contains(company.id)) {
      return FavoritoToggleResult.unchanged;
    }

    final wasFavorite = isFavorite(company.id);
    final previousItem = _findItem(company.id);
    _pendingCompanyIds.add(company.id);
    _pendingCompanies[company.id] = company;
    _pendingCompletions[company.id] = Completer<void>();
    _setLocalFavorite(company, !wasFavorite);
    _notifyIfActive();

    try {
      if (wasFavorite) {
        await _service.quitar(company.id);
        return FavoritoToggleResult.removed;
      }
      await _service.agregar(company.id);
      return FavoritoToggleResult.added;
    } on FavoritoExistenteException {
      _setLocalFavorite(company, true);
      return FavoritoToggleResult.unchanged;
    } on FavoritoNoEncontradoException {
      if (wasFavorite) {
        _setLocalFavorite(company, false);
        return FavoritoToggleResult.removed;
      }
      _restoreFavorite(company, wasFavorite, previousItem);
      rethrow;
    } on EmpresaNoEncontradaException {
      _restoreFavorite(company, wasFavorite, previousItem);
      await onCompanyUnavailable?.call();
      rethrow;
    } on FavoritosApiException catch (error) {
      if (error.statusCode != 401) {
        _restoreFavorite(company, wasFavorite, previousItem);
      } else {
        limpiar();
      }
      rethrow;
    } on Exception {
      _restoreFavorite(company, wasFavorite, previousItem);
      rethrow;
    } finally {
      _pendingCompanyIds.remove(company.id);
      _pendingCompanies.remove(company.id);
      final completion = _pendingCompletions.remove(company.id);
      if (completion != null && !completion.isCompleted) {
        completion.complete();
      }
      _notifyIfActive();
    }
  }

  void _setLocalFavorite(CompanyModel company, bool favorite) {
    _verifiedOverrides[company.id] = favorite;
    if (favorite) {
      _companyIds.add(company.id);
      if (_hasLoaded && _findItem(company.id) == null) {
        _items.add(
          FavoritoItem(
            idRegistro: '',
            empresa: company,
            fechaRegistro: DateTime.now(),
          ),
        );
        _sortItems();
      }
    } else {
      _companyIds.remove(company.id);
      _items.removeWhere((item) => item.empresa.id == company.id);
    }
  }

  void _restoreFavorite(
    CompanyModel company,
    bool wasFavorite,
    FavoritoItem? previousItem,
  ) {
    _verifiedOverrides[company.id] = wasFavorite;
    if (wasFavorite) {
      _companyIds.add(company.id);
      if (_hasLoaded && _findItem(company.id) == null) {
        _items.add(
          previousItem ??
              FavoritoItem(
                idRegistro: '',
                empresa: company,
                fechaRegistro: DateTime.now(),
              ),
        );
        _sortItems();
      }
    } else {
      _companyIds.remove(company.id);
      _items.removeWhere((item) => item.empresa.id == company.id);
    }
  }

  FavoritoItem? _findItem(String companyId) {
    for (final item in _items) {
      if (item.empresa.id == companyId) return item;
    }
    return null;
  }

  void _sortItems() {
    _items.sort(
      (first, second) => second.fechaRegistro.compareTo(first.fechaRegistro),
    );
  }

  void limpiar() {
    _clearGeneration++;
    _loadGeneration++;
    _loadTask = null;
    for (final completion in _pendingCompletions.values) {
      if (!completion.isCompleted) completion.complete();
    }
    _pendingCompletions.clear();
    _items.clear();
    _companyIds.clear();
    _pendingCompanyIds.clear();
    _pendingCompanies.clear();
    _verifiedOverrides.clear();
    _hasLoaded = false;
    _status = FavoritosLoadStatus.initial;
    _error = null;
    _notifyIfActive();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && isStudent) {
      unawaited(recargar());
    }
  }

  void _notifyIfActive() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    for (final completion in _pendingCompletions.values) {
      if (!completion.isCompleted) completion.complete();
    }
    _pendingCompletions.clear();
    _disposed = true;
    _loadGeneration++;
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
