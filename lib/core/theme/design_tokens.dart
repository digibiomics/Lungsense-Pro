// LungSense Pro design tokens, adapted from
// lungsense-pro-handoff/lib_snippets/design_tokens.dart.
// Public Sans is bundled as a font asset instead of fetched by google_fonts.
import 'package:flutter/painting.dart';

import 'app_colors.dart';

abstract final class LsSpace {
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double gutter = 20;
  static const double authGutter = 24;
  static const double lg = 24;
  static const double xl = 32;
}

abstract final class LsRadius {
  static const double checkbox = 6;
  static const double small = 8;
  static const double control = 10; // inputs, buttons, banners
  static const double panel = 12; // lists, panels
  static const double hero = 14;
  static const double sheet = 16; // bottom sheet top corners
}

abstract final class LsSize {
  static const double minTouch = 44;
  static const double input = 48;
  static const double button = 52;
  static const double severityButton = 56;
  static const double recordButton = 84;
  static const double bottomNav = 72;
  static const double headerHeight = 56;
}

/// Tints are palette colours at reduced opacity, never new hex values.
abstract final class LsTint {
  static final Color navActive = AppColors.primary.withValues(alpha: .35);
  static final Color chosen = AppColors.primary.withValues(alpha: .28);
  static final Color selectedCard = AppColors.primary.withValues(alpha: .12);
  static final Color loadingButton = AppColors.primary.withValues(alpha: .55);
  static final Color iconDisc = AppColors.secondary.withValues(alpha: .22);
  static final Color featurePrimary = AppColors.primary.withValues(alpha: .25);
  static final Color featureSecondary = AppColors.secondary.withValues(
    alpha: .25,
  );
  static final Color featureAccent = AppColors.accent.withValues(alpha: .25);
  static final Color draftPill = AppColors.warning.withValues(alpha: .22);
  static final Color completedPill = AppColors.success.withValues(alpha: .15);
  static final Color successBg = AppColors.success.withValues(alpha: .12);
  static final Color errorBg = AppColors.error.withValues(alpha: .08);
  static final Color errorBorder = AppColors.error.withValues(alpha: .35);
  static final Color errorDisc = AppColors.error.withValues(alpha: .12);
  static final Color cautionBg = AppColors.warning.withValues(alpha: .20);
  static final Color cautionBorder = AppColors.warning.withValues(alpha: .70);
  static final Color pendingDisc = AppColors.warning.withValues(alpha: .25);
  static final Color focusRing = AppColors.primary.withValues(alpha: .35);
}

abstract final class LsText {
  static const String fontFamily = 'PublicSans';

  static TextStyle _p(double size, double height, FontWeight w, [Color? c]) =>
      TextStyle(
        fontFamily: fontFamily,
        fontSize: size,
        height: height / size,
        fontWeight: w,
        color: c ?? AppColors.text,
      );

  static final TextStyle timer = _p(
    48,
    54,
    FontWeight.w600,
  ).copyWith(fontFeatures: const [FontFeature.tabularFigures()]);
  static final TextStyle brand = _p(
    34,
    40,
    FontWeight.w700,
  ).copyWith(letterSpacing: -0.68);
  static final TextStyle authTitle = _p(26, 32, FontWeight.w700);
  static final TextStyle pageTitle = _p(24, 30, FontWeight.w600);
  static final TextStyle screenTitle = _p(22, 28, FontWeight.w600);
  static final TextStyle section = _p(17, 22, FontWeight.w600);
  static final TextStyle lead = _p(
    17,
    25,
    FontWeight.w400,
    AppColors.textSecondary,
  );
  static final TextStyle body = _p(16, 22, FontWeight.w400);
  static final TextStyle button = _p(16, 22, FontWeight.w600);
  static final TextStyle subtitle = _p(
    15,
    22,
    FontWeight.w400,
    AppColors.textSecondary,
  );
  static final TextStyle bodySmall = _p(15, 22, FontWeight.w400);
  static final TextStyle listTitle = _p(15, 20, FontWeight.w600);
  static final TextStyle label = _p(14, 20, FontWeight.w500);
  static final TextStyle bannerBody = _p(14, 20, FontWeight.w400);
  static final TextStyle helper = _p(
    13,
    18,
    FontWeight.w400,
    AppColors.textSecondary,
  );
  static final TextStyle pill = _p(12, 16, FontWeight.w600);
  static final TextStyle footnote = _p(
    12,
    18,
    FontWeight.w400,
    AppColors.textSecondary,
  );
}
