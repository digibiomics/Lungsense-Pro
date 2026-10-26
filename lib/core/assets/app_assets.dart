/// Central registry of bundled assets. Reference images only through here.
///
/// Sources (copied unchanged from `Design and icons/`, see
/// docs/ARCHITECTURE.md "Asset inventory"):
abstract final class AppAssets {
  static const String _images = 'assets/images';

  /// `icons/LungSense Pro Clinical Logo.png` (1672x941, transparent).
  /// Stacked mark + wordmark + "Clinical Data Collection". Splash screen.
  static const String logoStacked = '$_images/logo_clinical_stacked.png';
  static const double logoStackedAspect = 1672 / 941;

  /// `icons/LungSense Pro Medical Logo.png` (1920x819, transparent).
  /// Horizontal lock-up for headers on wide layouts.
  static const String logoHorizontal = '$_images/logo_horizontal.png';
  static const double logoHorizontalAspect = 1920 / 819;

  /// `icons/Respiratory Waves Medical App Icon.png` (1254x1254, transparent
  /// corners). Rounded app tile used as the brand mark on Welcome.
  static const String appIconTile = '$_images/app_icon_tile.png';

  /// `icons/digibiomics-logo.png` (430x120, transparent). "Powered by".
  static const String digibiomicsLogo = '$_images/digibiomics_logo.png';
  static const double digibiomicsAspect = 430 / 120;
}
