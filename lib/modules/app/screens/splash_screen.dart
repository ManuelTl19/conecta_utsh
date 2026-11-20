import 'dart:async';

import 'package:material_ui/material_ui.dart';

import 'package:conecta_utsh/helpers/assets.dart';
import 'package:conecta_utsh/helpers/navigation.dart';
import 'package:conecta_utsh/helpers/style.dart';
import 'package:conecta_utsh/modules/app/screens/welcome_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;
  Timer? _navigationTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..forward();
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _scaleAnimation = Tween<double>(
      begin: .9,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
    _navigationTimer = Timer(const Duration(milliseconds: 2200), _showWelcome);
  }

  void _showWelcome() {
    if (!mounted) return;

    // Para producción, añade también los imports de Constants, prefs y
    // LoginScreen; descomenta este bloque y elimina la asignación fija de abajo.
    // El botón "Comenzar" guarda esta preferencia en SharedPreferences.
    // final bool onboardingCompleted =
    //     prefs.getBool(Constants.onboardingKey) ?? false;
    // final Widget destination = onboardingCompleted
    //     ? const LoginScreen()
    //     : const WelcomeScreen();
    const Widget destination = WelcomeScreen();

    push(context, destination, replace: true);
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Style.getPrimaryColor(), Style.getBackgroundColor()],
            stops: const [0, 1],
          ),
        ),
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Image.asset(
                Assets.logo,
                width: MediaQuery.sizeOf(context).width * .68,
                fit: BoxFit.contain,
                semanticLabel: 'Conecta UTSH - Encuentra, Conecta, Crece',
              ),
            ),
          ),
        ),
      ),
    );
  }
}
