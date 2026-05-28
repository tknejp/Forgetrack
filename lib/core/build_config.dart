/// Compile-time build configuration. Pass `--dart-define=FLAVOR=prod`
/// (or `dev` / `internal`) to `flutter run` / `flutter build` to select the
/// flavor. Defaults to `dev` so a bare `flutter run` (e.g. from an IDE play
/// button) keeps working during development.
///
/// `internal` is the FAD-distributed tester flavor — only this flavor pulls
/// the full firebase-appdistribution SDK (see android/app/build.gradle.kts)
/// and triggers the in-app update prompt + the
/// `forgetrack-internal-builds` FCM topic subscribe.
enum Flavor { dev, prod, internal }

class BuildConfig {
  BuildConfig._();

  static const Flavor flavor = _flavorFromEnv;

  static const _flavorEnv = String.fromEnvironment('FLAVOR', defaultValue: 'dev');

  static const Flavor _flavorFromEnv = _flavorEnv == 'prod'
      ? Flavor.prod
      : _flavorEnv == 'internal'
          ? Flavor.internal
          : Flavor.dev;

  static bool get isDev => flavor == Flavor.dev;
  static bool get isProd => flavor == Flavor.prod;
  static bool get isInternal => flavor == Flavor.internal;
}
