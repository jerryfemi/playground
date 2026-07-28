import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:motor/motor.dart';

/// A spring button with:
/// - press-down scale
/// - friction-based drag following
/// - spring snap-back on release
///
/// This widget uses:
/// - [SingleMotionBuilder] to animate scale
/// - [MotionBuilder] to animate translation as [Offset]
///
/// The interaction model is intentionally "direct-manipulation first":
/// while the user drags, we update the target offset immediately.
/// When they release, we set the target back to zero and let Motor spring it back.
class SpringButton extends StatefulWidget {
  const SpringButton({
    super.key,
    required this.child,
    this.onTap,
    this.pressedScale = 0.9,
    this.dragFriction = 19.0,
    this.maxTranslation = const Offset(24, 24),
    this.translationMotion,
    this.scaleMotion,
    this.hitTestBehavior = HitTestBehavior.opaque,
    this.enableTapHaptics = false,
    this.enableReleaseHaptics = false,
  });

  /// Button contents.
  final Widget child;

  /// Called when interaction ends and is considered a tap rather than a drag.
  final VoidCallback? onTap;

  /// Scale while finger is down.
  final double pressedScale;

  /// Example: 3.0 means the widget moves 1 px for every 3 px of finger movement.
  final double dragFriction;

  /// Maximum visual translation allowed while dragging.
  final Offset maxTranslation;

  /// Motion used for translation springing.
  ///
  /// If null, defaults to [CupertinoMotion.interactive()] for a responsive feel.
  final Motion? translationMotion;

  /// Motion used for scale springing.
  ///
  /// If null, defaults to [CupertinoMotion.snappy()].
  final Motion? scaleMotion;

  final HitTestBehavior hitTestBehavior;

  final bool enableTapHaptics;
  final bool enableReleaseHaptics;

  @override
  State<SpringButton> createState() => _SpringButtonState();
}

class _SpringButtonState extends State<SpringButton> {
  /// Accumulated drag distance must exceed this before the gesture
  /// is classified as a drag (and therefore won't fire onTap on release).
  /// A single threshold eliminates the confusing 4px / 8px dual-check
  /// from the original code.
  static const double _dragThreshold = 8.0;

  /// Current target translation for MotionBuilder.
  Offset _targetOffset = Offset.zero;

  /// The raw unconstrained drag distance, used to calculate the rubber-band effect.
  Offset _rawTranslation = Offset.zero;

  /// Current target scale for SingleMotionBuilder.
  double _targetScale = 1.0;

  bool _pointerDown = false;
  bool _dragged = false;
  double _accumulatedDragDistance = 0.0;

  Motion get _translationMotion =>
      widget.translationMotion ?? const CupertinoMotion.interactive();

  Motion get _scaleMotion =>
      widget.scaleMotion ?? const CupertinoMotion.snappy();

  // ---------------------------------------------------------------------------
  // Tap handlers — these cover the case where the finger presses and lifts
  // without moving past touch slop. In that scenario, the pan recognizer never
  // wins the gesture arena, so onPanEnd / onPanCancel never fire. Without
  // onTapUp / onTapCancel, the button would stay permanently scaled down.
  // ---------------------------------------------------------------------------

  void _handleTapDown(TapDownDetails details) {
    _pointerDown = true;
    _dragged = false;
    _accumulatedDragDistance = 0.0;

    setState(() {
      _targetScale = widget.pressedScale;
    });
  }

  void _handleTapUp(TapUpDetails details) {
    _pointerDown = false;
    _resetToRest();

    if (!_dragged) {
      if (widget.enableTapHaptics) HapticFeedback.selectionClick();
      widget.onTap?.call();
    }
  }

  // We omit _handleTapCancel. If a genuine cancellation occurs (e.g. scroll view
  // takes over), BOTH Tap and Pan recognizers lose the gesture arena, which means
  // onPanCancel will safely handle the reset. If we include onTapCancel, the Pan
  // recognizer winning the arena will trigger onTapCancel and prematurely reset
  // our button state while dragging.

  // ---------------------------------------------------------------------------
  // Pan handlers — these fire when the finger moves past touch slop.
  // ---------------------------------------------------------------------------

  void _handlePanUpdate(DragUpdateDetails details) {
    if (!_pointerDown) return;

    final friction = widget.dragFriction <= 0 ? 1.0 : widget.dragFriction;
    _rawTranslation += details.delta;

    // Classic rubber-band formula: c * (1 - (1 / ((x * 0.55 / c) + 1)))
    double rubberBand(double distance, double limit) {
      if (distance == 0 || limit == 0) return 0;
      final absDist = distance.abs();
      return (1.0 - (1.0 / ((absDist * 0.55 / limit) + 1.0))) *
          limit *
          distance.sign;
    }

    final next = Offset(
      rubberBand(_rawTranslation.dx / friction, widget.maxTranslation.dx),
      rubberBand(_rawTranslation.dy / friction, widget.maxTranslation.dy),
    );

    _accumulatedDragDistance += details.delta.distance;
    if (_accumulatedDragDistance > _dragThreshold) {
      _dragged = true;
    }

    setState(() {
      _targetOffset = next;
    });
  }

  void _handlePanEnd(DragEndDetails details) {
    _pointerDown = false;
    _resetToRest();

    // If the finger barely moved, treat it as a tap.
    if (!_dragged) {
      if (widget.enableTapHaptics) HapticFeedback.selectionClick();
      widget.onTap?.call();
    }
  }

  void _handlePanCancel() {
    _pointerDown = false;
    _resetToRest();
  }

  // ---------------------------------------------------------------------------
  // Shared reset
  // ---------------------------------------------------------------------------

  void _resetToRest() {
    setState(() {
      _rawTranslation = Offset.zero;
      _targetOffset = Offset.zero;
      _targetScale = 1.0;
    });

    if (widget.enableReleaseHaptics) {
      HapticFeedback.selectionClick();
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: widget.hitTestBehavior,
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onPanUpdate: _handlePanUpdate,
      onPanEnd: _handlePanEnd,
      onPanCancel: _handlePanCancel,
      child: SingleMotionBuilder(
        motion: _scaleMotion,
        value: _targetScale,
        builder: (context, animatedScale, child) {
          return MotionBuilder(
            motion: _translationMotion,
            value: _targetOffset,
            from: Offset.zero,
            converter: const OffsetMotionConverter(),
            builder: (context, animatedOffset, child) {
              return Transform.translate(
                offset: animatedOffset,
                child: Transform.scale(scale: animatedScale, child: child),
              );
            },
            child: RepaintBoundary(child: widget.child),
          );
        },
      ),
    );
  }
}
