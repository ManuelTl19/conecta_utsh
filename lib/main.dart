import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';
import 'package:resize/resize.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:conecta_utsh/helpers/providers/providers.dart';
import 'package:conecta_utsh/helpers/style.dart';
import 'package:conecta_utsh/modules/app/screens/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  prefs = await SharedPreferences.getInstance();
  await AppSettings.getSettings();
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Resize(
      builder: () => AnimatedBuilder(
        animation: AppSettings(),
        builder: (context, _) {
          final isDarkMode = Style.isDarkModeOn;
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
            theme: _buildTheme(Brightness.light),
            darkTheme: _buildTheme(Brightness.dark),
            home: const SplashScreen(),
          );
        },
      ),
    );
  }

  ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final primary = isDark
        ? AppSettings.primaryDarkColor
        : AppSettings.primaryLightColor;
    final secondary = isDark
        ? AppSettings.secondaryDarkColor
        : AppSettings.secondaryLightColor;
    final accent = isDark
        ? AppSettings.accentDarkColor
        : AppSettings.accentLightColor;
    final surface = isDark ? Style.backgroundDark : Style.background;
    final onSurface = isDark ? Style.txPrimaryDark : Style.txPrimary;
    final outline = isDark ? Style.subtleDark : Style.subtle;
    final error = isDark ? Style.errorDark : Style.error;
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: primary,
          brightness: brightness,
        ).copyWith(
          primary: primary,
          onPrimary: Colors.white,
          secondary: secondary,
          tertiary: accent,
          surface: surface,
          onSurface: onSurface,
          outline: outline,
          error: error,
          onError: Colors.white,
        );

    return ThemeData(
      brightness: brightness,
      colorScheme: colorScheme,
      fontFamily: GoogleFonts.outfit().fontFamily,
      scaffoldBackgroundColor: surface,
      dividerColor: outline,
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? primary
              : colorScheme.onSurfaceVariant,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? primary.withValues(alpha: .3)
              : outline.withValues(alpha: .45),
        ),
      ),
    );
  }
}
