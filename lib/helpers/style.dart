import 'package:google_fonts/google_fonts.dart';
import 'package:conecta_utsh/helpers/helpers.dart';

class Style {
  /// ---------- Colors ---------- ///

  // Primary Colors light
  static const Color primary = Color(0xFF007A1C);
  static const Color secondary = Color(0xFF64748B);
  static const Color accent = Color(0xFFEAB308);
  static const Color tags = Color(0xFFFEF9C3);

  static const Color background = Color(0xFFF8FAF8);
  static const Color backgroundCard = Color(0xFFFFFFFF);

  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFD97706);
  static const Color error = Color(0xFFDC2626);
  static const Color info = Color(0xFF2563EB);

  static const Color txPrimary = Color(0xFF17251A);
  static const Color txSecondary = Color(0xFF647067);
  static const Color txMuted = Color(0xFF94A39A);
  static const Color txInverse = Color(0xFFFFFFFF);

  static const Color icon = Color(0xFF334155);
  static const Color subtle = Color(0xFFD5E8EB);
  static const Color successBackground = Color(0xFFD9F2F6);

  // Primary Colors dark
  static const Color primaryDark = Color(0xFF007A1C);
  static const Color secondaryDark = Color(0xFF94A3B8);
  static const Color accentDark = Color(0xFFFACC15);
  static const Color tagsDark = Color(0xFF3F2E05);

  static const Color backgroundDark = Color(0xFF121214);
  static const Color backgroundCardDark = Color(0xFF1E1E24);

  static const Color successDark = Color(0xFF4ADE80);
  static const Color warningDark = Color(0xFFFBBF24);
  static const Color errorDark = Color(0xFFF87171);
  static const Color infoDark = Color(0xFF60A5FA);

  static const Color txPrimaryDark = Color(0xFFF8FAF8);
  static const Color txSecondaryDark = Color(0xFF94A3B8);
  static const Color txMutedDark = Color(0xFF64748B);
  static const Color txInverseDark = Color(0xFF121214);

  static const Color iconDark = Color(0xFF94A3B8);
  static const Color subtleDark = Color(0xFF2D3748);
  static const Color successBackgroundDark = Color(0xFF0B2512);

  // primary colors dark

  // ------- Dynamic Colors
  static bool get isDarkModeOn => AppSettings.isDarkModeOn;

  static Color getPrimaryColor() => AppSettings.isDarkModeOn
      ? AppSettings.primaryDarkColor
      : AppSettings.primaryLightColor;

  static Color getSecondaryColor() => AppSettings.isDarkModeOn
      ? AppSettings.secondaryDarkColor
      : AppSettings.secondaryLightColor;

  static Color getAccentColor() => AppSettings.isDarkModeOn
      ? AppSettings.accentDarkColor
      : AppSettings.accentLightColor;

  static Color getTagColor() => isDarkModeOn ? tagsDark : tags;

  static Color getBackgroundColor() =>
      isDarkModeOn ? backgroundDark : background;
  static Color getCardColor() =>
      isDarkModeOn ? backgroundCardDark : backgroundCard;
  static Color getAppBarColor() => getCardColor();

  static Color getSuccessColor() => isDarkModeOn ? successDark : success;
  static Color getWarningColor() => isDarkModeOn ? warningDark : warning;
  static Color getErrorColor() => isDarkModeOn ? errorDark : error;
  static Color getInfoColor() => isDarkModeOn ? infoDark : info;
  static Color getSuccessBackgroundColor() =>
      isDarkModeOn ? successBackgroundDark : successBackground;

  static Color getTextColor() => isDarkModeOn ? txPrimaryDark : txPrimary;
  static Color getObscureTextColor() =>
      AppSettings.isDarkModeOn ? txSecondaryDark : txSecondary;
  static Color getMutedTextColor() => isDarkModeOn ? txMutedDark : txMuted;
  static Color getInverseTextColor() =>
      isDarkModeOn ? txInverseDark : txInverse;
  static Color getIconColor() => isDarkModeOn ? iconDark : icon;
  static Color getSubtleColor() => isDarkModeOn ? subtleDark : subtle;

  // Border
  static Color getBorderColor() => getSubtleColor();

  static Color getFormFieldBorderColor() =>
      getTextColor().withValues(alpha: .18);

  static Color getFormFieldDisabledBorderColor() =>
      getTextColor().withValues(alpha: .10);

  // Shadow
  static Color getShadowColor() => getTextColor().withValues(alpha: .1);

  // ------- Other Colors
  static const darkScaffoldColor = Color(0xFF1a1d21);
  static const lightScaffoldColor = Color(0xFFf3f6f9);

  static const darkAppBarColor = Color(0xFF561b39);
  static const lightAppBarColor = Color(0xFFf3f6f9);

  static const lightCardColor = Color(0xFFFFFFFF);
  static const darkCardColor = Color(0xFF212529);

  static const transparent = Colors.transparent;
  static const white = Colors.white;
  static const black = Colors.black;
  static const red = Colors.red;
  static const pulse = Color.fromARGB(255, 255, 17, 0);

  /// -------- Text Styles -------- ///
  ///
  ///
  static TextStyle getHeaderOne({
    Color? color,
    double fontSize = 12,
    FontWeight fontWeight = FontWeight.w600,
    TextDecoration? decoration,
  }) => TextStyle(
    color: color ?? getPrimaryColor(),
    fontFamily: GoogleFonts.poppins().fontFamily,
    fontSize: fontSize.sp,
    fontWeight: fontWeight,
    decoration: decoration,
    decorationColor: color ?? getPrimaryColor(),
  );

  static TextStyle getHeaderTwo({
    Color? color,
    double fontSize = 11,
    FontWeight fontWeight = FontWeight.w600,
    TextDecoration? decoration,
  }) => TextStyle(
    color: color ?? getPrimaryColor(),
    fontFamily: GoogleFonts.poppins().fontFamily,
    fontSize: fontSize.sp,
    fontWeight: fontWeight,
    decoration: decoration,
    decorationColor: color ?? getPrimaryColor(),
  );

  static TextStyle getHeaderThree({
    Color? color,
    double fontSize = 10,
    FontWeight fontWeight = FontWeight.w400,
    TextDecoration? decoration,
  }) => TextStyle(
    color: color ?? getSecondaryColor(),
    fontFamily: GoogleFonts.poppins().fontFamily,
    fontSize: fontSize.sp,
    fontWeight: fontWeight,
    decoration: decoration,
    decorationColor: color ?? getSecondaryColor(),
  );

  static TextStyle getTextStyle({
    Color? color,
    double fontSize = 8,
    FontWeight fontWeight = FontWeight.w400,
    TextDecoration? decoration,
  }) => TextStyle(
    color: color ?? getTextColor(),
    fontFamily: GoogleFonts.poppins().fontFamily,
    fontSize: fontSize.sp,
    fontWeight: fontWeight,
    decoration: decoration,
    decorationColor: color ?? getTextColor(),
  );

  static TextStyle getHintStyle({
    Color? color,
    double fontSize = 8,
    FontWeight fontWeight = FontWeight.w400,
    TextDecoration? decoration,
  }) => TextStyle(
    color: color ?? getAccentColor(),
    fontFamily: GoogleFonts.poppins().fontFamily,
    fontSize: fontSize.sp,
    fontWeight: fontWeight,
    decoration: decoration,
    decorationColor: color ?? getAccentColor(),
  );

  /// -------- Padding -------- ///
  // Values
  static const double horizontalPadding = 10;
  static const double verticalPadding = 10;

  static EdgeInsets getPadding() => EdgeInsets.symmetric(
    horizontal: horizontalPadding.w,
    vertical: verticalPadding.w,
  );

  static EdgeInsets getPaddingAll(double padding) => EdgeInsets.all(padding.w);

  static EdgeInsets getPaddingSymmetric({
    double horizontal = horizontalPadding,
    double vertical = verticalPadding,
  }) => EdgeInsets.symmetric(horizontal: horizontal.w, vertical: vertical.w);

  static EdgeInsets getPaddingHorizontal({
    double padding = horizontalPadding,
  }) => EdgeInsets.symmetric(horizontal: padding.w);

  static EdgeInsets getPaddingVertical({double padding = verticalPadding}) =>
      EdgeInsets.symmetric(vertical: padding.w);

  static EdgeInsets getOnlyPadding({
    double left = 0,
    double right = 0,
    double top = 0,
    double bottom = 0,
  }) => EdgeInsets.only(
    left: left.w,
    right: right.w,
    top: top.w,
    bottom: bottom.w,
  );

  static EdgeInsets noPadding() => const EdgeInsets.all(0);

  static EdgeInsets getCardPadding({double padding = 10}) =>
      EdgeInsets.all(padding);

  /// -------- Border Radius -------- ///

  // Values
  static double circularBorderRadius = 10;
  static double buttonBorderRadius = 15;

  // BorderRadius
  static BorderRadius getBorderRadius() =>
      BorderRadius.circular(circularBorderRadius.r);

  static BorderRadius getButtonBorderRadius() =>
      BorderRadius.circular(buttonBorderRadius.r);

  static BorderRadius getCircularBorderRadius(double radius) =>
      BorderRadius.circular(radius.r);

  static BorderRadius getVerticalBorderRadius({
    double top = 10,
    double bottom = 10,
  }) => BorderRadius.vertical(
    top: Radius.circular(top.r),
    bottom: Radius.circular(bottom.r),
  );

  static BorderRadius getOnlyBorderRadius({
    double topLeft = 0,
    double topRight = 0,
    double bottomLeft = 0,
    double bottomRight = 0,
  }) => BorderRadius.only(
    topLeft: Radius.circular(topLeft.r),
    topRight: Radius.circular(topRight.r),
    bottomLeft: Radius.circular(bottomLeft.r),
    bottomRight: Radius.circular(bottomRight.r),
  );

  /// -------- Icon Sizes -------- ///

  static double bigIconSize = 18.w;
  static double smallIconSize = 14.w;
}
