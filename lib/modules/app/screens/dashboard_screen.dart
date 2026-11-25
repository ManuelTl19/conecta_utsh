import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:conecta_utsh/helpers/providers/app_settings.dart';
import 'package:conecta_utsh/modules/app/components/quick_menu.dart';
import 'package:conecta_utsh/modules/calendar/screens/calendar_screen.dart';
import 'package:conecta_utsh/modules/app/models/login_response_model.dart';
import 'package:conecta_utsh/modules/app/screens/home_screen.dart';
import 'package:conecta_utsh/modules/app/screens/login_screen.dart';
import 'package:conecta_utsh/modules/app/screens/change_password_screen.dart';
import 'package:conecta_utsh/modules/app/screens/profile_screen.dart';
import 'package:conecta_utsh/modules/app/providers/user_profile_controller.dart';
import 'package:conecta_utsh/modules/app/services/auth_service.dart';
import 'package:conecta_utsh/modules/app/services/token_store.dart';
import 'package:conecta_utsh/modules/app/services/user_profile_service.dart';
import 'package:conecta_utsh/modules/settings/screens/settings_screen.dart';
import 'package:conecta_utsh/modules/notifications/providers/notificaciones_controller.dart';
import 'package:conecta_utsh/modules/notifications/services/notificaciones_service.dart';
import 'package:conecta_utsh/modules/company/services/company_service.dart';
import 'package:conecta_utsh/modules/company/providers/company_controller.dart';
import 'package:conecta_utsh/modules/favoritos/providers/favoritos_controller.dart';
import 'package:conecta_utsh/modules/favoritos/services/favoritos_service.dart';
import 'package:conecta_utsh/modules/resenas/services/resenas_service.dart';
import 'package:conecta_utsh/modules/solicitudes/services/solicitudes_service.dart';
import 'package:conecta_utsh/utils/widgets/dialogs.dart';

class DashboardController extends ChangeNotifier {
  int _selectedIndex = 1;
  VoidCallback? _onSelectionChanged;

  int get selectedIndex => _selectedIndex;

  void selectTab(int index) {
    if (index < 0 || index > 2 || index == _selectedIndex) return;
    _selectedIndex = index;
    notifyListeners();
    _onSelectionChanged?.call();
  }

  void _updateFromPage(int index) {
    if (_selectedIndex == index) return;
    _selectedIndex = index;
    notifyListeners();
  }

  static DashboardController of(BuildContext context) =>
      Provider.of<DashboardController>(context, listen: false);
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({
    required this.user,
    required this.authService,
    this.companyService,
    super.key,
  });

  final LoginUserModel user;
  final AuthService authService;
  final CompanyService? companyService;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final DashboardController _dashboardController;
  late final PageController _pageController;
  late final NotificacionesController _notificacionesController;
  late final FavoritosController _favoritosController;
  late final UserProfileController _userProfileController;
  late final UserProfileService _userProfileService;
  late final ResenasService _resenasService;
  late final SolicitudesService _solicitudesService;
  bool _isShowingExitDialog = false;
  bool _isLoggingOut = false;

  @override
  void initState() {
    super.initState();
    _dashboardController = DashboardController();
    _userProfileController = UserProfileController(widget.user);
    _userProfileService = UserProfileService(
      authService: widget.authService,
      onUnauthorized: _handleUnauthorized,
    );
    _pageController = PageController(
      initialPage: _dashboardController.selectedIndex,
    );
    _dashboardController._onSelectionChanged = _animateToSelectedTab;
    _notificacionesController = NotificacionesController(
      service: NotificacionesService(
        authService: widget.authService,
        onUnauthorized: _handleUnauthorized,
      ),
    );
    _favoritosController = FavoritosController(
      service: FavoritosService(
        authService: widget.authService,
        onUnauthorized: _handleUnauthorized,
      ),
      userRole: widget.user.role,
    );
    _resenasService = ResenasService(
      authService: widget.authService,
      onUnauthorized: _handleUnauthorized,
    );
    _solicitudesService = SolicitudesService(
      authService: widget.authService,
      onUnauthorized: _handleUnauthorized,
    );
    unawaited(_favoritosController.cargar());
  }

