import 'package:material_ui/material_ui.dart';

import 'package:conecta_utsh/helpers/providers/app_settings.dart';
import 'package:conecta_utsh/helpers/style.dart';
import 'package:conecta_utsh/modules/app/models/login_response_model.dart';
import 'package:conecta_utsh/modules/app/services/auth_service.dart';
import 'package:conecta_utsh/modules/app/services/token_store.dart';
import 'package:conecta_utsh/utils/widgets/dialogs.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({required this.user, required this.authService, super.key});

  final LoginUserModel user;
  final AuthService authService;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoggingOut = false;

  Future<void> _logout() async {
    setState(() => _isLoggingOut = true);
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
          color: Style.getErrorColor(),
          duration: 2200,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoggingOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Style.getBackgroundColor(),
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(
            'Inicio',
            style: Style.getHeaderOne(
              color: Style.getTextColor(),
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          actions: [
            IconButton(
              tooltip: 'Cerrar sesión',
              onPressed: _isLoggingOut ? null : _logout,
              icon: _isLoggingOut
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.logout),
            ),
          ],
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '¡Hola, ${widget.user.name}!',
                  style: Style.getHeaderOne(
                    color: Style.getTextColor(),
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Bienvenido a Vincula UTSH.',
                  style: Style.getHeaderThree(
                    color: Style.getObscureTextColor(),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 24),
                Card(
                  color: Style.getCardColor(),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Icon(
                          Icons.school_outlined,
                          color: Style.getPrimaryColor(),
                          size: 32,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            'Tu espacio para conectar con oportunidades '
                            'profesionales estará aquí.',
                            style: Style.getHeaderThree(
                              color: Style.getTextColor(),
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
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
}
