import 'package:material_ui/material_ui.dart';
import 'package:conecta_utsh/helpers/providers/app_settings.dart';
import 'package:conecta_utsh/modules/app/components/home_components.dart';
import 'package:conecta_utsh/modules/app/components/user_drawer.dart';
import 'package:conecta_utsh/modules/app/models/login_response_model.dart';
import 'package:conecta_utsh/modules/app/services/auth_service.dart';
import 'package:conecta_utsh/modules/app/services/token_store.dart';
import 'package:conecta_utsh/modules/app/screens/notifications_screen.dart';
import 'package:conecta_utsh/modules/app/screens/profile_screen.dart';
import 'package:conecta_utsh/modules/company/components/company_cards.dart';
import 'package:conecta_utsh/modules/company/components/featured_companies_carousel.dart';
import 'package:conecta_utsh/modules/company/models/company_model.dart';
import 'package:conecta_utsh/modules/company/services/company_service.dart';
import 'package:conecta_utsh/utils/widgets/dialogs.dart';
import 'package:shimmer/shimmer.dart';
import 'package:conecta_utsh/modules/company/screens/company_screen.dart';
class HomeScreen extends StatefulWidget {
  const HomeScreen({
    required this.user,
    required this.authService,
    this.companyService = const CompanyService(),
    this.onSettings,
    this.onLogout,
    super.key,
  });

  final LoginUserModel user;
  final AuthService authService;
  final CompanyService companyService;
  final VoidCallback? onSettings;
  final Future<void> Function()? onLogout;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}
// 1. Agrega este import arriba junto a los demás de company:
class _HomeScreenState extends State<HomeScreen>
    with AutomaticKeepAliveClientMixin<HomeScreen> {
  List<CompanyModel> _companies = [];
  List<CompanyModel> _featuredCompanies = [];
  bool _isLoading = true;
  String? _loadError;
  bool _isDrawerOpen = false;
  bool _isLoggingOut = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadCompanies();
  }

  Future<void> _loadCompanies() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final results = await Future.wait([
        widget.companyService.getCompanies(),
        widget.companyService.getFeaturedCompanies(),
      ]);
      if (!mounted) return;
      setState(() {
        _companies = results[0];
        _featuredCompanies = results[1];
        _isLoading = false;
      });
    } on Exception catch (error) {
      if (!mounted) return;
      setState(() {
        _loadError = error.toString();
        _isLoading = false;
      });
    }
  }

  void _toggleSaved(CompanyModel selected) {
    setState(() {
      _companies = _companies
          .map(
            (company) => company.id == selected.id
                ? company.copyWith(isSaved: !company.isSaved)
                : company,
          )
          .toList();
      _featuredCompanies = _featuredCompanies
          .map(
            (company) => company.id == selected.id
                ? company.copyWith(isSaved: !company.isSaved)
                : company,
          )
          .toList();
    });
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
      Navigator.of(context).pop();
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

  void _onSearch(String value) {
    // TODO: conectar con el endpoint de búsqueda de empresas.
  }

  void _onFilterPressed() {
    // TODO: abrir los filtros de vacantes cuando el servicio esté disponible.
  }

  void _onViewAllFeatured() {
    // TODO: mostrar el catálogo completo de empresas destacadas.
  }

  void _onDrawerOption(String option) {
    setState(() => _isDrawerOpen = false);
    if (option == 'Ver perfil') {
      _openProfile();
      return;
    }
    // TODO: navegar al destino de "$option" cuando exista su pantalla.
  }

  void _openProfile() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => ProfileScreen(user: widget.user)),
    );
  }
// 2. Agrega este método junto a _openProfile() y _openNotifications():
  void _openCompanies() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const CompaniesScreen()),
    );
  }
  void _openNotifications() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const NotificationsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
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
              _buildHomeContent(),
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
                    role: 'UX Designer',
                    onClose: () => setState(() => _isDrawerOpen = false),
                    onSettings: () {
                      setState(() => _isDrawerOpen = false);
                      widget.onSettings?.call();
                    },
                    onLogout: _logout,
                    onOption: _onDrawerOption,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHomeContent() {
    final colors = Theme.of(context).colorScheme;
    return ListView(
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
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: colors.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Notificaciones',
              onPressed: _openNotifications,
              icon: Badge(
                isLabelVisible: true,
                backgroundColor: colors.error,
                smallSize: 8,
                child: Icon(
                  Icons.notifications_none_rounded,
                  color: colors.onSurfaceVariant,
                ),
              ),
            ),
            UserAvatar(name: widget.user.name, onTap: _openProfile),
          ],
        ),
        const SizedBox(height: 23),
        HomeSearchBar(onSearch: _onSearch, onFilterPressed: _onFilterPressed),
        const SizedBox(height: 24),
        HomeSectionHeading(
          title: 'Empresas destacadas',
          onViewAll: _onViewAllFeatured,
        ),
        const SizedBox(height: 11),
        if (_isLoading)
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
        else if (_loadError != null)
          _LoadError(message: _loadError!, onRetry: _loadCompanies)
        else if (_featuredCompanies.isEmpty)
          const _EmptyState(message: 'No hay empresas destacadas por ahora.')
        else
          FeaturedCompaniesCarousel(
            companies: _featuredCompanies,
            onSave: _toggleSaved,
          ),
        const SizedBox(height: 24),
        HomeSectionHeading(
          title: 'Empresas',
          onViewAll: _openCompanies,///agregue esta linea
        ),
        const SizedBox(height: 11),
        if (_isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            ),
          )
        else if (_loadError != null)
          _LoadError(message: _loadError!, onRetry: _loadCompanies)
        else if (_companies.isEmpty)
          const _EmptyState(message: 'No hay empresas disponibles.')
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _companies.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              mainAxisExtent: 164,
            ),
            itemBuilder: (context, index) =>
                CompanyCard(company: _companies[index]),
          ),
      ],
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

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
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: colors.onSurface),
          ),
          const SizedBox(height: 4),
          TextButton(onPressed: onRetry, child: const Text('Reintentar')),
          Text(
            message,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: colors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyMedium
            ?.copyWith(color: colors.onSurfaceVariant),
      ),
    );
  }
}
