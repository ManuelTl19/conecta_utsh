import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:conecta_utsh/helpers/providers/app_settings.dart';
import 'package:conecta_utsh/modules/app/components/quick_menu.dart';
import 'package:conecta_utsh/modules/calendar/screens/calendar_screen.dart';
import 'package:conecta_utsh/modules/app/models/login_response_model.dart';
import 'package:conecta_utsh/modules/app/screens/home_screen.dart';
import 'package:conecta_utsh/modules/app/screens/login_screen.dart';
import 'package:conecta_utsh/modules/app/services/auth_service.dart';
import 'package:conecta_utsh/modules/app/services/token_store.dart';
import 'package:conecta_utsh/modules/settings/screens/settings_screen.dart';
import 'package:conecta_utsh/modules/notifications/providers/notificaciones_controller.dart';
import 'package:conecta_utsh/modules/notifications/services/notificaciones_service.dart';
import 'package:conecta_utsh/modules/company/services/company_service.dart';
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
  bool _isShowingExitDialog = false;
  bool _isLoggingOut = false;

  @override
  void initState() {
    super.initState();
    _dashboardController = DashboardController();
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
                        companyService: widget.companyService,
                        onSettings: () => _dashboardController.selectTab(2),
                        onLogout: _logout,
                      ),
                      SettingsScreen(
                        onLogout: _logout,
                        onBack: () => _dashboardController.selectTab(1),
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

  Future<void> _logout() async {
    if (_isLoggingOut) return;
    _isLoggingOut = true;
    try {
      await widget.authService.logout();
      if (!mounted) return;
      AppSettings.isSignedIn = false;
      AppSettings.loginDate = null;
      Navigator.of(context).pop();
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
}
