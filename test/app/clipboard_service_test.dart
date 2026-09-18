import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sdui_engine/sdui_engine.dart';

import 'package:sdui_starter/app/service/clipboard_service.dart';

CommandInvocation _invocation(
  Map<String, Object?> params, {
  bool cancelled = false,
}) => CommandInvocation(
  params: params,
  event: null,
  isCancelled: () => cancelled,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final calls = <MethodCall>[];
  String? clipboardText;

  setUp(() {
    calls.clear();
    clipboardText = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          calls.add(call);
          if (call.method == 'Clipboard.setData') {
            clipboardText = (call.arguments as Map)['text'] as String?;
            return null;
          }
          if (call.method == 'Clipboard.getData') {
            return clipboardText == null ? null : {'text': clipboardText};
          }
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  group('ClipboardService', () {
    group('commands', () {
      test('contributes the copy and read command types', () {
        expect(
          const ClipboardService().commands.map((c) => c.type),
          ['sys_clipboard_copy', 'sys_clipboard_read'],
        );
      });
    });
  });

  group('ClipboardCopyCommand', () {
    group('run', () {
      test('writes params.text to the system clipboard', () async {
        await const ClipboardCopyCommand().run(
          _invocation(const {'text': 'CODE-42'}),
        );
        expect(clipboardText, 'CODE-42');
      });

      test('missing text is an authoring error', () {
        expect(
          () => const ClipboardCopyCommand().run(_invocation(const {})),
          throwsArgumentError,
        );
      });

      test('cancelled invocation does nothing', () async {
        await const ClipboardCopyCommand().run(
          _invocation(const {'text': 'x'}, cancelled: true),
        );
        expect(calls, isEmpty);
      });
    });
  });

  group('ClipboardReadCommand', () {
    group('run', () {
      test('returns {text} for the _then flow as \$data', () async {
        clipboardText = 'pasted';
        final data = await const ClipboardReadCommand().run(
          _invocation(const {}),
        );
        expect(data, {'text': 'pasted'});
      });

      test('empty clipboard is a coded failure the template can branch on',
          () {
        expect(
          () => const ClipboardReadCommand().run(_invocation(const {})),
          throwsA(
            isA<CommandFailure>().having((e) => e.code, 'code', 'EMPTY'),
          ),
        );
      });
    });
  });
}