  void _animateToSelectedTab() {
    if (!_pageController.hasClients) return;
    _pageController.animateToPage(
      _dashboardController.selectedIndex,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _dashboardController._onSelectionChanged = null;
    _dashboardController.dispose();
    _notificacionesController.dispose();
    _favoritosController.dispose();
    _userProfileController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<DashboardController>.value(
          value: _dashboardController,
        ),
        ChangeNotifierProvider<NotificacionesController>.value(
          value: _notificacionesController,
        ),
        ChangeNotifierProvider<FavoritosController>.value(
          value: _favoritosController,
        ),
        ChangeNotifierProvider<UserProfileController>.value(
          value: _userProfileController,
        ),
        Provider<ResenasService>.value(value: _resenasService),
        Provider<SolicitudesService>.value(value: _solicitudesService),
      ],
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _showExitDialog();
        },
        child: Scaffold(
          body: SafeArea(
            bottom: false,
            child: Stack(
              children: [
                Positioned.fill(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: _dashboardController._updateFromPage,
                    children: [
                      const CalendarScreen(),
                      HomeScreen(
                        user: widget.user,
                        authService: widget.authService,
                        solicitudesService: _solicitudesService,
                        companyService: widget.companyService,
                        onSettings: () => _dashboardController.selectTab(2),
                        onCalendar: () => _dashboardController.selectTab(0),
                        onLogout: _logout,
                        onUnauthorized: _handleUnauthorized,
                        onAccountDeleted: _handleAccountDeleted,
                      ),
                      SettingsScreen(
                        onLogout: _logout,
                        onOpenProfile: _openProfileFromSettings,
                        onChangePassword: _changePasswordFromSettings,
                        email: widget.user.email,
                      ),
                    ],
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: AnimatedBuilder(
                    animation: _dashboardController,
                    builder: (context, _) => QuickMenu(
                      selectedIndex: _dashboardController.selectedIndex,
                      onSelected: _dashboardController.selectTab,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showExitDialog() async {
    if (_isShowingExitDialog || !mounted) return;
    _isShowingExitDialog = true;
    try {
      await Dialogs.exitDialog(context);
    } finally {
      _isShowingExitDialog = false;
    }
  }

  Future<void> _openProfileFromSettings() async {
    final companyController = CompanyController(
      service:
          widget.companyService ??
          CompanyService(
            authService: widget.authService,
            onUnauthorized: _handleUnauthorized,
          ),
      favoritosController: _favoritosController,
    );
    try {
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => MultiProvider(
            providers: [
              ChangeNotifierProvider<NotificacionesController>.value(
                value: _notificacionesController,
              ),
              ChangeNotifierProvider<CompanyController>.value(
                value: companyController,
              ),
              ChangeNotifierProvider<FavoritosController>.value(
                value: _favoritosController,
              ),
              ChangeNotifierProvider<UserProfileController>.value(
                value: _userProfileController,
              ),
            ],
            child: ProfileScreen(
              authService: widget.authService,
              onLogout: _logout,
              onUnauthorized: _handleUnauthorized,
              onAccountDeleted: _handleAccountDeleted,
              profileController: _userProfileController,
              resenasService: _resenasService,
              solicitudesService: _solicitudesService,
              onSolicitudesUpdated: _notificacionesController.refreshCount,
              userRole: widget.user.role,
            ),
          ),
        ),
      );
    } finally {
      companyController.dispose();
    }
  }

  Future<void> _changePasswordFromSettings() async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) =>
            ChangePasswordScreen(profileService: _userProfileService),
      ),
    );
    if (changed == true && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Contraseña actualizada')));
    }
  }

  Future<void> _logout() async {
    if (_isLoggingOut) return;
    _isLoggingOut = true;
    try {
      await widget.authService.logout();
      if (!mounted) return;
      _clearSessionState();
      AppSettings.isSignedIn = false;
      AppSettings.loginDate = null;
      Navigator.of(context).pushAndRemoveUntil<void>(
        MaterialPageRoute<void>(
          builder: (_) => LoginScreen(authService: widget.authService),
        ),
        (_) => false,
      );
    } on TokenStorageException catch (error) {
      if (!mounted) return;
      await Dialogs.showSimpleDialog(
        context,
        title: 'No se pudo cerrar sesión',
        message: error.message,
        icon: Icons.error_outline_rounded,
        color: Theme.of(context).colorScheme.error,
        duration: 2200,
      );
    } finally {
      _isLoggingOut = false;
    }
  }

  Future<void> _handleUnauthorized() async {
    if (_isLoggingOut) return;
    _isLoggingOut = true;
    try {
      await widget.authService.logout();
      if (!mounted) return;
      _clearSessionState();
      AppSettings.isSignedIn = false;
      AppSettings.loginDate = null;
      Navigator.of(context).pushAndRemoveUntil<void>(
        MaterialPageRoute<void>(
          builder: (_) => LoginScreen(authService: widget.authService),
        ),
        (_) => false,
      );
    } on TokenStorageException catch (error) {
      if (!mounted) return;
      await Dialogs.showSimpleDialog(
        context,
        title: 'No se pudo cerrar sesión',
        message: error.message,
        icon: Icons.error_outline_rounded,
        color: Theme.of(context).colorScheme.error,
        duration: 2200,
      );
    } finally {
      _isLoggingOut = false;
    }
  }

  Future<void> _handleAccountDeleted() async {
    if (_isLoggingOut) return;
    _isLoggingOut = true;
    try {
      await widget.authService.logout();
      if (!mounted) return;
      _clearSessionState();
      AppSettings.isSignedIn = false;
      AppSettings.loginDate = null;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pushAndRemoveUntil<void>(
        MaterialPageRoute<void>(
          builder: (_) => LoginScreen(authService: widget.authService),
        ),
        (_) => false,
      );
      messenger.showSnackBar(
        const SnackBar(content: Text('Tu cuenta fue eliminada')),
      );
    } on TokenStorageException catch (error) {
      if (!mounted) return;
      await Dialogs.showSimpleDialog(
        context,
        title: 'No se pudo completar la operación',
        message: error.message,
        icon: Icons.error_outline_rounded,
        color: Theme.of(context).colorScheme.error,
        duration: 2200,
      );
    } finally {
      _isLoggingOut = false;
    }
  }

  void _clearSessionState() {
    _userProfileController.clear();
    _favoritosController.limpiar();
    _notificacionesController.clearData();
  }
}
