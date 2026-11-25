import 'package:material_ui/material_ui.dart';
import 'package:conecta_utsh/helpers/providers/app_settings.dart';
import 'package:conecta_utsh/modules/app/components/quick_menu.dart';
import 'package:conecta_utsh/modules/settings/components/settings_components.dart';
import 'package:conecta_utsh/modules/settings/models/settings_option_model.dart';
import 'package:conecta_utsh/modules/settings/services/settings_service.dart';
import 'package:conecta_utsh/modules/settings/screens/help_center_screen.dart';
import 'package:conecta_utsh/utils/widgets/dialogs.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    required this.onLogout,
    required this.onOpenProfile,
    required this.onChangePassword,
    required this.email,
    this.settingsService = const SettingsService(),
    super.key,
  });

  final Future<void> Function() onLogout;
  final VoidCallback onOpenProfile;
  final VoidCallback onChangePassword;
  final String email;
  final SettingsService settingsService;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with AutomaticKeepAliveClientMixin<SettingsScreen> {
  Map<String, bool> _values = {};
  bool _isLoading = true;
  Object? _loadError;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final values = await widget.settingsService.loadToggleValues();
      if (!mounted) return;
      setState(() {
        _values = values;
        _isLoading = false;
        _loadError = null;
      });
    } on Exception catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadError = error;
      });
    }
  }

  Future<void> _toggle(SettingsOptionModel option) async {
    if (option.id == 'theme') {
      final saved = await AppSettings().changeTheme();
      if (mounted) {
        if (saved) {
          setState(() {});
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No se pudo guardar el tema.')),
          );
        }
      }
      return;
    }
    final nextValue = !(_values[option.id] ?? false);
    setState(() => _values[option.id] = nextValue);
    try {
      await widget.settingsService.saveToggleValue(option.id, nextValue);
    } on Exception catch (error) {
      if (!mounted) return;
      setState(() => _values[option.id] = !nextValue);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo guardar la opción: $error')),
      );
    }
  }

  void _onOptionPressed(SettingsOptionModel option) {
    switch (option.id) {
      case 'profile':
        widget.onOpenProfile();
        break;
      case 'password':
        widget.onChangePassword();
        break;
      case 'email':
        _showEmail();
        break;
      case 'help':
        Navigator.of(context).push<void>(
          MaterialPageRoute<void>(builder: (_) => const HelpCenterScreen()),
        );
        break;
      case 'about':
        showAboutDialog(
          context: context,
          applicationName: 'Conecta UTSH',
          applicationVersion: '0.1.0+1',
          applicationIcon: const Icon(Icons.hub_outlined, size: 36),
        );
        break;
    }
  }

  Future<void> _showEmail() => showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Correo electrónico'),
      content: Text(
        widget.email.isEmpty
            ? 'No hay un correo registrado en esta sesión.'
            : widget.email,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cerrar'),
        ),
      ],
    ),
  );

  Future<void> _confirmLogout() async {
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
    if (confirmed == true) await widget.onLogout();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final colors = Theme.of(context).colorScheme;
    final sections = settingsOptions
        .map((option) => option.section)
        .toSet()
        .toList();
    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 9),
              child: Center(
                child: Text(
                  'Configuraciones',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _loadError != null
                  ? _ErrorState(
                      message: _loadError.toString(),
                      onRetry: _loadSettings,
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(20, 6, 20, 24),
                      children: [
                        Text(
                          'Personaliza tu experiencia en Conecta UTSH.',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: colors.onSurfaceVariant),
                        ),
                        const SizedBox(height: 17),
                        for (final section in sections) ...[
                          SettingsSectionCard(
                            title: section,
                            options: settingsOptions
                                .where((option) => option.section == section)
                                .toList(),
                            values: {
                              ..._values,
                              'theme': AppSettings.isDarkModeOn,
                            },
                            onToggle: _toggle,
                            onOptionPressed: _onOptionPressed,
                          ),
                          const SizedBox(height: 16),
                        ],
                        SettingsOptionTile(
                          option: const SettingsOptionModel(
                            section: 'Cuenta',
                            id: 'logout',
                            label: 'Cerrar sesión',
                            icon: Icons.logout_rounded,
                            type: SettingsOptionType.destructive,
                          ),
                          value: false,
                          destructive: true,
                          onToggle: () {},
                          onPressed: _confirmLogout,
                        ),
                        SizedBox(height: QuickMenu.reservedHeight(context) + 8),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 32,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 10),
          const Text('No se pudieron cargar las configuraciones.'),
          const SizedBox(height: 4),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Reintentar')),
        ],
      ),
    ),
  );
}
