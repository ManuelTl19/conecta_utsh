import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:conecta_utsh/helpers/providers/app_settings.dart';
import 'package:conecta_utsh/modules/app/components/quick_menu.dart';
import 'package:conecta_utsh/modules/app/models/login_response_model.dart';
import 'package:conecta_utsh/modules/app/screens/home_screen.dart';
import 'package:conecta_utsh/modules/app/services/auth_service.dart';
import 'package:conecta_utsh/modules/app/services/token_store.dart';
import 'package:conecta_utsh/modules/settings/screens/settings_screen.dart';
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
    super.key,
  });

  final LoginUserModel user;
  final AuthService authService;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final DashboardController _dashboardController;
  late final PageController _pageController;
  bool _isShowingExitDialog = false;

  @override
  void initState() {
    super.initState();
    _dashboardController = DashboardController();
    _pageController = PageController(
      initialPage: _dashboardController.selectedIndex,
    );
    _dashboardController._onSelectionChanged = _animateToSelectedTab;
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
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<DashboardController>.value(
      value: _dashboardController,
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
                      const _CalendarTab(),
                      HomeScreen(
                        user: widget.user,
                        authService: widget.authService,
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
    }
  }
}

class _CalendarTab extends StatefulWidget {
  const _CalendarTab();

  @override
  State<_CalendarTab> createState() => _CalendarTabState();
}

class _CalendarTabState extends State<_CalendarTab>
    with AutomaticKeepAliveClientMixin<_CalendarTab> {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.calendar_month_outlined, size: 48, color: colors.primary),
          const SizedBox(height: 12),
          Text('Calendario', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 5),
          Text(
            'Próximamente podrás organizar tus entrevistas.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
