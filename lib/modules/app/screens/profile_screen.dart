import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:resize/resize.dart';
import 'package:conecta_utsh/helpers/style.dart';
import 'package:conecta_utsh/modules/app/components/home_components.dart';
import 'package:conecta_utsh/modules/app/components/primary_button.dart';
import 'package:conecta_utsh/modules/app/models/user_profile_model.dart';
import 'package:conecta_utsh/modules/app/screens/edit_profile_screen.dart';
import 'package:conecta_utsh/modules/app/screens/forgot_password_email_screen.dart';
import 'package:conecta_utsh/modules/app/services/auth_service.dart';
import 'package:conecta_utsh/modules/app/services/user_profile_service.dart';
import 'package:conecta_utsh/modules/notifications/components/notification_bell_button.dart';
import 'package:conecta_utsh/modules/notifications/providers/notificaciones_controller.dart';
import 'package:conecta_utsh/modules/notifications/screens/notificaciones_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    required this.authService,
    required this.onLogout,
    this.userRole,
    super.key,
  });

  final AuthService authService;
  final Future<void> Function() onLogout;
  final String? userRole;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final UserProfileService _profileService;
  UserProfile? _profile;
  Object? _loadError;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _profileService = UserProfileService(authService: widget.authService);
    _loadProfile();
  }

  @override
  void dispose() {
    _profileService.close();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final profile = await _profileService.getCurrentUser();
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _isLoading = false;
      });
    } on Exception catch (error) {
      if (!mounted) return;
      setState(() {
        _loadError = error;
        _isLoading = false;
      });
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
        ),
      ),
    );
    if (saved == true && mounted) await _loadProfile();
  }

  Future<void> _changePassword() async {
    final profile = _profile;
    if (profile == null) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => ForgotPasswordEmailScreen(
          authService: widget.authService,
          initialEmail: profile.correo,
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
          child: NotificacionesScreen(userRole: widget.userRole),
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
          ? Center(child: CircularProgressIndicator(color: colors.primary))
          : _loadError != null
          ? _buildLoadError(context)
          : _profile == null
          ? _buildLoadError(context)
          : _buildProfile(context, _profile!),
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
                _loadError.toString(),
                textAlign: TextAlign.center,
                style: Style.getTextStyle(
                  color: colors.onSurfaceVariant,
                  fontSize: 10,
                ),
              ),
            ],
            SizedBox(height: 14.h),
            TextButton(
              onPressed: _loadProfile,
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

  Widget _buildProfile(BuildContext context, UserProfile profile) {
    final colors = Theme.of(context).colorScheme;
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
        value: '${profile.cuatrimestre}',
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
                name: '${profile.nombre} ${profile.apellidoPaterno}',
                size: 104,
              ),
              SizedBox(height: 14.h),
              Text(
                profile.nombreCompleto,
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
                value: '${profile.favoriteCount}',
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
        _ProfileAccessItem(
          label: 'Mis empresas favoritas',
          icon: Icons.favorite_border_rounded,
        ),
        _ProfileAccessItem(
          label: 'Mi proceso de estadía',
          icon: Icons.work_outline_rounded,
        ),
        _ProfileAccessItem(
          label: 'Mis citas',
          icon: Icons.event_available_outlined,
        ),
        _ProfileAccessItem(
          label: 'Cambiar contraseña',
          icon: Icons.lock_outline_rounded,
          onTap: _changePassword,
        ),
        _ProfileAccessItem(
          label: 'Cerrar sesión',
          icon: Icons.logout_rounded,
          color: colors.error,
          onTap: widget.onLogout,
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
  });

  final String label;
  final IconData icon;
  final Color? color;
  final VoidCallback? onTap;

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
