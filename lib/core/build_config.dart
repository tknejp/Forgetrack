/// Compile-time build configuration. Pass `--dart-define=FLAVOR=prod`
/// (or `dev` / `internal`) to `flutter run` / `flutter build` to select the
/// flavor. Defaults to `dev` so a bare `flutter run` (e.g. from an IDE play
/// button) keeps working during development.
///
/// `internal` is the friend-tester flavor — only this flavor pulls the
/// REQUEST_INSTALL_PACKAGES permission (via `android/app/src/internal/
/// AndroidManifest.xml`) and runs the DIY in-app updater that polls
/// Firestore for newer builds and offers the system install prompt
/// (see `lib/core/services/app_update_service.dart`).
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
