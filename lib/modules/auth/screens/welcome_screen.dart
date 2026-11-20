import 'package:material_ui/material_ui.dart';

import 'package:conecta_utsh/helpers/assets.dart';
import 'package:conecta_utsh/helpers/constants.dart';
import 'package:conecta_utsh/helpers/navigation.dart';
import 'package:conecta_utsh/helpers/providers/providers.dart';
import 'package:conecta_utsh/helpers/style.dart';
import 'package:conecta_utsh/modules/auth/screens/login_screen.dart';
import 'package:conecta_utsh/modules/auth/widgets/primary_button.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  Future<void> _start(BuildContext context) async {
    final saved = await prefs.setBool(Constants.onboardingKey, true);
    if (!context.mounted) return;
    if (!saved) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo guardar el inicio.')),
      );
      return;
    }
    push(context, const LoginScreen());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Style.getCardColor(),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              flex: 6,
              child: SizedBox(
                width: double.infinity,
                child: Image.asset(
                  Assets.campus,
                  fit: BoxFit.cover,
                  semanticLabel:
                      'Campus de la Universidad Tecnológica '
                      'de la Sierra Hidalguense',
                ),
              ),
            ),
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(26, 18, 26, 16),
                child: Column(
                  children: [
                    Text(
                      'Bienvenid@ a',
                      textAlign: TextAlign.center,
                      style: Style.getHeaderOne(
                        color: Style.getTextColor(),
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Vincula UTSH',
                      textAlign: TextAlign.center,
                      style: Style.getHeaderOne(
                        color: Style.getPrimaryColor(),
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Busca empresas para realizar tus estadías '
                      'profesionales',
                      textAlign: TextAlign.center,
                      style: Style.getHeaderThree(
                        color: Style.getObscureTextColor(),
                        fontSize: 12,
                      ),
                    ),
                    const Spacer(),
                    PrimaryButton(
                      label: 'Comenzar',
                      onPressed: () => _start(context),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
