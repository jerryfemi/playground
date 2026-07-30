import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'glide_menu_overlay.dart';
import 'glide_menu_item.dart';
import 'glide_hit_test.dart';

export 'glide_menu_overlay.dart';
export 'glide_menu_item.dart';
export 'glide_hit_test.dart';

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
class GlideMenu<T> extends StatefulWidget {
  const GlideMenu({
    super.key,
    required this.child,
    required this.items,
    required this.onSelected,
    this.footer,
    this.itemHeight = 35,
    this.menuWidth = 180,
    this.margin = 12,
    this.deadZone = 10,
    this.anchorGap = 8,
    this.highlightColor,
    this.backgroundColor,
    this.textStyle,
    this.borderRadius = 24,
    this.itemBorderRadius = 24,
    this.enableHaptics = true,
    this.initialIndex = 0,
  }) : assert(items.length > 0 || footer != null,
            'GlideMenu requires at least one item or a footer.');

  /// The widget that the user long-presses to open the menu.
  final Widget child;

  /// The list of items to display in the menu.
  final List<GlideMenuItem<T>> items;

  /// Called when the user releases their finger over a menu item.
  final ValueChanged<T> onSelected;

  /// Optional destructive/final action grouped at the bottom separated by a divider.
  final GlideMenuItem<T>? footer;

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

  /// The background color of the hovered item. Defaults to Theme primary with low opacity.
  final Color? highlightColor;

  /// The background color of the menu. Defaults to Theme surface color.
  final Color? backgroundColor;

  /// The text style for menu items. Defaults to Theme bodyMedium.
  final TextStyle? textStyle;

  /// Corner radius of the entire menu container.
  final double borderRadius;

  /// Corner radius of each individual menu item.
  final double itemBorderRadius;

  /// If true, triggers haptic feedback during interactions.
  final bool enableHaptics;

  /// Initial highlighted item when menu appears.
  final int initialIndex;

  @override
  State<GlideMenu<T>> createState() => _GlideMenuState<T>();
}

class _GlideMenuState<T> extends State<GlideMenu<T>> {
  OverlayEntry? _overlayEntry;

  Rect? _childRect;
  Offset _pressGlobalPosition = Offset.zero;

  bool _isLockedOpen = false;
  bool _isClosing = false;
  bool _isPressedDown = false;
  int _hoveredIndex = -1;

  MenuPosition? _initialPosition;

  Timer? _closeTimer;

  @override
  void dispose() {
    _closeTimer?.cancel();
    // During dispose, skip the exit animation (nobody sees it)
    // and remove the overlay synchronously.
    _overlayEntry?.remove();
    _overlayEntry = null;
    super.dispose();
  }

  void _removeOverlay({VoidCallback? onClosed}) {
    if (_overlayEntry == null || _isClosing) return;

    // Trigger closing animation in the overlay
    _isClosing = true;
    _markNeedsBuild();

    // Wait for the reverse spring animation using a cancellable Timer
    _closeTimer?.cancel();
    _closeTimer = Timer(const Duration(milliseconds: 150), () {
      _overlayEntry?.remove();
      _overlayEntry = null;

      if (mounted) {
        setState(() {
          _isClosing = false;
        }); // Re-show the original child
      }
      onClosed?.call();
    });
  }

  void _markNeedsBuild() {
    _overlayEntry?.markNeedsBuild();
  }

  void _showOverlay() {
    _overlayEntry = OverlayEntry(
      builder: (context) {
        return GlideMenuOverlay<T>(
          pressGlobalPosition: _pressGlobalPosition,
          margin: widget.margin,
          anchorGap: widget.anchorGap,
          textStyle: widget.textStyle,
          width: widget.menuWidth,
          itemHeight: widget.itemHeight,
          items: widget.items,
          footer: widget.footer,
          highlightedIndex: _hoveredIndex,
          backgroundColor: widget.backgroundColor,
          highlightColor: widget.highlightColor,
          borderRadius: widget.borderRadius,
          itemBorderRadius: widget.itemBorderRadius,
          isLockedOpen: _isLockedOpen,
          isClosing: _isClosing,
          childReplica: widget.child,
          childRect: _childRect,
          onSelected: widget.onSelected,
          onClose: () {
            _removeOverlay(
              onClosed: () {
                if (mounted) _reset();
              },
            );
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

    final media = MediaQuery.of(context);

    _initialPosition = GlideHitTest.calculateMenuPosition(
      screenSize: media.size,
      safePadding: media.padding,
      keyboardHeight: media.viewInsets.bottom,
      childRect: _childRect,
      pressGlobalPosition: _pressGlobalPosition,
      menuWidth: widget.menuWidth,
      menuHeight: GlideHitTest.menuHeight(
        itemCount: widget.items.length,
        itemHeight: widget.itemHeight,
        hasFooter: widget.footer != null,
      ),
      margin: widget.margin,
      anchorGap: widget.anchorGap,
    );

    _showOverlay();
    _markNeedsBuild();

    // Haptic feedback when the menu first appears — matches Telegram behaviour.
    if (widget.enableHaptics) {
      HapticFeedback.mediumImpact();
    }
  }

  void _handleLongPressMoveUpdate(LongPressMoveUpdateDetails details) {
    if (_overlayEntry == null) return;
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
    if (_initialPosition == null) return -1;
    return GlideHitTest.indexFromGlobal(
      globalPosition: globalPos,
      menuLeft: _initialPosition!.left,
      menuTop: _initialPosition!.top,
      menuWidth: widget.menuWidth,
      itemHeight: widget.itemHeight,
      itemCount: widget.items.length,
      hasFooter: widget.footer != null,
    );
  }

  void _handleLongPressEnd(LongPressEndDetails details) {
    final totalItems = widget.items.length + (widget.footer != null ? 1 : 0);
    if (_hoveredIndex >= 0 && _hoveredIndex < totalItems) {
      // User dragged over an item and released. Execute it.
      if (_hoveredIndex == widget.items.length && widget.footer != null) {
        widget.onSelected(widget.footer!.value);
      } else {
        widget.onSelected(widget.items[_hoveredIndex].value);
      }
      _removeOverlay(
        onClosed: () {
          if (mounted) _reset();
        },
      );
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
    _pressGlobalPosition = Offset.zero;
    _childRect = null;
    _initialPosition = null;
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _isPressedDown = true),
      onTapUp: (_) => setState(() => _isPressedDown = false),
      onTapCancel: () => setState(() => _isPressedDown = false),
      onLongPressStart: _handleLongPressStart,
      onLongPressMoveUpdate: _handleLongPressMoveUpdate,
      onLongPressEnd: _handleLongPressEnd,
      onLongPressCancel: _handleLongPressCancel,
      child: AnimatedScale(
        scale: _isPressedDown ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        child: Opacity(
          opacity: _overlayEntry != null ? 0.0 : 1.0,
          child: widget.child,
        ),
      ),
    );
  }
}
