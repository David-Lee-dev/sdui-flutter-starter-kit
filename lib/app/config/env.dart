import 'package:sdui_starter/app/config/env.g.dart';

/// Compile-time configuration.
///
/// Values come from the generated [EnvG] (run `scripts/gen_env.sh <flavor>`
/// after editing a `.env.<flavor>` file — `scripts/set_local_ip.sh` does the
/// local-IP case end to end). A `--dart-define` still overrides for one-off
/// runs: `flutter run --dart-define=SDUI_SERVER_URL=http://10.0.2.2:8080`.
final class Env {
  const Env._();

  /// Base URL of the server hosting compiled templates and data operations.
  static const serverUrl = String.fromEnvironment(
    'SDUI_SERVER_URL',
    defaultValue: EnvG.serverUrl,
  );

  /// App version sent as `x-app-version` — selects template version thresholds.
  static const appVersion = String.fromEnvironment(
    'SDUI_APP_VERSION',
    defaultValue: EnvG.appVersion,
  );

  /// Active env flavor (`local` / `dev` / `prod`).
  static const flavor = EnvG.flavor;
}
