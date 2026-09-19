// Advanced press feedback ported from the tuk app — the starter's example of
// replacing the engine's stock ink ripple through the TapFeedback contract.
//
// Inject at boot:
//   Sdui.initialize(
//     presentation: const SduiPresentation(tapFeedback: PressTapFeedback()),
//   );

import 'package:sdui_engine/sdui_engine.dart';

import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// 누름 피드백의 시각 상수와 크기 규칙.
///
/// 값은 실측 벤치에서 고른 것이다. 핵심은 두 가지 — 들어올 때와 나갈 때의 시간이
/// 다르다는 것(비대칭), 그리고 스케일이 비율이 아니라 **픽셀 인셋 상수**에서 나온다는
/// 것이다. 비율을 고정하면 넓은 카드는 출렁이고 작은 아이콘은 꿈쩍도 하지 않는다.
final class PressSpec {
  const PressSpec._();

  /// 다크 단일 팔레트라 누름은 '밝히는' 방향이다.
  static const Color tint = Color(0xFFEDEDED);

  /// 최대 세기. Material 3 규정값(6%)보다 높다 — 실기기에서 지각 가능한 최소치.
  /// `#2C2C2C` 표면이 `#3F3F3F`가 된다.
  static const double tintOpacity = 0.10;

  /// 눌렸을 때 각 변이 안쪽으로 들어오는 목표 픽셀.
  static const double inset = 3.5;

  /// 작은 타깃이 과하게 출렁이지 않도록 하는 하한.
  static const double minScale = 0.94;

  /// 큰 표면에서도 눌림이 사라지지 않도록 하는 상한.
  static const double maxScale = 0.985;

  static const Duration inDuration = Duration(milliseconds: 110);
  static const Duration outDuration = Duration(milliseconds: 240);

  /// 양방향 모두 감속. 등속이면 기계처럼 보인다.
  static const Curve curve = Cubic(0.2, 0, 0, 1);

  /// [size]를 눌렀을 때 쓸 스케일 배율을 돌려준다.
  ///
  /// 긴 변을 기준으로 삼아 인셋을 상수로 유지한다. 짧은 변을 기준으로 잡으면
  /// 가로로 긴 카드에서 좌우 인셋만 크게 벌어져 카드가 찌그러져 보인다.
  ///
  /// @param size - 눌리는 표면의 렌더된 크기
  /// @returns [minScale]~[maxScale]로 잘린 배율. 크기를 모르면 [maxScale]
  static double scaleFor(Size size, {double inset = PressSpec.inset}) {
    final longest = math.max(size.width, size.height);
    if (!longest.isFinite || longest <= 0) return maxScale;
    return (1 - (2 * inset) / longest).clamp(minScale, maxScale);
  }
}

/// 자식에 누름 피드백(압인 + 틴트)을 입힌다.
///
/// 두 효과를 한 렌더 오브젝트에 모은 이유는 [amount]가 0일 때 트랜스폼도 saveLayer도
/// 만들지 않기 위해서다. 위젯을 눌릴 때만 끼워 넣는 방식은 자식 엘리먼트를 재부모화해
/// 서브트리의 State를 날린다.
class PressFeedback extends SingleChildRenderObjectWidget {
  const PressFeedback({
    super.key,
    required this.amount,
    this.tint = PressSpec.tint,
    this.tintOpacity = PressSpec.tintOpacity,
    this.inset = PressSpec.inset,
    super.child,
  });

  /// 누름 진행도. 0이면 아무것도 그리지 않는다.
  final double amount;

  final Color tint;

  /// [amount]가 1일 때의 틴트 세기.
  final double tintOpacity;

  /// 눌렸을 때 각 변이 들어오는 목표 픽셀.
  final double inset;

  @override
  RenderPressFeedback createRenderObject(BuildContext context) =>
      RenderPressFeedback(
        amount: amount,
        tint: tint,
        tintOpacity: tintOpacity,
        inset: inset,
      );

  @override
  void updateRenderObject(
    BuildContext context,
    RenderPressFeedback renderObject,
  ) {
    renderObject
      ..amount = amount
      ..tint = tint
      ..tintOpacity = tintOpacity
      ..inset = inset;
  }
}

/// 압인과 틴트를 그리는 렌더 오브젝트.
///
/// 틴트는 [BlendMode.srcATop]이라 자식이 **실제로 칠한 픽셀**에만 얹힌다. 출력 알파가
/// destination의 알파이므로 둥근 모서리 바깥은 투명하게 남는다. 덕분에 모서리 값을
/// 조회하거나 추정할 필요가 없고, 원형·말풍선·이미지처럼 사각형이 아닌 표면도 그대로
/// 따라간다.
class RenderPressFeedback extends RenderProxyBox {
  RenderPressFeedback({
    required double amount,
    required Color tint,
    required double tintOpacity,
    required double inset,
  }) : _amount = amount,
       _tint = tint,
       _tintOpacity = tintOpacity,
       _inset = inset;

  final LayerHandle<ColorFilterLayer> _filter = LayerHandle<ColorFilterLayer>();

  double get amount => _amount;
  double _amount;
  set amount(double value) {
    final next = value.clamp(0.0, 1.0);
    if (next == _amount) return;
    final wasIdle = _amount <= 0;
    _amount = next;
    // 0을 넘나들 때만 합성 필요 여부가 바뀐다.
    if (wasIdle != (next <= 0)) markNeedsCompositingBitsUpdate();
    markNeedsPaint();
  }

