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
    this.itemHeight = 35,
    this.menuWidth = 150,
    this.margin = 12,
    this.deadZone = 10,
    this.anchorGap = 8,
    this.highlightColor = const Color(0x14007AFF),
    this.backgroundColor = Colors.white,
    this.borderRadius = 26,
    this.itemBorderRadius = 26,
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
  bool _isLockedOpen = false;
  bool _isClosing = false;

  Offset? _pressGlobalPosition;
  Rect? _childRect;
  bool _spawnUpward = false;

  double _menuLeft = 0;
  double _menuTop = 0;


  double get _menuHeight => widget.items.length * widget.itemHeight + 16;

  @override
  void dispose() {
    _removeOverlay();
    super.dispose();
  }

  void _removeOverlay() async {
    if (_overlayEntry == null || _isClosing) return;

    // Trigger closing animation in the overlay
    _isClosing = true;
    _markNeedsBuild();

    // Wait for the reverse spring animation (150ms)
    await Future.delayed(const Duration(milliseconds: 150));

    _overlayEntry?.remove();
    _overlayEntry = null;

    if (mounted) {
      setState(() {
        _isClosing = false;
      }); // Re-show the original child
    }
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
          isLockedOpen: _isLockedOpen,
          isClosing: _isClosing,
          childReplica: widget.child,
          childRect: _childRect,
          onClose: () {
            _removeOverlay();
            Future.delayed(const Duration(milliseconds: 150), () {
              if (mounted) _reset();
            });
          },
        );
      },
    );

    Overlay.of(context, rootOverlay: true).insert(_overlayEntry!);
    setState(() {}); // Hide original child
  }

  void _handleLongPressStart(LongPressStartDetails details) {
    if (!mounted || widget.items.isEmpty) return;

    _pressGlobalPosition = details.globalPosition;
    _hoveredIndex = -1; // Start unhovered until they drag into the menu bounds
    _isLockedOpen = false;

    // Get exact screen coordinates of the child for the iOS lift effect.
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      final size = renderBox.size;
      final position = renderBox.localToGlobal(Offset.zero);
      _childRect = position & size;
    }

    // Fetch screen size once — it can't change mid-gesture.
    final media = MediaQuery.of(context);
    final size = media.size;

    final totalMenuHeight = _menuHeight;
    final childBottom = _childRect?.bottom ?? details.globalPosition.dy;
    final childTop = _childRect?.top ?? details.globalPosition.dy;

    final spaceBelow = size.height - childBottom - widget.margin;
    final spaceAbove = childTop - widget.margin;

    // If insufficient space below, prefer spawning upward.
    _spawnUpward = spaceBelow < totalMenuHeight && spaceAbove > spaceBelow;

    if (_childRect != null) {
      // If widget is mostly on the right side of the screen, right-align the menu
      if (_childRect!.center.dx > size.width / 2) {
        _menuLeft = (_childRect!.right - widget.menuWidth).clamp(
          widget.margin,
          size.width - widget.menuWidth - widget.margin,
        );
      } else {
        // Otherwise left-align
        _menuLeft = _childRect!.left.clamp(
          widget.margin,
          size.width - widget.menuWidth - widget.margin,
        );
      }
    } else {
      _menuLeft = (details.globalPosition.dx + 12).clamp(
        widget.margin,
        size.width - widget.menuWidth - widget.margin,
      );
    }

    _menuTop = _spawnUpward
        ? (childTop - totalMenuHeight - widget.anchorGap).clamp(
            widget.margin,
            size.height - totalMenuHeight - widget.margin,
          )
        : (childBottom + widget.anchorGap).clamp(
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

    final index = _getHoveredIndex(details.globalPosition);

    if (index != _hoveredIndex) {
      _hoveredIndex = index;
      if (_hoveredIndex != -1 && widget.enableHaptics) {
        HapticFeedback.selectionClick();
      }
      _markNeedsBuild();
    }
  }

  int _getHoveredIndex(Offset globalPos) {
    // 1. Check if X is within the menu horizontally (with a tiny bit of horizontal forgiveness)
    final dx = globalPos.dx;
    if (dx < _menuLeft - 20 || dx > _menuLeft + widget.menuWidth + 20) {
      return -1;
    }

    // 2. Check if Y intersects a specific item.
    // The menu container has 8px padding top and bottom (assumed from DragMenuOverlay).
    final localY = globalPos.dy - _menuTop - 8;

    // If we are above the first item or below the last item
    if (localY < 0) return -1;

    final index = (localY / widget.itemHeight).floor();
    if (index >= 0 && index < widget.items.length) {
      return index;
    }

    return -1;
  }

  void _handleLongPressEnd(LongPressEndDetails details) {
    if (_hoveredIndex >= 0 && _hoveredIndex < widget.items.length) {
      // User dragged over an item and released. Execute it.
      widget.items[_hoveredIndex].onSelected();
      _removeOverlay();
      
      // Delay reset so the highlight doesn't disappear during the out-animation
      Future.delayed(const Duration(milliseconds: 150), () {
        if (mounted) _reset();
      });
    } else {
      // Didn't select anything via dragging, or just lifted finger. Lock it open!
      _isLockedOpen = true;
      _hoveredIndex = -1; // Clear highlight so it looks neutral
      _markNeedsBuild();
    }
  }

  void _handleLongPressCancel() {
    _removeOverlay();
    _reset();
  }

  void _reset() {
    _hoveredIndex = -1;
    _isLockedOpen = false;
    _pressGlobalPosition = null;
    _childRect = null;
    _spawnUpward = false;
    _menuLeft = 0;
    _menuTop = 0;
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onLongPressStart: _handleLongPressStart,
      onLongPressMoveUpdate: _handleLongPressMoveUpdate,
      onLongPressEnd: _handleLongPressEnd,
      onLongPressCancel: _handleLongPressCancel,
      child: Opacity(
        opacity: _overlayEntry != null ? 0.0 : 1.0,
        child: widget.child,
      ),
    );
  }
}
