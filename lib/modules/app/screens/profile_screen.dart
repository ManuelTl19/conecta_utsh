import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:resize/resize.dart';
import 'package:shimmer/shimmer.dart';
import 'package:conecta_utsh/helpers/style.dart';
import 'package:conecta_utsh/modules/app/components/home_components.dart';
import 'package:conecta_utsh/modules/app/components/primary_button.dart';
import 'package:conecta_utsh/modules/app/providers/user_profile_controller.dart';
import 'package:conecta_utsh/modules/app/models/user_profile_model.dart';
import 'package:conecta_utsh/modules/app/screens/edit_profile_screen.dart';
import 'package:conecta_utsh/modules/app/screens/change_password_screen.dart';
import 'package:conecta_utsh/modules/app/screens/delete_account_screen.dart';
import 'package:conecta_utsh/modules/app/services/auth_service.dart';
import 'package:conecta_utsh/modules/app/services/user_profile_service.dart';
import 'package:conecta_utsh/modules/company/providers/company_controller.dart';
import 'package:conecta_utsh/modules/favoritos/providers/favoritos_controller.dart';
import 'package:conecta_utsh/modules/favoritos/screens/favoritos_screen.dart';
import 'package:conecta_utsh/modules/notifications/components/notification_bell_button.dart';
import 'package:conecta_utsh/modules/notifications/providers/notificaciones_controller.dart';
import 'package:conecta_utsh/modules/notifications/screens/notificaciones_screen.dart';
import 'package:conecta_utsh/utils/widgets/dialogs.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    required this.authService,
    required this.onLogout,
    required this.onUnauthorized,
    required this.onAccountDeleted,
    required this.profileController,
    this.userRole,
    super.key,
  });

  final AuthService authService;
  final Future<void> Function() onLogout;
  final Future<void> Function() onUnauthorized;
  final Future<void> Function() onAccountDeleted;
  final UserProfileController profileController;
  final String? userRole;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final UserProfileService _profileService;
  UserProfile? _profile;
  String? _loadError;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _profile = widget.profileController.profile;
    _isLoading = !_hasProfileData(_profile);
    _profileService = UserProfileService(
      authService: widget.authService,
      onUnauthorized: widget.onUnauthorized,
    );
    _loadProfile();
  }

  bool _hasProfileData(UserProfile? profile) =>
      profile != null &&
      (profile.nombre.isNotEmpty ||
          profile.correo.isNotEmpty ||
          profile.id.isNotEmpty);

  Future<void> _loadProfile({bool showRefreshMessage = false}) async {
    if (mounted) {
      setState(() {
        _loadError = null;
        if (!_hasProfileData(_profile)) _isLoading = true;
      });
    }
    try {
      final profile = await _profileService.obtenerPerfil(
        fallback: widget.profileController.profile,
      );
      if (!mounted) return;
      widget.profileController.update(profile);
      setState(() {
        _profile = profile;
        _isLoading = false;
        _loadError = null;
      });
    } on UserProfileApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _loadError = error.message;
        _isLoading = false;
      });
      if (showRefreshMessage && _hasProfileData(_profile)) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(error.message)));
      }
    }
  }

  Future<void> _editProfile() async {
    final profile = _profile;
    if (profile == null) return;
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => EditProfileScreen(
          profile: profile,
          profileService: _profileService,
          profileController: widget.profileController,
        ),
      ),
    );
    if (saved == true && mounted) {
      setState(() => _profile = widget.profileController.profile);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Perfil actualizado')));
    }
  }

  Future<void> _changePassword() async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => ChangePasswordScreen(profileService: _profileService),
      ),
    );
    if (changed == true && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Contraseña actualizada')));
    }
  }

  Future<void> _deleteAccount() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => DeleteAccountScreen(
          profileService: _profileService,
          onUnauthorized: widget.onUnauthorized,
          onAccountDeleted: widget.onAccountDeleted,
        ),
      ),
    );
  }

  Future<void> _confirmLogout() async {
    final shouldLogout = await Dialogs.showConfirmDialogDelete(
      context,
      title: 'Cerrar sesión',
      message: '¿Deseas salir de tu cuenta?',
      icon: Icons.logout_rounded,
      confirmText: 'Cerrar sesión',
      cancelText: 'Cancelar',
      confirmColor: Theme.of(context).colorScheme.error,
      cancelColor: Theme.of(context).colorScheme.surfaceContainerHigh,
    );
    if (shouldLogout == true) await widget.onLogout();
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
          child: NotificacionesScreen(userRole: widget.userRole),
        ),
      ),
    );
  }

  void _openFavorites() {
    final favoritesController = context.read<FavoritosController>();
    final companyController = context.read<CompanyController>();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MultiProvider(
          providers: [
            ChangeNotifierProvider<FavoritosController>.value(
              value: favoritesController,
            ),
            ChangeNotifierProvider<CompanyController>.value(
              value: companyController,
            ),
          ],
          child: const FavoritosScreen(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        title: const Text('Mi perfil'),
        backgroundColor: colors.surface,
        foregroundColor: colors.onSurface,
        surfaceTintColor: Colors.transparent,
        actions: [NotificationBellButton(onPressed: _openNotifications)],
      ),
      body: _isLoading
          ? _buildProfileSkeleton(colors)
          : _loadError != null && !_hasProfileData(_profile)
          ? _buildLoadError(context)
          : _profile == null
          ? _buildLoadError(context)
          : RefreshIndicator(
              onRefresh: () => _loadProfile(showRefreshMessage: true),
              child: _buildProfile(context, _profile!),
            ),
    );
  }

  Widget _buildLoadError(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: Style.getPaddingSymmetric(horizontal: 28, vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, color: colors.error, size: 34),
            SizedBox(height: 12.h),
            Text(
              'No se pudo cargar tu perfil.',
              textAlign: TextAlign.center,
              style: Style.getHeaderTwo(
                color: colors.onSurface,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (_loadError != null) ...[
              SizedBox(height: 6.h),
              Text(
                _loadError!,
                textAlign: TextAlign.center,
                style: Style.getTextStyle(
                  color: colors.onSurfaceVariant,
                  fontSize: 10,
                ),
              ),
            ],
            SizedBox(height: 14.h),
            TextButton(
              onPressed: () => _loadProfile(),
              child: Text(
                'Reintentar',
                style: Style.getHeaderThree(
                  color: colors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSkeleton(ColorScheme colors) => Shimmer.fromColors(
    baseColor: colors.surfaceContainerHighest,
    highlightColor: colors.surface,
    child: ListView(
      padding: Style.getPaddingSymmetric(horizontal: 22, vertical: 18),
      children: [
        Center(
          child: Column(
            children: [
              CircleAvatar(
                radius: 52,
                backgroundColor: colors.surfaceContainerHighest,
              ),
              SizedBox(height: 14.h),
              Container(
                width: 190,
                height: 22,
                decoration: BoxDecoration(
                  color: colors.surfaceContainerHighest,
                  borderRadius: Style.getCircularBorderRadius(8),
                ),
              ),
              SizedBox(height: 8.h),
              Container(
                width: 150,
                height: 16,
                decoration: BoxDecoration(
                  color: colors.surfaceContainerHighest,
                  borderRadius: Style.getCircularBorderRadius(8),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 24.h),
        Container(
          height: 82,
          decoration: BoxDecoration(
            color: colors.surfaceContainerHighest,
            borderRadius: Style.getCircularBorderRadius(18),
          ),
        ),
        SizedBox(height: 20.h),
        for (var index = 0; index < 5; index++) ...[
          Container(
            height: 72,
            margin: EdgeInsets.only(bottom: 10.h),
            decoration: BoxDecoration(
              color: colors.surfaceContainerHighest,
              borderRadius: Style.getCircularBorderRadius(18),
            ),
          ),
        ],
      ],
    ),
  );

  Widget _buildProfile(BuildContext context, UserProfile profile) {
    final colors = Theme.of(context).colorScheme;
    final favoritesController = context.watch<FavoritosController>();
    final details = [
      (
        label: 'Correo electrónico',
        value: profile.correo,
        icon: Icons.email_outlined,
      ),
      (
        label: 'Teléfono',
        value: profile.telefono == null || profile.telefono!.trim().isEmpty
            ? 'Sin teléfono registrado'
            : profile.telefono!,
        icon: Icons.phone_outlined,
      ),
      (
        label: 'Matrícula',
        value: profile.matricula,
        icon: Icons.badge_outlined,
      ),
      (
        label: 'Dirección académica',
        value: profile.direccion,
        icon: Icons.account_balance_outlined,
      ),
      (label: 'Carrera', value: profile.carrera, icon: Icons.school_outlined),
      (
        label: 'Cuatrimestre',
        value: profile.cuatrimestre > 0
            ? '${profile.cuatrimestre}.º cuatrimestre'
            : 'No disponible',
        icon: Icons.calendar_month_outlined,
      ),
    ];

    return ListView(
      padding: Style.getPaddingSymmetric(horizontal: 22, vertical: 18),
      children: [
        Center(
          child: Column(
            children: [
              UserAvatar(
                name: profile.nombreCompleto,
                initials: profile.iniciales,
                size: 104,
              ),
              SizedBox(height: 14.h),
              Text(
                profile.nombreCompletoPresentacion,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: colors.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 5.h),
              Text(
                profile.carrera,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(color: colors.onSurfaceVariant),
              ),
            ],
          ),
        ),
        SizedBox(height: 24.h),
        Row(
          children: [
            Expanded(
              child: _ProfileSummaryCard(
                label: 'Favoritos',
                value: favoritesController.hasLoaded
                    ? '${favoritesController.count}'
                    : '—',
                icon: Icons.favorite_border_rounded,
              ),
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: _ProfileSummaryCard(
                label: 'Estadía',
                value: profile.estadoEstadia?.trim().isNotEmpty == true
                    ? profile.estadoEstadia!
                    : 'Sin iniciar',
                icon: Icons.work_outline_rounded,
              ),
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: _ProfileSummaryCard(
                label: 'Citas',
                value: '${profile.citasActivas}',
                icon: Icons.event_available_outlined,
              ),
            ),
          ],
        ),
        SizedBox(height: 22.h),
        for (final detail in details) ...[
          _ProfileInfoCard(
            label: detail.label,
            value: detail.value,
            icon: detail.icon,
          ),
          SizedBox(height: 10.h),
        ],
        SizedBox(height: 10.h),
        Text(
          'Accesos',
          style: Style.getHeaderTwo(
            color: colors.onSurface,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 8.h),
        if (_loadError != null) ...[
          Container(
            margin: EdgeInsets.only(bottom: 8.h),
            padding: Style.getPaddingAll(12),
            decoration: BoxDecoration(
              color: colors.errorContainer,
              borderRadius: Style.getCircularBorderRadius(12),
            ),
            child: Text(
              'No se pudieron actualizar tus datos. ${_loadError!}',
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: colors.onErrorContainer),
            ),
          ),
        ],
        _ProfileAccessItem(
          label: 'Mis empresas favoritas',
          icon: Icons.bookmark_border_rounded,
          onTap: _openFavorites,
        ),
        Builder(
          builder: (context) {
            final notificationController = context
                .watch<NotificacionesController>();
            return _ProfileAccessItem(
              label: 'Notificaciones',
              icon: Icons.notifications_none_rounded,
              trailing: notificationController.unreadCount > 0
                  ? '${notificationController.unreadCount}'
                  : null,
              onTap: _openNotifications,
            );
          },
        ),
        _ProfileAccessItem(
          label: 'Cambiar contraseña',
          icon: Icons.lock_outline_rounded,
          onTap: _changePassword,
        ),
        if (profile.esEstudiante)
          _ProfileAccessItem(
            label: 'Eliminar cuenta',
            icon: Icons.delete_outline_rounded,
            color: colors.error,
            onTap: _deleteAccount,
          ),
        _ProfileAccessItem(
          label: 'Cerrar sesión',
          icon: Icons.logout_rounded,
          color: colors.error,
          onTap: _confirmLogout,
        ),
        SizedBox(height: 18.h),
        PrimaryButton(label: 'Editar perfil', onPressed: _editProfile),
        SizedBox(height: 20.h),
      ],
    );
  }
}

class _ProfileSummaryCard extends StatelessWidget {
  const _ProfileSummaryCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: Style.getPaddingSymmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Icon(icon, color: colors.primary, size: 20),
          SizedBox(height: 6.h),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: Style.getHeaderTwo(
              color: colors.onSurface,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 3.h),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: Style.getTextStyle(
              color: colors.onSurfaceVariant,
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileInfoCard extends StatelessWidget {
  const _ProfileInfoCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: Style.getPaddingAll(16),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: colors.primary),
          SizedBox(width: 13.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelMedium
                      ?.copyWith(color: colors.onSurfaceVariant),
                ),
                SizedBox(height: 4.h),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(color: colors.onSurface),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileAccessItem extends StatelessWidget {
  const _ProfileAccessItem({
    required this.label,
    required this.icon,
    this.color,
    this.onTap,
    this.trailing,
  });

  final String label;
  final IconData icon;
  final Color? color;
  final VoidCallback? onTap;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final foreground = color ?? colors.onSurface;
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: Style.getPaddingSymmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(icon, color: color ?? colors.primary),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    label,
                    style: Style.getHeaderThree(
                      color: foreground,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (trailing != null)
                  Padding(
                    padding: EdgeInsets.only(right: 8.w),
                    child: Text(
                      trailing!,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: foreground,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: color ?? colors.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
