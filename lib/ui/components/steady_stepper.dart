import 'dart:async';

import 'package:flutter/gestures.dart'; // computeHitSlop
import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';
import '../../l10n/app_localizations.dart';
import 'steady_icon.dart';

/// Hàng chỉnh một con số bằng nút − và +. Callback bằng `null` nghĩa là nút
/// đó đang ở giới hạn. Xếp các hàng liền nhau trong `ClipRRect(lg)` và đặt
/// `divider: false` cho hàng cuối.
class SteadyStepper extends StatelessWidget {
  const SteadyStepper({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.detail,
    required this.onDecrement,
    required this.onIncrement,
    this.divider = true,
  });

  final String label;
  final String value;
  final String? icon;
  final String? detail;
  final VoidCallback? onDecrement;
  final VoidCallback? onIncrement;
  final bool divider;

  @override
  Widget build(BuildContext context) {
    final c = SteadyColors.of(context);
    final l10n = AppLocalizations.of(context);
    final large = MediaQuery.textScalerOf(context).scale(16) > 16 * 1.3;
    final title = Row(
      children: [
        if (icon != null) ...[
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: c.surface2,
              shape: BoxShape.circle,
            ),
            child: Center(child: SteadyIcon(icon!, size: 20, color: c.ink)),
          ),
          const SizedBox(width: SteadySpace.s3),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label, style: SteadyText.body.copyWith(color: c.ink)),
              if (detail != null)
                Text(
                  detail!,
                  style: SteadyText.label.copyWith(color: c.inkMuted),
                ),
            ],
          ),
        ),
      ],
    );
    final valueText = ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 64),
      child: Semantics(
        liveRegion: true,
        child: Text(
          value,
          maxLines: 1,
          textAlign: TextAlign.center,
          style: SteadyText.stat.copyWith(color: c.ink),
        ),
      ),
    );
    final controls = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _StepButton(
          icon: SteadyIcons.minus,
          semanticLabel: l10n.decreaseLabel(label),
          onPressed: onDecrement,
        ),
        const SizedBox(width: SteadySpace.s1),
        // Bố cục hai dòng có chỗ rộng cố định: con số lớn quá thì thu nhỏ lại.
        large
            ? Flexible(
                child: FittedBox(fit: BoxFit.scaleDown, child: valueText),
              )
            : valueText,
        const SizedBox(width: SteadySpace.s1),
        _StepButton(
          icon: SteadyIcons.plus,
          semanticLabel: l10n.increaseLabel(label),
          onPressed: onIncrement,
        ),
      ],
    );
    return Container(
      constraints: const BoxConstraints(minHeight: 72),
      padding: const EdgeInsets.symmetric(
        horizontal: SteadySpace.s4,
        vertical: SteadySpace.s3,
      ),
      decoration: BoxDecoration(
        color: c.surface,
        border: divider ? Border(bottom: BorderSide(color: c.line)) : null,
      ),
      child: large
          ? Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                title,
                const SizedBox(height: SteadySpace.s2),
                Align(alignment: Alignment.centerRight, child: controls),
              ],
            )
          : Row(
              children: [
                Expanded(child: title),
                const SizedBox(width: SteadySpace.s3),
                controls,
              ],
            ),
    );
  }
}

/// Nút tròn 48. Nhấn giữ: sau 400 ms thì lặp mỗi 100 ms, dừng khi thả tay,
/// khi bị huỷ, khi ngón tay trượt quá ngưỡng chạm (đang cuộn) hoặc khi nút bị
/// vô hiệu (chạm giới hạn).
class _StepButton extends StatefulWidget {
  const _StepButton({
    required this.icon,
    required this.semanticLabel,
    required this.onPressed,
  });

  final String icon;
  final String semanticLabel;
  final VoidCallback? onPressed;

  @override
  State<_StepButton> createState() => _StepButtonState();
}

class _StepButtonState extends State<_StepButton> {
  static const _holdDelay = Duration(milliseconds: 400);
  static const _repeatEvery = Duration(milliseconds: 100);

  Timer? _timer;
  bool _repeated = false;
  Offset? _downAt;

  @override
  void didUpdateWidget(_StepButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.onPressed == null) _stop();
  }

  @override
  void dispose() {
    _stop();
    super.dispose();
  }

  void _stop() {
    _timer?.cancel();
    _timer = null;
  }

  void _down(PointerDownEvent event) {
    _downAt = event.position;
    _repeated = false;
    _stop();
    if (widget.onPressed == null) return;
    _timer = Timer(_holdDelay, () {
      _repeated = true;
      _fire();
      _timer = Timer.periodic(_repeatEvery, (_) => _fire());
    });
  }

  /// Ngón tay trượt quá ngưỡng chạm: người dùng đang cuộn, không phải nhấn giữ.
  void _move(PointerMoveEvent event) {
    final downAt = _downAt;
    if (downAt == null || _timer == null) return;
    final slop = computeHitSlop(
      event.kind,
      MediaQuery.maybeGestureSettingsOf(context),
    );
    if ((event.position - downAt).distance > slop) _stop();
  }

  void _fire() {
    final callback = widget.onPressed;
    if (callback == null) {
      _stop();
      return;
    }
    callback();
  }

  void _tap() {
    // Thả tay sau khi đã lặp: các bước đã chạy rồi, không thêm một bước nữa.
    if (_repeated) {
      _repeated = false;
      return;
    }
    widget.onPressed?.call();
  }

  @override
  Widget build(BuildContext context) {
    final c = SteadyColors.of(context);
    final enabled = widget.onPressed != null;
    const shape = CircleBorder();
    final button = Listener(
      onPointerDown: _down,
      onPointerMove: _move,
      onPointerUp: (_) {
        _stop();
        _downAt = null;
      },
      onPointerCancel: (_) {
        _stop();
        _repeated = false;
        _downAt = null;
      },
      child: Material(
        color: c.surface2,
        shape: shape,
        child: InkWell(
          onTap: enabled ? _tap : null,
          customBorder: shape,
          child: SizedBox.square(
            dimension: SteadySize.tap,
            child: Center(
              child: SteadyIcon(widget.icon, size: 18, color: c.ink),
            ),
          ),
        ),
      ),
    );
    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.semanticLabel,
      onTap: widget.onPressed,
      excludeSemantics: true,
      child: enabled ? button : Opacity(opacity: 0.4, child: button),
    );
  }
}
