import 'package:flutter/services.dart';
import 'package:sdui_engine/sdui_engine.dart';

/// Example [SduiService] — the app's clipboard integration.
///
/// ## What a service is
///
/// A service is how an app adds NEW capability to the template language.
/// The engine seals its own drivers (`set`, `api`, `navigate`, ...); anything
/// beyond them — platform features, vendor SDKs (ads, support chat, social
/// login) — enters as a service: a bundle of [ExternalCommand]s plus an
/// [onRegister] setup hook, wired once at boot:
///
/// ```dart
/// Sdui.initialize(..., services: [ClipboardService()]);
/// ```
///
/// ## What an ExternalCommand is
///
/// One command = one verb the server's templates can invoke. Registering a
/// command whose [ExternalCommand.type] is `sys_clipboard_copy` makes this a
/// valid template action:
///
/// ```yaml
/// _action:
///   copy_code:
///     _type: sys_clipboard_copy        # <- ExternalCommand.type
///     text: '${coupon.code}'           # <- arrives in invocation.params
///     _then:
///       - { _type: toast, message: 복사되었습니다 }
/// ```
///
/// The engine handles everything around the call — resolving `${}` bindings
/// in params, running `_then`/`_error`/`_dismiss` continuations, dedupe,
/// logging, telemetry. The command only does its one job and communicates
/// through its return/throw:
///
/// - **return a value** → success; the value is exposed to the `_then` flow
///   as `$data` (return `null` when there is nothing to report).
/// - **throw [CommandFailure]`(code)`** → an expected domain failure; the
///   template's `_error[code]` flow runs (`_error._` is the catch-all).
/// - **throw [CommandDismissed]** → the user backed out; the `_dismiss` flow
///   runs — deliberately not an error.
/// - anything else thrown → an engine-reported defect, not a template branch.
///
/// [CommandInvocation] is the safe surface the engine hands in: resolved
/// [CommandInvocation.params], the tap's [CommandInvocation.event] payload,
/// [CommandInvocation.isCancelled] (check before irreversible work — the
/// screen may have been disposed mid-flight), and
/// [CommandInvocation.correlationId] for telemetry/server correlation.
/// It deliberately excludes engine internals — a command returns data;
/// it never mutates engine state directly (templates do that with `_set`
/// in the `_then` flow).
class ClipboardService extends SduiService {
  const ClipboardService();

  /// Each command here becomes one template-callable `_type`.
  @override
  List<ExternalCommand> get commands => const [
    ClipboardCopyCommand(),
    ClipboardReadCommand(),
  ];

  /// One-time setup, called before the engine catalog freezes.
  ///
  /// The clipboard needs none; an SDK-backed service (ads, support chat)
  /// initializes its SDK here.
  @override
  void onRegister() {}
}

/// `{ _type: sys_clipboard_copy, text: ... }` — writes [text] to the system
/// clipboard. Returns nothing; a confirmation toast belongs to the template's
/// `_then` flow, not here.
class ClipboardCopyCommand implements ExternalCommand {
  const ClipboardCopyCommand();

  @override
  String get type => 'sys_clipboard_copy';

  @override
  Future<Object?> run(CommandInvocation invocation) async {
    final text = invocation.params['text'];
    if (text is! String || text.isEmpty) {
      // Malformed params are authoring errors — throw the argument error so
      // the engine reports a defect instead of running an _error flow.
      throw ArgumentError.value(
        text,
        'text',
        'sys_clipboard_copy requires a non-empty "text"',
      );
    }
    if (invocation.isCancelled) return null;
    await Clipboard.setData(ClipboardData(text: text));
    return null;
  }
}

/// `{ _type: sys_clipboard_read }` — reads the clipboard and exposes it to
/// the `_then` flow as `${data.text}`:
///
/// ```yaml
/// paste_code:
///   _type: sys_clipboard_read
///   _then:
///     - { _type: set, code_input: '${data.text}' }
///   _error:
///     _: [{ _type: toast, message: 클립보드가 비어 있습니다 }]
/// ```
class ClipboardReadCommand implements ExternalCommand {
  const ClipboardReadCommand();

  @override
  String get type => 'sys_clipboard_read';

  @override
  Future<Object?> run(CommandInvocation invocation) async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text;
    if (text == null || text.isEmpty) {
      // An empty clipboard is an expected condition the template may branch
      // on — a coded CommandFailure, not a crash.
      throw const CommandFailure('EMPTY', message: 'clipboard is empty');
    }
    return {'text': text};
  }
}
