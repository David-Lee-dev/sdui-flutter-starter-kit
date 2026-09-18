import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sdui_engine/sdui_engine.dart';

/// 엔진 통합 테스트 공유 하니스 — [EngineRunner]를 실제 마운트 문맥(`MaterialApp`+`Scaffold`+`Overlay`)에
/// 올려 **EngineRunner→ActionHost→driver 전 배선**을 실제로 타게 한다.
///
/// driver 단위 테스트는 `DriverContext`를 손으로 만들어 이 배선을 건너뛰므로, 마운트-스코프 채널
/// ([EngineHost]의 `modalTemplates`·`registries`·`overlay`)이 한 lane에서 빠져도 못 잡는다(foreground
/// 모달 회귀가 그 사례). 이 하니스로 그 통합 경로를 계약으로 고정한다.
///
/// - `Scaffold` 아래 마운트(Material 조상 필요 — `tabBar` 등).
/// - 오버레이는 [EngineRunner]가 `Overlay.of(context)`(MaterialApp 제공)를 **마운트-스코프로 캡처**한다
///   — 전역 attach 불필요(§2 host 통일). 라우터·토스트가 필요하면 [navigate]·[toast]로 주입한다.
Future<void> pumpEngineTemplate(
  WidgetTester tester,
  Map<String, Object?> template, {
  Map<String, Object?> rootData = const {},
  Map<String, Object?> modalTemplates = const {},
  NavigateHandle? navigate,
  ToastHandle? toast,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: EngineRunner(
          template: template,
          rootData: rootData,
          modalTemplates: modalTemplates,
          navigate: navigate,
          toast: toast,
        ),
      ),
    ),
  );
}
