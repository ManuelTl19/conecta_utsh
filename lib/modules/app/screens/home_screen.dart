import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:conecta_utsh/helpers/providers/app_settings.dart';
import 'package:conecta_utsh/helpers/style.dart';
import 'package:conecta_utsh/modules/app/components/home_components.dart';
import 'package:conecta_utsh/modules/app/components/quick_menu.dart';
import 'package:conecta_utsh/modules/app/components/user_drawer.dart';
import 'package:conecta_utsh/modules/app/models/login_response_model.dart';
import 'package:conecta_utsh/modules/app/providers/user_profile_controller.dart';
import 'package:conecta_utsh/modules/app/services/auth_service.dart';
import 'package:conecta_utsh/modules/app/services/token_store.dart';
import 'package:conecta_utsh/modules/app/screens/profile_screen.dart';
import 'package:conecta_utsh/modules/company/components/company_cards.dart';
import 'package:conecta_utsh/modules/company/components/company_filters_sheet.dart';
import 'package:conecta_utsh/modules/company/components/featured_companies_carousel.dart';
import 'package:conecta_utsh/modules/company/components/company_search_filters.dart';
import 'package:conecta_utsh/modules/company/models/company_filters.dart';
import 'package:conecta_utsh/modules/company/models/company_model.dart';
import 'package:conecta_utsh/modules/company/providers/company_controller.dart';
import 'package:conecta_utsh/modules/company/screens/company_details_screen.dart';
import 'package:conecta_utsh/modules/company/screens/company_screen.dart';
import 'package:conecta_utsh/modules/company/services/company_service.dart';
import 'package:conecta_utsh/modules/favoritos/providers/favoritos_controller.dart';
import 'package:conecta_utsh/modules/favoritos/screens/favoritos_screen.dart';
import 'package:conecta_utsh/modules/notifications/components/notification_bell_button.dart';
import 'package:conecta_utsh/modules/notifications/providers/notificaciones_controller.dart';
import 'package:conecta_utsh/modules/notifications/screens/notificaciones_screen.dart';
import 'package:conecta_utsh/modules/resenas/services/resenas_service.dart';
import 'package:conecta_utsh/modules/solicitudes/screens/mis_solicitudes_screen.dart';
import 'package:conecta_utsh/modules/solicitudes/services/solicitudes_service.dart';
import 'package:conecta_utsh/utils/widgets/dialogs.dart';
import 'package:shimmer/shimmer.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    required this.user,
    required this.authService,
    required this.solicitudesService,
    this.companyService,
    this.onSettings,
    this.onCalendar,
    this.onLogout,
    this.onUnauthorized,
    this.onAccountDeleted,
    super.key,
  });

  final LoginUserModel user;
  final AuthService authService;
  final SolicitudesService solicitudesService;
  final CompanyService? companyService;
  final VoidCallback? onSettings;
  final VoidCallback? onCalendar;
  final Future<void> Function()? onLogout;
  final Future<void> Function()? onUnauthorized;
  final Future<void> Function()? onAccountDeleted;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with AutomaticKeepAliveClientMixin<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  late final CompanyController _companyController;
  late final FavoritosController _favoritosController;
  bool _isDrawerOpen = false;
  bool _isLoggingOut = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _favoritosController = Provider.of<FavoritosController>(
      context,
      listen: false,
    );
    _companyController = CompanyController(
      service:
          widget.companyService ??
          CompanyService(
            authService: widget.authService,
            onUnauthorized: _logout,
          ),
      favoritosController: _favoritosController,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _companyController.dispose();
    super.dispose();
  }

  Future<void> _logout() async {
    final onLogout = widget.onLogout;
    if (onLogout != null) {
      await onLogout();
      return;
    }
    if (_isLoggingOut) return;
    setState(() {
      _isLoggingOut = true;
      _isDrawerOpen = false;
    });
    try {
      await widget.authService.logout();
      if (!mounted) return;
      AppSettings.isSignedIn = false;
      AppSettings.loginDate = null;
      Navigator.of(context).popUntil((route) => route.isFirst);
    } on TokenStorageException catch (error) {
      if (mounted) {
        await Dialogs.showSimpleDialog(
          context,
          title: 'No se pudo cerrar sesión',
          message: error.message,
          icon: Icons.error_outline_rounded,
          color: Theme.of(context).colorScheme.error,
          duration: 2200,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoggingOut = false);
    }
  }

  Future<void> _onFilterPressed() async {
    final selected = await showModalBottomSheet<CompanyFilters>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      barrierColor: Theme.of(context).colorScheme.scrim.withValues(alpha: .5),
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Style.getCircularBorderRadius(24).topLeft,
        ),
      ),
      builder: (context) => CompanyFiltersSheet(
        initialFilters: _companyController.filters,
        options: _companyController.filterOptions,
      ),
    );
    if (selected != null) _companyController.setFilters(selected);
  }

  void _openCompanies() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MultiProvider(
          providers: [
            ChangeNotifierProvider<CompanyController>.value(
              value: _companyController,
            ),
            ChangeNotifierProvider<FavoritosController>.value(
              value: _favoritosController,
            ),
          ],
          child: CompaniesScreen(
            initialQuery: _companyController.query,
            userRole: widget.user.role,
            resenasService: context.read<ResenasService>(),
            solicitudesService: widget.solicitudesService,
            onSolicitudesUpdated: _refreshNotificationCount,
          ),
        ),
      ),
    );
  }

  void _openCompanyDetail(CompanyModel company) {
    FocusManager.instance.primaryFocus?.unfocus();
    Navigator.of(context)
        .push(
          MaterialPageRoute<void>(
            builder: (_) => MultiProvider(
              providers: [
                ChangeNotifierProvider<CompanyController>.value(
                  value: _companyController,
                ),
                ChangeNotifierProvider<FavoritosController>.value(
                  value: _favoritosController,
                ),
              ],
              child: CompanyDetailScreen(
                company: company,
                userRole: widget.user.role,
                resenasService: context.read<ResenasService>(),
                solicitudesService: widget.solicitudesService,
                onSolicitudesUpdated: _refreshNotificationCount,
              ),
            ),
          ),
        )
        .then((_) {
          if (mounted) FocusScope.of(context).unfocus();
        });
  }

  void _openProfile() {
    final notificationController = Provider.of<NotificacionesController>(
      context,
      listen: false,
    );
    final userProfileController = Provider.of<UserProfileController>(
      context,
      listen: false,
    );
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MultiProvider(
          providers: [
            ChangeNotifierProvider<NotificacionesController>.value(
              value: notificationController,
            ),
            ChangeNotifierProvider<CompanyController>.value(
              value: _companyController,
            ),
            ChangeNotifierProvider<FavoritosController>.value(
              value: _favoritosController,
            ),
            ChangeNotifierProvider<UserProfileController>.value(
              value: userProfileController,
            ),
          ],
          child: ProfileScreen(
            authService: widget.authService,
            resenasService: context.read<ResenasService>(),
            solicitudesService: widget.solicitudesService,
            onSolicitudesUpdated: _refreshNotificationCount,
            onLogout: _logout,
            userRole: widget.user.role,
            profileController: userProfileController,
            onUnauthorized: widget.onUnauthorized ?? _logout,
            onAccountDeleted: widget.onAccountDeleted ?? _logout,
          ),
        ),
      ),
    );
  }

  void _openNotifications() {
    final notificationController = Provider.of<NotificacionesController>(
      context,
      listen: false,
    );
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ChangeNotifierProvider<NotificacionesController>.value(
          value: notificationController,
          child: NotificacionesScreen(
            userRole: widget.user.role,
            solicitudesService: widget.solicitudesService,
            resenasService: context.read<ResenasService>(),
            onSolicitudesUpdated: _refreshNotificationCount,
          ),
        ),
      ),
    );
  }

  void _openFavorites() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MultiProvider(
          providers: [
            ChangeNotifierProvider<CompanyController>.value(
              value: _companyController,
            ),
            ChangeNotifierProvider<FavoritosController>.value(
              value: _favoritosController,
            ),
          ],
          child: FavoritosScreen(
            userRole: widget.user.role,
            resenasService: context.read<ResenasService>(),
            solicitudesService: widget.solicitudesService,
            onSolicitudesUpdated: _refreshNotificationCount,
          ),
        ),
      ),
    );
  }

  void _onDrawerOption(String option) {
    setState(() => _isDrawerOpen = false);
    switch (option) {
      case 'Mi perfil':
        _openProfile();
        break;
      case 'Empresas':
        _openCompanies();
        break;
      case 'Mis solicitudes':
        _openMyRequests();
        break;
      case 'Mis citas':
        widget.onCalendar?.call();
        break;
      case 'Mis empresas favoritas':
        _openFavorites();
        break;
      case 'Notificaciones':
        _openNotifications();
        break;
    }
  }

  Future<void> _confirmLogout() async {
    setState(() => _isDrawerOpen = false);
    final confirmed = await Dialogs.showConfirmDialogDelete(
      context,
      title: 'Cerrar sesión',
      message: '¿Deseas salir de tu cuenta?',
      icon: Icons.logout_rounded,
      confirmText: 'Cerrar sesión',
      cancelText: 'Cancelar',
      confirmColor: Theme.of(context).colorScheme.error,
      cancelColor: Theme.of(context).colorScheme.surfaceContainerHigh,
    );
    if (confirmed == true) await _logout();
  }

  Future<void> _refreshNotificationCount() =>
      context.read<NotificacionesController>().refreshCount();

  void _openMyRequests() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MisSolicitudesScreen(
          service: widget.solicitudesService,
          resenasService: context.read<ResenasService>(),
          userRole: widget.user.role,
          onSolicitudesUpdated: _refreshNotificationCount,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return ChangeNotifierProvider<CompanyController>.value(
      value: _companyController,
      child: Builder(builder: _buildScreen),
    );
  }

  Widget _buildScreen(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return PopScope(
      canPop: !_isDrawerOpen,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _isDrawerOpen) {
          setState(() => _isDrawerOpen = false);
        }
      },
      child: Scaffold(
        backgroundColor: colors.surface,
        body: SafeArea(
          child: Stack(
            children: [
              _buildHomeContent(context),
              if (_isDrawerOpen) ...[
                Positioned.fill(
                  child: GestureDetector(
                    onTap: () => setState(() => _isDrawerOpen = false),
                    child: ColoredBox(
                      color: colors.scrim.withValues(alpha: .42),
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: MediaQuery.sizeOf(context).width * .8,
                  child: UserDrawer(
                    name: widget.user.name,
                    role: widget.user.role,
                    onClose: () => setState(() => _isDrawerOpen = false),
                    onSettings: () {
                      setState(() => _isDrawerOpen = false);
                      widget.onSettings?.call();
                    },
                    onLogout: _confirmLogout,
                    onOption: _onDrawerOption,
                    showStudentOptions:
                        widget.user.role.trim().toLowerCase() == 'estudiante',
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHomeContent(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return RefreshIndicator(
      onRefresh: _companyController.refresh,
      child: AnimatedBuilder(
        animation: _companyController,
        builder: (context, _) {
          final companies = _companyController.companies;
          final featuredCompanies = _companyController.unfilteredCompanies;
          final filters = _companyController.filters;
          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            children: [
              Row(
                children: [
                  IconButton(
                    tooltip: 'Abrir menú',
                    onPressed: () => setState(() => _isDrawerOpen = true),
                    icon: Icon(Icons.menu_rounded, color: colors.onSurface),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '¡Bienvenido de nuevo!',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: colors.onSurfaceVariant),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          widget.user.name,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: colors.onSurface,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ],
                    ),
                  ),
                  NotificationBellButton(onPressed: _openNotifications),
                  UserAvatar(name: widget.user.name, onTap: _openProfile),
                ],
              ),
              const SizedBox(height: 23),
              CompanySearchFilters(
                controller: _searchController,
                hintText: 'Buscar empresa por nombre',
                onSearch: _companyController.setQuery,
                filtersActive: filters.hasActiveFilters,
                onFilterPressed: _onFilterPressed,
              ),
              const SizedBox(height: 24),
              HomeSectionHeading(
                title: 'Empresas destacadas',
                onViewAll: _openCompanies,
              ),
              const SizedBox(height: 11),
              if (_companyController.isLoadingUnfiltered &&
                  featuredCompanies.isEmpty)
                Shimmer.fromColors(
                  baseColor: colors.surfaceContainerHighest,
                  highlightColor: colors.surface,
                  child: Container(
                    height: 180,
                    decoration: BoxDecoration(
                      color: colors.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(26),
                    ),
                  ),
                )
              else if (featuredCompanies.isNotEmpty)
                FeaturedCompaniesCarousel(
                  companies: featuredCompanies.take(4).toList(),
                  onTap: _openCompanyDetail,
                  resenasService: context.read<ResenasService>(),
                )
              else if (_companyController.unfilteredError != null)
                _CompanyLoadError(
                  message: _companyController.unfilteredError!,
                  onRetry: _companyController.refresh,
                )
              else
                const _CompanyEmptyState(
                  message: 'No hay empresas destacadas por ahora.',
                ),
              const SizedBox(height: 24),
              HomeSectionHeading(title: 'Empresas', onViewAll: _openCompanies),
              const SizedBox(height: 11),
              if (_companyController.isLoading)
                _CompanyGridSkeleton(colors: colors)
              else if (_companyController.error != null)
                _CompanyLoadError(
                  message: _companyController.error!,
                  onRetry: _companyController.refresh,
                )
              else if (companies.isEmpty)
                _CompanyEmptyState(
                  message:
                      filters.hasActiveFilters ||
                          _companyController.query.isNotEmpty
                      ? 'No se encontraron empresas con esos criterios.'
                      : 'No hay empresas disponibles.',
                )
              else
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: companies.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 1,
                    mainAxisSpacing: 12,
                    mainAxisExtent: 158,
                  ),
                  itemBuilder: (context, index) {
                    final company = companies[index];
                    return CompanyCard(
                      company: company,
                      resenasService: context.read<ResenasService>(),
                      onTap: () => _openCompanyDetail(company),
                    );
                  },
                ),
              SizedBox(height: QuickMenu.reservedHeight(context) + 8),
            ],
          );
        },
      ),
    );
  }
}

class _CompanyGridSkeleton extends StatelessWidget {
  const _CompanyGridSkeleton({required this.colors});

  final ColorScheme colors;

  @override
  Widget build(BuildContext context) => Shimmer.fromColors(
    baseColor: colors.surfaceContainerHighest,
    highlightColor: colors.surface,
    child: GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 4,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 1,
        mainAxisSpacing: 12,
        mainAxisExtent: 158,
      ),
      itemBuilder: (context, index) => Container(
        decoration: BoxDecoration(
          color: colors.surfaceContainerHighest,
          borderRadius: Style.getCircularBorderRadius(20),
        ),
      ),
    ),
  );
}

class _CompanyLoadError extends StatelessWidget {
  const _CompanyLoadError({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Column(
        children: [
          Icon(Icons.error_outline_rounded, color: colors.error),
          const SizedBox(height: 8),
          Text(
            'No se pudieron cargar las empresas.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 4),
          Text(
            message,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: colors.onSurfaceVariant),
          ),
          TextButton(
            onPressed: () => onRetry(),
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}

class _CompanyEmptyState extends StatelessWidget {
  const _CompanyEmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyMedium
            ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
    );
  }
}
