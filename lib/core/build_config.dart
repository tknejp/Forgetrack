/// Compile-time build configuration. Pass `--dart-define=FLAVOR=prod`
/// (or `dev`) to `flutter run` / `flutter build` to select the flavor.
/// Defaults to `dev` so a bare `flutter run` (e.g. from an IDE play
/// button) keeps working during development.
enum Flavor { dev, prod }

class BuildConfig {
  BuildConfig._();

  static const Flavor flavor = _flavorFromEnv;

  static const _flavorEnv = String.fromEnvironment('FLAVOR', defaultValue: 'dev');

  static const Flavor _flavorFromEnv =
      _flavorEnv == 'prod' ? Flavor.prod : Flavor.dev;

  static bool get isDev => flavor == Flavor.dev;
  static bool get isProd => flavor == Flavor.prod;
}