  Color get tint => _tint;
  Color _tint;
  set tint(Color value) {
    if (value == _tint) return;
    _tint = value;
    markNeedsPaint();
  }

  double get tintOpacity => _tintOpacity;
  double _tintOpacity;
  set tintOpacity(double value) {
    if (value == _tintOpacity) return;
    _tintOpacity = value;
    markNeedsPaint();
  }

  double get inset => _inset;
  double _inset;
  set inset(double value) {
    if (value == _inset) return;
    _inset = value;
    markNeedsPaint();
  }

  /// 현재 적용 중인 배율. 눌리지 않았으면 1.
  double get scale {
    if (_amount <= 0 || !hasSize) return 1;
    return 1 - _amount * (1 - PressSpec.scaleFor(size, inset: _inset));
  }

  /// 현재 틴트 알파.
  double get tintAlpha => _amount <= 0 ? 0 : _tintOpacity * _amount;

  // 눌린 동안에만 레이어를 만든다.
  @override
  bool get alwaysNeedsCompositing => _amount > 0;

  Matrix4 _effectiveTransform() {
    final center = size.center(Offset.zero);
    final factor = scale;
    return Matrix4.identity()
      ..translateByDouble(center.dx, center.dy, 0, 1)
      ..scaleByDouble(factor, factor, 1, 1)
      ..translateByDouble(-center.dx, -center.dy, 0, 1);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final child = this.child;
    if (child == null) return;
    if (_amount <= 0) {
      layer = null;
      _filter.layer = null;
      context.paintChild(child, offset);
      return;
    }
    layer = context.pushTransform(
      needsCompositing,
      offset,
      _effectiveTransform(),
      (PaintingContext inner, Offset innerOffset) {
        _filter.layer = inner.pushColorFilter(
          innerOffset,
          ColorFilter.mode(
            _tint.withValues(alpha: tintAlpha),
            BlendMode.srcATop,
          ),
          (PaintingContext ctx, Offset off) => ctx.paintChild(child, off),
          oldLayer: _filter.layer,
        );
      },
      oldLayer: layer as TransformLayer?,
    );
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    if (_amount <= 0) {
      return super.hitTestChildren(result, position: position);
    }
    return result.addWithPaintTransform(
      transform: _effectiveTransform(),
      position: position,
      hitTest: (BoxHitTestResult inner, Offset transformed) =>
          super.hitTestChildren(inner, position: transformed),
    );
  }

  @override
  void applyPaintTransform(RenderBox child, Matrix4 transform) {
    if (_amount <= 0) return;
    transform.multiply(_effectiveTransform());
  }

  @override
  void dispose() {
    _filter.layer = null;
    super.dispose();
  }
}

/// 탭 제스처를 받아 누름 피드백을 재생한다.
///
/// 효과는 손가락 상태를 따라간다 — 누르면 [PressSpec.inDuration]에 걸쳐 오르고,
/// 누르는 동안 유지되며, 떼면 더 느긋하게([PressSpec.outDuration]) 빠진다. 스크롤에
/// 제스처를 뺏기면(`onTapCancel`) 들어올 때만큼 빠르게 되돌려 잔상을 남기지 않는다.
class TapEffect extends StatefulWidget {
  const TapEffect({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.onDoubleTap,
    this.tint = PressSpec.tint,
    this.tintOpacity = PressSpec.tintOpacity,
    this.pressInset = PressSpec.inset,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onDoubleTap;
  final Color tint;
  final double tintOpacity;
  final double pressInset;

  @override
  State<TapEffect> createState() => _TapEffectState();
}

class _TapEffectState extends State<TapEffect>
    with SingleTickerProviderStateMixin {
  late final AnimationController _press = AnimationController(
    vsync: this,
    duration: PressSpec.inDuration,
    reverseDuration: PressSpec.outDuration,
  );

  late final CurvedAnimation _amount = CurvedAnimation(
    parent: _press,
    curve: PressSpec.curve,
    reverseCurve: PressSpec.curve,
  );

  @override
  void dispose() {
    _amount.dispose();
    _press.dispose();
    super.dispose();
  }

  // animateBack의 곡선은 linear로 둔다 — 곡선은 _amount가 이미 입힌다.
  void _cancel() => _press.animateBack(0, duration: PressSpec.inDuration);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _press.forward(),
      onTapUp: (_) => _press.reverse(),
      onTapCancel: _cancel,
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      onDoubleTap: widget.onDoubleTap,
      child: AnimatedBuilder(
        animation: _amount,
        builder: (context, child) => PressFeedback(
          amount: _amount.value,
          tint: widget.tint,
          tintOpacity: widget.tintOpacity,
          inset: widget.pressInset,
          child: child,
        ),
        child: widget.child,
      ),
    );
  }
}


/// The app's [TapFeedback]: tint + press-inset feedback instead of the
/// engine's default ink ripple.
final class PressTapFeedback extends TapFeedback {
  const PressTapFeedback({
    this.tint = PressSpec.tint,
    this.tintOpacity = PressSpec.tintOpacity,
    this.pressInset = PressSpec.inset,
  });

  final Color tint;
  final double tintOpacity;
  final double pressInset;

  @override
  Widget wrap(
    BuildContext context,
    Widget child, {
    required VoidCallback onTap,
    VoidCallback? onLongPress,
    VoidCallback? onDoubleTap,
  }) => TapEffect(
    onTap: onTap,
    onLongPress: onLongPress,
    onDoubleTap: onDoubleTap,
    tint: tint,
    tintOpacity: tintOpacity,
    pressInset: pressInset,
    child: child,
  );
}
