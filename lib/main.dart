import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';
import 'package:resize/resize.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:conecta_utsh/helpers/providers/providers.dart';
import 'package:conecta_utsh/helpers/style.dart';
import 'package:conecta_utsh/modules/auth/screens/splash_screen.dart';

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
            theme: ThemeData(
              brightness: Brightness.light,
              colorScheme: ColorScheme.fromSeed(
                seedColor: Style.getPrimaryColor(),
              ),
              fontFamily: GoogleFonts.poppins().fontFamily,
              scaffoldBackgroundColor: Style.getBackgroundColor(),
            ),
            darkTheme: ThemeData(
              brightness: Brightness.dark,
              colorScheme: ColorScheme.fromSeed(
                seedColor: Style.getPrimaryColor(),
                brightness: Brightness.dark,
              ),
              fontFamily: GoogleFonts.poppins().fontFamily,
              scaffoldBackgroundColor: Style.getBackgroundColor(),
            ),
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}
