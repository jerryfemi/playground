import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'drag_menu_overlay.dart';

export 'drag_menu_overlay.dart' show DragMenuItem;

/// Continuous drag menu with spring-like interaction.
///
/// Interaction flow:
/// 1. User long-presses the child.
/// 2. A floating menu appears near the finger using [OverlayEntry].
/// 3. The finger stays down; vertical dragging changes highlighted item.
/// 4. Haptic tick fires only when highlighted index changes.
/// 5. On release, the highlighted action executes and overlay closes.
///
/// This intentionally does NOT use `showMenu` or routes.
class DragMenu extends StatefulWidget {
  const DragMenu({
    super.key,
    required this.child,
    required this.items,
    this.itemHeight = 30,
    this.menuWidth = 150,
    this.margin = 12,
    this.deadZone = 10,
    this.anchorGap = 8,
    this.highlightColor = const Color(0x14007AFF),
    this.backgroundColor = Colors.white,
    this.borderRadius = 26,
    this.itemBorderRadius = 12,
    this.enableHaptics = true,
    this.initialIndex = 0,
  });

  final Widget child;
  final List<DragMenuItem> items;

  /// Height for each selectable row.
  final double itemHeight;

  /// Width of the menu overlay.
  final double menuWidth;

  /// Minimum screen margin for placement.
  final double margin;

  /// Small movement buffer before selection starts changing.
  final double deadZone;

  /// Gap between finger position and menu.
  final double anchorGap;

  final Color highlightColor;
  final Color backgroundColor;
  final double borderRadius;
  final double itemBorderRadius;
  final bool enableHaptics;

  /// Initial highlighted item when menu appears.
  final int initialIndex;

  @override
  State<DragMenu> createState() => _DragMenuState();
}

class _DragMenuState extends State<DragMenu> {
  OverlayEntry? _overlayEntry;

  int _hoveredIndex = -1;

  Offset? _pressGlobalPosition;
  bool _spawnUpward = false;

  double _menuLeft = 0;
  double _menuTop = 0;

  /// Cached screen size — captured once in [_handleLongPressStart] and reused
  /// in [_handleLongPressMoveUpdate] to avoid a widget tree lookup every frame.
  Size? _cachedScreenSize;

  double get _menuHeight => widget.items.length * widget.itemHeight + 16;

  @override
  void dispose() {
    _removeOverlay();
    super.dispose();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _markNeedsBuild() {
    _overlayEntry?.markNeedsBuild();
  }

  void _showOverlay() {
    _overlayEntry = OverlayEntry(
      builder: (context) {
        return DragMenuOverlay(
          left: _menuLeft,
          top: _menuTop,
          width: widget.menuWidth,
          itemHeight: widget.itemHeight,
          items: widget.items,
          highlightedIndex: _hoveredIndex,
          backgroundColor: widget.backgroundColor,
          highlightColor: widget.highlightColor,
          borderRadius: widget.borderRadius,
          itemBorderRadius: widget.itemBorderRadius,
        );
      },
    );

    Overlay.of(context, rootOverlay: true).insert(_overlayEntry!);
  }

  void _handleLongPressStart(LongPressStartDetails details) {
    if (!mounted || widget.items.isEmpty) return;

    _pressGlobalPosition = details.globalPosition;
    _hoveredIndex = widget.initialIndex.clamp(0, widget.items.length - 1);

    // Cache screen size once — it can't change mid-gesture.
    final media = MediaQuery.of(context);
    final size = media.size;
    _cachedScreenSize = size;

    final totalMenuHeight = _menuHeight;
    final spaceBelow = size.height - details.globalPosition.dy - widget.margin;
    final spaceAbove = details.globalPosition.dy - widget.margin;

    // If insufficient space below, prefer spawning upward.
    _spawnUpward = spaceBelow < totalMenuHeight && spaceAbove > spaceBelow;

    _menuLeft = (details.globalPosition.dx + 12).clamp(
      widget.margin,
      size.width - widget.menuWidth - widget.margin,
    );

    _menuTop = _spawnUpward
        ? (details.globalPosition.dy - totalMenuHeight - widget.anchorGap)
              .clamp(
                widget.margin,
                size.height - totalMenuHeight - widget.margin,
              )
        : (details.globalPosition.dy + widget.anchorGap).clamp(
            widget.margin,
            size.height - totalMenuHeight - widget.margin,
          );

    _showOverlay();
    _markNeedsBuild();

    // Haptic feedback when the menu first appears — matches Telegram behaviour.
    if (widget.enableHaptics) {
      HapticFeedback.mediumImpact();
    }
  }

  void _handleLongPressMoveUpdate(LongPressMoveUpdateDetails details) {
    if (_overlayEntry == null || _pressGlobalPosition == null) return;
    if (widget.items.isEmpty) return;

    final size = _cachedScreenSize!;

    // We use the finger's movement relative to the original press point.
    final deltaY = details.globalPosition.dy - _pressGlobalPosition!.dy;

    // Dead zone: tiny wiggles do not immediately change item.
    double adjustedDy;
    if (deltaY.abs() <= widget.deadZone) {
      adjustedDy = 0;
    } else {
      adjustedDy = deltaY.sign * (deltaY.abs() - widget.deadZone);
    }

    // Hovered index is based on dy / itemHeight, floored.
    final stepped = (adjustedDy / widget.itemHeight).floor();

    // If menu spawns upward, dragging upward should move deeper into the list.
    // If it spawns downward, dragging downward should move deeper into the list.
    final nextIndex = _spawnUpward
        ? (widget.initialIndex - stepped)
        : (widget.initialIndex + stepped);

    final clampedIndex = nextIndex.clamp(0, widget.items.length - 1);

    if (clampedIndex != _hoveredIndex) {
      _hoveredIndex = clampedIndex;
      if (widget.enableHaptics) {
        HapticFeedback.selectionClick();
      }
    }

    // Menu stays stationary. We don't update _menuTop here anymore.
    // _menuTop = desiredTop.clamp(...);

    _markNeedsBuild();
  }

  void _handleLongPressEnd(LongPressEndDetails details) {
    if (_hoveredIndex >= 0 && _hoveredIndex < widget.items.length) {
      widget.items[_hoveredIndex].onSelected();
    }

    _removeOverlay();
    _reset();
  }

  void _handleLongPressCancel() {
    _removeOverlay();
    _reset();
  }

  void _reset() {
    _hoveredIndex = -1;
    _pressGlobalPosition = null;
    _spawnUpward = false;
    _menuLeft = 0;
    _menuTop = 0;
    _cachedScreenSize = null;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onLongPressStart: _handleLongPressStart,
      onLongPressMoveUpdate: _handleLongPressMoveUpdate,
      onLongPressEnd: _handleLongPressEnd,
      onLongPressCancel: _handleLongPressCancel,
      child: widget.child,
    );
  }
}
