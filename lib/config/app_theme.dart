import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class AppTheme {
  // ── Stitch Design Tokens ─────────────────────────────────────────────────
  // Primary purple palette (from Stitch "Kinetic Clarity")
  static const Color primary = Color(0xFF6750A4);
  static const Color primaryDark = Color(0xFF4F378A);
  static const Color primaryLight = Color(0xFFCFBCFF);
  static const Color secondary = Color(0xFF4ECDC4);
  static const Color accent = Color(0xFFE7C365);
  static const Color gold = Color(0xFFE7C365);
  static const Color rose = Color(0xFFEF476F);
  static const Color ink = Color(0xFF1D1B20);

  // Light mode surfaces
  static const Color surface = Color(0xFFF8F5FF);
  static const Color cardBg = Colors.white;
  static const Color darkText = Color(0xFF1D1B20);
  static const Color greyText = Color(0xFF79747E);
  static const Color lightGrey = Color(0xFFE0DDE4);

  // Semantic colors
  static const Color success = Color(0xFF2ECC71);
  static const Color warning = Color(0xFFE7C365);
  static const Color error = Color(0xFFEF476F);
  static const Color urgent = Color(0xFFDC2626);

  // Dark mode (Stitch "Deep Space")
  static const Color _darkSurface = Color(0xFF141218);
  static const Color _darkCard = Color(0xFF211F26);
  static const Color _darkCardHigher = Color(0xFF2B292F);
  static const Color _darkInput = Color(0xFF1D1B20);
  static const Color _darkCardBorder = Color(0xFF494551);
  static const Color _darkText = Color(0xFFE6E0E9);
  static const Color _darkMutedText = Color(0xFFCBC4D2);
  static const Color _darkPrimary = Color(0xFFCFBCFF);

  // ── Subject Color Palette ────────────────────────────────────────────────
  static const subjectColors = [
    Color(0xFFEDE7FF), // purple
    Color(0xFFFFECE0), // orange
    Color(0xFFE0FFF0), // green
    Color(0xFFFFF8E0), // gold
    Color(0xFFE0E8FF), // blue
    Color(0xFFE0FFF8), // teal
    Color(0xFFFFE0F0), // pink
    Color(0xFFE0F8FF), // cyan
  ];

  static const subjectAccents = [
    Color(0xFF6750A4),
    Color(0xFFFF6B4A),
    Color(0xFF2ECC71),
    Color(0xFFE7C365),
    Color(0xFF5B6CF7),
    Color(0xFF4ECDC4),
    Color(0xFFEF476F),
    Color(0xFF4AC8F7),
  ];

  // ── Gradients ────────────────────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF2D1B69), Color(0xFF4F378A), Color(0xFF6750A4)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient headerGradient = LinearGradient(
    colors: [Color(0xFF2D1B69), Color(0xFF6750A4), Color(0xFF4ECDC4)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF2ECC71), Color(0xFF27AE60)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient warmGradient = LinearGradient(
    colors: [Color(0xFFEF476F), Color(0xFFE7C365)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient purpleGradient = LinearGradient(
    colors: [Color(0xFF4F378A), Color(0xFF6750A4)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient screenGradient(BuildContext context) {
    if (isDark(context)) {
      return const LinearGradient(
        colors: [Color(0xFF0F0D13), Color(0xFF141218), Color(0xFF1D1B20)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }
    return const LinearGradient(
      colors: [Color(0xFFF8F5FF), Color(0xFFF3EEFF), Color(0xFFF8F5FF)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  // ── Shadows (Luminous borders style for dark, subtle for light) ──────────
  static List<BoxShadow> get softShadow => [
        BoxShadow(
          color: primary.withValues(alpha: 0.06),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
      ];

  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: primary.withValues(alpha: 0.10),
          blurRadius: 24,
          offset: const Offset(0, 10),
        ),
      ];

  static List<BoxShadow> premiumShadow(BuildContext context) => isDark(context)
      ? [
          BoxShadow(
            color: _darkPrimary.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ]
      : [
          BoxShadow(
            color: primary.withValues(alpha: 0.08),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ];

  // Glassmorphic glow shadow
  static List<BoxShadow> glowShadow(Color color, {double intensity = 0.3}) => [
        BoxShadow(
          color: color.withValues(alpha: intensity),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ];

  // ── Border Radius (Stitch ultra-soft) ────────────────────────────────────
  static BorderRadius get cardRadius => BorderRadius.circular(20);
  static BorderRadius get buttonRadius => BorderRadius.circular(18);
  static BorderRadius get chipRadius => BorderRadius.circular(12);
  static BorderRadius get inputRadius => BorderRadius.circular(18);

  // ── Theme-Aware Helper Methods ──────────────────────────────────────────
  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color cardColor(BuildContext context) =>
      isDark(context) ? _darkCard : cardBg;

  static Color surfaceColor(BuildContext context) =>
      isDark(context) ? _darkSurface : surface;

  static Color textColor(BuildContext context) =>
      isDark(context) ? _darkText : darkText;

  static Color subtitleColor(BuildContext context) =>
      isDark(context) ? _darkMutedText : greyText;

  static Color borderColor(BuildContext context) =>
      isDark(context) ? _darkCardBorder : lightGrey;

  static Color elevatedSurface(BuildContext context) =>
      isDark(context) ? _darkCardHigher : Colors.white;

  static Color chipBgColor(BuildContext context, Color accentColor) =>
      isDark(context)
          ? accentColor.withValues(alpha: 0.18)
          : accentColor.withValues(alpha: 0.1);

  static List<BoxShadow> adaptiveShadow(BuildContext context) =>
      isDark(context) ? [] : softShadow;

  // Glassmorphic decoration helper
  static BoxDecoration glassDecoration(BuildContext context, {
    double borderOpacity = 0.12,
    double fillOpacity = 0.05,
    double radius = 20,
  }) {
    final dark = isDark(context);
    return BoxDecoration(
      color: dark
          ? Colors.white.withValues(alpha: fillOpacity)
          : Colors.white.withValues(alpha: 0.7),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: dark
            ? Colors.white.withValues(alpha: borderOpacity)
            : Colors.white.withValues(alpha: 0.5),
        width: 1.5,
      ),
    );
  }

  // ── Theme Data ───────────────────────────────────────────────────────────
  static ThemeData get lightTheme {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: Brightness.light,
        primary: primary,
        secondary: secondary,
        surface: surface,
        error: error,
      ),
      useMaterial3: true,
      textTheme: GoogleFonts.plusJakartaSansTextTheme(),
      scaffoldBackgroundColor: surface,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          color: darkText,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: const IconThemeData(color: primary),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: cardBg,
        shape: RoundedRectangleBorder(borderRadius: cardRadius),
        margin: const EdgeInsets.only(bottom: 12),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: buttonRadius),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: const BorderSide(color: primary, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: buttonRadius),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF3EEFF),
        border: OutlineInputBorder(
          borderRadius: inputRadius,
          borderSide: const BorderSide(color: lightGrey),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: inputRadius,
          borderSide: const BorderSide(color: lightGrey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: inputRadius,
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: inputRadius,
          borderSide: const BorderSide(color: error),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        labelStyle: GoogleFonts.plusJakartaSans(color: greyText, fontSize: 14),
        hintStyle:
            GoogleFonts.plusJakartaSans(color: greyText.withValues(alpha: 0.5)),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: chipRadius),
        side: BorderSide.none,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 0,
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: cardRadius),
      ),
      dividerTheme: const DividerThemeData(
        color: lightGrey,
        thickness: 1,
        space: 1,
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: primary,
        unselectedLabelColor: greyText,
        indicatorColor: primary,
        labelStyle: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w600, fontSize: 14),
        unselectedLabelStyle: GoogleFonts.plusJakartaSans(fontSize: 14),
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: cardBg,
        headerBackgroundColor: primary,
        headerForegroundColor: Colors.white,
        dayForegroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.white;
          return darkText;
        }),
        dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primary;
          return Colors.transparent;
        }),
        todayForegroundColor: WidgetStateProperty.all(primary),
        todayBackgroundColor:
            WidgetStateProperty.all(primary.withValues(alpha: 0.08)),
        todayBorder: const BorderSide(color: primary, width: 1),
        shape: RoundedRectangleBorder(borderRadius: cardRadius),
      ),
      timePickerTheme: TimePickerThemeData(
        backgroundColor: cardBg,
        hourMinuteColor: WidgetStateColor.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primary.withValues(alpha: 0.12);
          }
          return const Color(0xFFF3EEFF);
        }),
        hourMinuteTextColor: WidgetStateColor.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primary;
          return darkText;
        }),
        dialHandColor: primary,
        dialBackgroundColor: const Color(0xFFF3EEFF),
        entryModeIconColor: primary,
        shape: RoundedRectangleBorder(borderRadius: cardRadius),
        hourMinuteShape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: Brightness.dark,
        primary: _darkPrimary,
        secondary: secondary,
        surface: _darkSurface,
        error: const Color(0xFFFFB4AB),
      ).copyWith(
        onPrimary: Colors.white,
        onSurface: _darkText,
        outline: _darkCardBorder,
      ),
      useMaterial3: true,
      textTheme:
          GoogleFonts.plusJakartaSansTextTheme(ThemeData.dark().textTheme)
              .apply(
        bodyColor: _darkText,
        displayColor: _darkText,
      ),
      scaffoldBackgroundColor: _darkSurface,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          color: _darkText,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: const IconThemeData(color: _darkPrimary),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: _darkCard,
        shape: RoundedRectangleBorder(borderRadius: cardRadius),
        margin: const EdgeInsets.only(bottom: 12),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: buttonRadius),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _darkPrimary,
          side: const BorderSide(color: _darkPrimary, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: buttonRadius),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: _darkPrimary,
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _darkInput,
        border: OutlineInputBorder(
          borderRadius: inputRadius,
          borderSide: const BorderSide(color: _darkCardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: inputRadius,
          borderSide: const BorderSide(color: _darkCardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: inputRadius,
          borderSide: const BorderSide(color: _darkPrimary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: inputRadius,
          borderSide: const BorderSide(color: Color(0xFFFFB4AB)),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        labelStyle:
            GoogleFonts.plusJakartaSans(color: _darkMutedText, fontSize: 14),
        hintStyle: GoogleFonts.plusJakartaSans(color: const Color(0xFF948E9C)),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: _darkInput,
        selectedColor: _darkPrimary.withValues(alpha: 0.22),
        disabledColor: const Color(0xFF17192B),
        labelStyle: GoogleFonts.plusJakartaSans(color: _darkText),
        checkmarkColor: _darkText,
        shape: RoundedRectangleBorder(borderRadius: chipRadius),
        side: const BorderSide(color: _darkCardBorder),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 0,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: _darkCard,
        shape: RoundedRectangleBorder(borderRadius: cardRadius),
      ),
      dividerTheme: const DividerThemeData(
        color: _darkCardBorder,
        thickness: 1,
        space: 1,
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: _darkPrimary,
        unselectedLabelColor: Colors.white54,
        indicatorColor: _darkPrimary,
        labelStyle: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w600, fontSize: 14),
        unselectedLabelStyle: GoogleFonts.plusJakartaSans(fontSize: 14),
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: _darkCard,
        headerBackgroundColor: primary,
        headerForegroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        dayForegroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.white;
          return _darkText;
        }),
        dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primary;
          return Colors.transparent;
        }),
        todayForegroundColor: WidgetStateProperty.all(_darkPrimary),
        todayBackgroundColor:
            WidgetStateProperty.all(_darkPrimary.withValues(alpha: 0.15)),
        todayBorder: const BorderSide(color: _darkPrimary, width: 1),
        shape: RoundedRectangleBorder(borderRadius: cardRadius),
      ),
      timePickerTheme: TimePickerThemeData(
        backgroundColor: _darkCard,
        hourMinuteColor: WidgetStateColor.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return _darkPrimary.withValues(alpha: 0.22);
          }
          return _darkInput;
        }),
        hourMinuteTextColor: WidgetStateColor.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return _darkPrimary;
          return _darkText;
        }),
        dialHandColor: primary,
        dialBackgroundColor: _darkInput,
        entryModeIconColor: _darkPrimary,
        shape: RoundedRectangleBorder(borderRadius: cardRadius),
        hourMinuteShape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: _darkCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
    );
  }

  // ── Picker Helpers ─────────────────────────────────────────────────────────

  /// Shows a Material time picker and returns the selected TimeOfDay.
  static Future<TimeOfDay?> showAppTimePicker(
    BuildContext context, {
    TimeOfDay? initialTime,
    String? helpText,
  }) {
    return showTimePicker(
      context: context,
      initialTime: initialTime ?? TimeOfDay.now(),
      helpText: helpText,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: Theme.of(ctx).colorScheme.copyWith(
                primary: isDark(ctx) ? _darkPrimary : primary,
                onPrimary: Colors.white,
                surface: isDark(ctx) ? _darkCard : cardBg,
                onSurface: isDark(ctx) ? _darkText : darkText,
              ),
        ),
        child: child!,
      ),
    );
  }

  /// Shows a Material date picker and returns the selected DateTime.
  static Future<DateTime?> showAppDatePicker(
    BuildContext context, {
    DateTime? initialDate,
    DateTime? firstDate,
    DateTime? lastDate,
    String? helpText,
  }) {
    return showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime.now(),
      firstDate: firstDate ?? DateTime(2020),
      lastDate: lastDate ?? DateTime(2030),
      helpText: helpText,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: Theme.of(ctx).colorScheme.copyWith(
                primary: isDark(ctx) ? _darkPrimary : primary,
                onPrimary: Colors.white,
                surface: isDark(ctx) ? _darkCard : cardBg,
                onSurface: isDark(ctx) ? _darkText : darkText,
              ),
        ),
        child: child!,
      ),
    );
  }

  /// Shows a Material date range picker and returns the selected range.
  static Future<DateTimeRange?> showAppDateRangePicker(
    BuildContext context, {
    DateTimeRange? initialDateRange,
    DateTime? firstDate,
    DateTime? lastDate,
    String? helpText,
  }) {
    return showDateRangePicker(
      context: context,
      firstDate: firstDate ?? DateTime(2020),
      lastDate: lastDate ?? DateTime(2030),
      initialDateRange: initialDateRange,
      helpText: helpText,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: Theme.of(ctx).colorScheme.copyWith(
                primary: isDark(ctx) ? _darkPrimary : primary,
                onPrimary: Colors.white,
                surface: isDark(ctx) ? _darkCard : cardBg,
                onSurface: isDark(ctx) ? _darkText : darkText,
              ),
        ),
        child: child!,
      ),
    );
  }

  /// Parses "HH:mm" string to TimeOfDay. Returns null on failure.
  static TimeOfDay? parseTime(String time) {
    final parts = time.split(':');
    if (parts.length != 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    return TimeOfDay(hour: h, minute: m);
  }

  /// Formats TimeOfDay to "HH:mm" string.
  static String formatTime(TimeOfDay tod) =>
      '${tod.hour.toString().padLeft(2, '0')}:${tod.minute.toString().padLeft(2, '0')}';

  /// Formats TimeOfDay to display string like "9:00 AM".
  static String formatTimeDisplay(TimeOfDay tod) {
    final hour = tod.hourOfPeriod == 0 ? 12 : tod.hourOfPeriod;
    final minute = tod.minute.toString().padLeft(2, '0');
    final period = tod.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  /// Formats a DateTime to a short date string like "Aug 1, 2026".
  static String formatDate(DateTime date) =>
      DateFormat('MMM d, yyyy').format(date);
}

// ─── Day/Slot Constants ────────────────────────────────────────────────────────

class AppConst {
  static const List<String> dayNames = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  static const List<String> departments = [
    'Computer Science',
    'Information Technology',
    'Electronics',
    'Mechanical',
    'Civil',
    'Electrical',
    'Chemical',
    'Biotechnology',
    'Mathematics',
    'Physics',
  ];

  static const List<String> semesters = [
    '1st',
    '2nd',
    '3rd',
    '4th',
    '5th',
    '6th',
    '7th',
    '8th',
  ];

  static String slotLabel(int index) => 'Slot ${index + 1}';
  static String dayLabel(int index) =>
      index < dayNames.length ? dayNames[index] : 'Day ${index + 1}';
}
