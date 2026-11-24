import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:conecta_utsh/helpers/providers/app_settings.dart';
import 'package:conecta_utsh/modules/app/components/quick_menu.dart';
import 'package:conecta_utsh/modules/calendar/screens/calendar_screen.dart';
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
      child: Scaffold(
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: _dashboardController._updateFromPage,
                  children: [
                    const CalendarScreen(), // <-- Pantalla separada
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
              AnimatedBuilder(
                animation: _dashboardController,
                builder: (context, _) => QuickMenu(
                  selectedIndex: _dashboardController.selectedIndex,
                  onSelected: _dashboardController.selectTab,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ... (_logout igual que antes)


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
