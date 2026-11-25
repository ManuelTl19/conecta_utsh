import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:conecta_utsh/modules/company/models/company_filters.dart';
import 'package:conecta_utsh/modules/company/models/company_model.dart';
import 'package:conecta_utsh/modules/company/services/company_service.dart';

class CompanyController extends ChangeNotifier {
  CompanyController({required CompanyService service, String initialQuery = ''})
    : _service = service,
      _query = initialQuery {
    unawaited(_load());
  }

  final CompanyService _service;
  Timer? _searchDebounce;
  List<CompanyModel>? _unfilteredCompanies;
  int? _unfilteredTotal;
  String? _unfilteredError;
  List<CompanyModel> _companies = const [];
  CompanyFilterOptions _filterOptions = const CompanyFilterOptions(
    estados: [],
    municipiosPorEstado: {},
  );
  CompanyFilters _filters = const CompanyFilters();
  String _query;
  String? _error;
  int _requestId = 0;
  int _total = 0;
  bool _isLoading = true;

  List<CompanyModel> get companies => _companies;
  List<CompanyModel> get unfilteredCompanies =>
      _unfilteredCompanies ?? const [];
  bool get isLoadingUnfiltered => _unfilteredCompanies == null && _isLoading;
  CompanyFilterOptions get filterOptions => _filterOptions;
  CompanyFilters get filters => _filters;
  String get query => _query;
  String? get error => _error;
  int get total => _total;
  bool get isLoading => _isLoading;
  String? get unfilteredError => _unfilteredError;

  void setQuery(String query) {
    _query = query;
    _searchDebounce?.cancel();
    final requestId = ++_requestId;
    _isLoading = true;
    _error = null;
    notifyListeners();
    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      if (requestId == _requestId) unawaited(_load());
    });
  }

  void setFilters(CompanyFilters filters) {
    _filters = filters;
    _searchDebounce?.cancel();
    unawaited(_load());
  }

  Future<void> refresh() {
    _searchDebounce?.cancel();
    return _load(refreshOptions: true);
  }

  Future<void> _load({bool refreshOptions = false}) async {
    final requestId = ++_requestId;
    final loadingUnfiltered = refreshOptions || _unfilteredCompanies == null;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      List<CompanyModel>? unfiltered;
      if (refreshOptions || _unfilteredCompanies == null) {
        final response = await _service.getCompanies();
        if (requestId != _requestId) return;
        unfiltered = response.companies;
        _unfilteredCompanies = unfiltered;
        _unfilteredTotal = response.total;
        _unfilteredError = null;
        _filterOptions = _deriveFilterOptions(unfiltered);
      }

      final hasSearchOrFilters =
          _query.trim().isNotEmpty || _filters.hasActiveFilters;
      final response = hasSearchOrFilters
          ? await _service.getCompanies(
              empresa: _query,
              direccionAcademica: _filters.direccionAcademica,
              carrera: _filters.carrera,
              estado: _filters.estado,
              municipio: _filters.municipio,
              soloFavoritas: _filters.soloFavoritas,
            )
          : null;
      if (requestId != _requestId) return;

      _companies = response?.companies ?? unfiltered ?? _unfilteredCompanies!;
      _total = response?.total ?? _unfilteredTotal ?? _companies.length;
      _isLoading = false;
      notifyListeners();
    } on CompanyApiException catch (error) {
      if (requestId != _requestId) return;
      _error = error.message;
      if (loadingUnfiltered) _unfilteredError = error.message;
      _isLoading = false;
      notifyListeners();
    } on Exception catch (error) {
      if (requestId != _requestId) return;
      _error = 'No se pudieron cargar las empresas: $error';
      if (loadingUnfiltered) _unfilteredError = _error;
      _isLoading = false;
      notifyListeners();
    }
  }

  CompanyFilterOptions _deriveFilterOptions(List<CompanyModel> companies) {
    final municipalitiesByState = <String, Set<String>>{};
    for (final company in companies) {
      final state = company.location.state?.trim();
      final municipality = company.location.municipality?.trim();
      if (state == null ||
          state.isEmpty ||
          municipality == null ||
          municipality.isEmpty) {
        continue;
      }
      municipalitiesByState
          .putIfAbsent(state, () => <String>{})
          .add(municipality);
    }

    final states = municipalitiesByState.keys.toList()..sort();
    return CompanyFilterOptions(
      estados: states,
      municipiosPorEstado: {
        for (final state in states)
          state: municipalitiesByState[state]!.toList()..sort(),
      },
    );
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _requestId++;
    super.dispose();
  }
}
