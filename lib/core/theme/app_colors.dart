import 'package:flutter/painting.dart';

/// The only colour source in the app (design handoff, Tokens.dc.html).
/// Tints are these colours at reduced opacity; never add new hex values.
abstract final class AppColors {
  /// Primary buttons, selected controls, active nav. Dark text on top.
  static const Color primary = Color(0xFF91D14D);

  /// Playback button, info panels, empty-state icons.
  static const Color secondary = Color(0xFF60CFD3);

  /// Avatar initials and rare highlights only.
  static const Color accent = Color(0xFFD698EC);

  /// All headings, labels, body; submit button.
  static const Color text = Color(0xFF140F2D);

  /// Helper text, metadata, inactive nav.
  static const Color textSecondary = Color(0xFF5C5870);

  /// Screen backgrounds.
  static const Color background = Color(0xFFF8FAFC);

  /// Inputs, lists, sheets, bars.
  static const Color surface = Color(0xFFFFFFFF);

  /// Text links, focus ring edge, current step. Only green allowed as text.
  static const Color supportingGreen = Color(0xFF5A7438);

  /// Completed dots and success tints (fill only).
  static const Color success = Color(0xFF4CAF50);

  /// Draft and pending dots, caution tints (fill only).
  static const Color warning = Color(0xFFFFB74D);

  /// Field errors, failed states, stop recording.
  static const Color error = Color(0xFFE53935);

  /// Upload progress, informational icons (fill only).
  static const Color info = Color(0xFF2196F3);

  /// Input outlines, dividers, disabled fills.
  static const Color border = Color(0xFFE2E8F0);
}
