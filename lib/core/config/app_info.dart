/// Build metadata. The Flutter tool defines FLUTTER_BUILD_NAME/NUMBER from
/// `pubspec.yaml` `version:` on every build.
abstract final class AppInfo {
  static const String version = String.fromEnvironment(
    'FLUTTER_BUILD_NAME',
    defaultValue: 'dev',
  );
  static const String build = String.fromEnvironment('FLUTTER_BUILD_NUMBER');
}
