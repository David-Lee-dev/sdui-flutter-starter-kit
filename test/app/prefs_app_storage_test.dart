import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sdui_starter/app/impl/prefs_app_storage.dart';

void main() {
  group('PrefsAppStorage', () {
    setUp(() => SharedPreferences.setMockInitialValues(const {}));

    group('get / set', () {
      test('JSON 호환 값이 기기 저장소를 왕복한다', () async {
        final storage = await PrefsAppStorage.load();
        await storage.set('profile', {
          'name': 'kim',
          'level': 3,
          'tags': ['a', 'b'],
        });

        // 새로 로드해도 (영속) 같은 값이 나온다.
        final reloaded = await PrefsAppStorage.load();
        expect(reloaded.get('profile'), {
          'name': 'kim',
          'level': 3,
          'tags': ['a', 'b'],
        });
      });

      test('없는 키는 null', () async {
        final storage = await PrefsAppStorage.load();
        expect(storage.get('nope'), isNull);
      });

      test('null 저장은 삭제다', () async {
        final storage = await PrefsAppStorage.load();
        await storage.set('k', 'v');
        await storage.set('k', null);
        expect(storage.get('k'), isNull);
      });
    });
  });
}
