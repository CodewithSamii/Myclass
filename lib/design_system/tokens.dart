import 'package:flutter/material.dart' hide Badge;

abstract final class Space {
  static const double xxs = 4,
      xs = 8,
      sm = 12,
      md = 16,
      lg = 20,
      xl = 24,
      xxl = 32,
      huge = 48;
}

abstract final class Shape {
  static const double small = 8, medium = 12, large = 18, sheet = 24;
}

abstract final class Motion {
  static const fast = Duration(milliseconds: 140),
      normal = Duration(milliseconds: 240),
      sheet = Duration(milliseconds: 320);
  static const curve = Curves.easeOutCubic;
}

abstract final class Metrics {
  static const double touch = 48, icon = 20, pageInset = 24, maxContent = 1120;
}

@immutable
class AulaColors extends ThemeExtension<AulaColors> {
  const AulaColors({
    required this.canvas,
    required this.surface,
    required this.subtle,
    required this.ink,
    required this.secondary,
    required this.faint,
    required this.line,
    required this.hero,
    required this.onHero,
    required this.heroMuted,
    required this.sage,
    required this.sageBg,
    required this.amber,
    required this.amberBg,
    required this.red,
    required this.redBg,
  });
  final Color canvas,
      surface,
      subtle,
      ink,
      secondary,
      faint,
      line,
      hero,
      onHero,
      heroMuted,
      sage,
      sageBg,
      amber,
      amberBg,
      red,
      redBg;
  static const light = AulaColors(
    canvas: Color(0xFFF6F6F2),
    surface: Color(0xFFFFFFFF),
    subtle: Color(0xFFEDEEE8),
    ink: Color(0xFF242923),
    secondary: Color(0xFF656D63),
    faint: Color(0xFF7B8479),
    line: Color(0xFFDFE3DA),
    hero: Color(0xFF28352D),
    onHero: Color(0xFFF3F5ED),
    heroMuted: Color(0xFFB6C3B5),
    sage: Color(0xFF45624D),
    sageBg: Color(0xFFE8EEE6),
    amber: Color(0xFF8A5A2B),
    amberBg: Color(0xFFF5EBDD),
    red: Color(0xFF9B5047),
    redBg: Color(0xFFF4E7E2),
  );
  static const dark = AulaColors(
    canvas: Color(0xFF101410),
    surface: Color(0xFF1B201B),
    subtle: Color(0xFF252D25),
    ink: Color(0xFFE7EDE3),
    secondary: Color(0xFFABB6A8),
    faint: Color(0xFF8D9A8A),
    line: Color(0xFF323C31),
    hero: Color(0xFFDCE5D6),
    onHero: Color(0xFF223021),
    heroMuted: Color(0xFF566750),
    sage: Color(0xFFB0C5A6),
    sageBg: Color(0xFF273725),
    amber: Color(0xFFE2BB8C),
    amberBg: Color(0xFF372D21),
    red: Color(0xFFE6A398),
    redBg: Color(0xFF3B2926),
  );
  @override
  AulaColors copyWith() => this;
  @override
  AulaColors lerp(covariant AulaColors? other, double t) {
    if (other == null) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return AulaColors(
      canvas: l(canvas, other.canvas),
      surface: l(surface, other.surface),
      subtle: l(subtle, other.subtle),
      ink: l(ink, other.ink),
      secondary: l(secondary, other.secondary),
      faint: l(faint, other.faint),
      line: l(line, other.line),
      hero: l(hero, other.hero),
      onHero: l(onHero, other.onHero),
      heroMuted: l(heroMuted, other.heroMuted),
      sage: l(sage, other.sage),
      sageBg: l(sageBg, other.sageBg),
      amber: l(amber, other.amber),
      amberBg: l(amberBg, other.amberBg),
      red: l(red, other.red),
      redBg: l(redBg, other.redBg),
    );
  }
}

extension DesignContext on BuildContext {
  AulaColors get colors => Theme.of(this).extension<AulaColors>()!;
  TextTheme get type => Theme.of(this).textTheme;
  bool get wide => MediaQuery.sizeOf(this).width >= 720;
}

ThemeData aulaTheme(Brightness brightness) {
  final c = brightness == Brightness.dark ? AulaColors.dark : AulaColors.light;
  TextStyle style(
    double size,
    FontWeight weight, {
    double height = 1.4,
    double spacing = 0,
  }) => TextStyle(
    fontFamily: 'Inter',
    fontSize: size,
    fontWeight: weight,
    height: height,
    letterSpacing: spacing,
    color: c.ink,
  );
  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    scaffoldBackgroundColor: c.canvas,
    fontFamily: 'Inter',
    extensions: [c],
    colorScheme: ColorScheme(
      brightness: brightness,
      primary: c.ink,
      onPrimary: c.canvas,
      secondary: c.sage,
      onSecondary: c.surface,
      error: c.red,
      onError: c.surface,
      surface: c.surface,
      onSurface: c.ink,
      outline: c.line,
    ),
    textTheme: TextTheme(
      displaySmall: style(38, FontWeight.w600, height: 1.14, spacing: -1.6),
      headlineLarge: style(32, FontWeight.w600, height: 1.15, spacing: -1.2),
      headlineMedium: style(27, FontWeight.w600, height: 1.22, spacing: -.9),
      headlineSmall: style(23, FontWeight.w600, height: 1.25, spacing: -.6),
      titleLarge: style(19, FontWeight.w600, height: 1.3, spacing: -.4),
      titleMedium: style(15, FontWeight.w600, height: 1.4, spacing: -.2),
      titleSmall: style(13, FontWeight.w600),
      bodyLarge: style(15, FontWeight.w400),
      bodyMedium: style(13, FontWeight.w400),
      bodySmall: style(11, FontWeight.w400),
      labelLarge: style(14, FontWeight.w500),
      labelMedium: style(12, FontWeight.w500),
      labelSmall: style(10, FontWeight.w600, spacing: .8),
    ),
    dividerColor: c.line,
    dividerTheme: DividerThemeData(color: c.line, space: 1, thickness: 1),
    splashFactory: InkSparkle.splashFactory,
    appBarTheme: AppBarTheme(
      backgroundColor: c.canvas,
      foregroundColor: c.ink,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: style(17, FontWeight.w600),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: c.surface,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(Shape.sheet)),
      ),
      showDragHandle: true,
      dragHandleColor: c.line,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: c.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      hintStyle: TextStyle(color: c.faint, fontSize: 14),
      labelStyle: TextStyle(color: c.secondary),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: c.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: c.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: c.ink, width: 1.5),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: c.ink,
        foregroundColor: c.canvas,
        minimumSize: const Size(48, 52),
        textStyle: style(14, FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: c.ink,
        textStyle: style(13, FontWeight.w500),
        minimumSize: const Size(44, 44),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: c.ink,
        minimumSize: const Size(48, 48),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: c.ink,
      contentTextStyle: TextStyle(color: c.canvas, fontFamily: 'Inter'),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStatePropertyAll(c.surface),
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? c.sage : c.line,
      ),
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
      },
    ),
  );
}
