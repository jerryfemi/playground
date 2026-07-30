import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'glide_menu_overlay.dart';
import 'glide_menu_item.dart';
import 'glide_hit_test.dart';

export 'glide_menu_overlay.dart';
export 'glide_menu_item.dart';
export 'glide_hit_test.dart';

/// Controller for programmatically opening and closing a [GlideMenu].
///
/// Works with both [GlideMenu] (long-press mode) and [GlideMenu.button]
/// (tap mode). When [open] is called, the menu behaves as if the user
/// triggered it via the configured gesture.
class GlideMenuController {
  _GlideMenuState? _state;

  /// Whether the menu is currently visible.
  bool get isOpen => _state?._overlayEntry != null;

  /// Opens the menu programmatically.
  void open() => _state?._openFromController();

  /// Closes the menu programmatically.
  void close() {
    _state?._removeOverlay(
      onClosed: () => _state?._reset(),
    );
  }

  void _attach(_GlideMenuState state) => _state = state;
  void _detach() => _state = null;
}

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
  /// Creates a long-press context menu with child replica lift and scrub-to-select.
  ///
  /// This is the signature Telegram-style interaction: the user long-presses
  /// the [child], it lifts onto the overlay, and they scrub to select an item.
  const GlideMenu({
    super.key,
    required this.child,
    required this.items,
    required this.onSelected,
    this.footer,
    this.itemHeight = 35,
    this.menuWidth = 180,
    this.margin = 12,
    this.anchorGap = 8,
    this.highlightColor,
    this.backgroundColor,
    this.textStyle,
    this.borderRadius = 24,
    this.itemBorderRadius = 24,
    this.enableHaptics = true,
    this.controller,
  })  : _isButtonMode = false,
        assert(items.length > 0 || footer != null,
            'GlideMenu requires at least one item or a footer.');

  /// Creates a tap-to-open dropdown menu without child replica or scrub phase.
  ///
  /// The [child] stays in place, and the menu opens immediately in locked mode
  /// (tap-to-select, scrollable). Ideal for icon buttons, action icons, or any
  /// widget where a single tap should reveal a menu.
  const GlideMenu.button({
    super.key,
    required this.child,
    required this.items,
    required this.onSelected,
    this.footer,
    this.itemHeight = 35,
    this.menuWidth = 180,
    this.margin = 12,
    this.anchorGap = 8,
    this.highlightColor,
    this.backgroundColor,
    this.textStyle,
    this.borderRadius = 24,
    this.itemBorderRadius = 24,
    this.enableHaptics = true,
    this.controller,
  })  : _isButtonMode = true,
        assert(items.length > 0 || footer != null,
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

  /// Optional controller for programmatic open/close.
  final GlideMenuController? controller;

  /// Whether this menu was created via [GlideMenu.button].
  final bool _isButtonMode;

  @override
  State<GlideMenu<T>> createState() => _GlideMenuState<T>();
}

class _GlideMenuState<T> extends State<GlideMenu<T>> {
  /// Global lock: only one GlideMenu can be open at a time across the entire app.
  static _GlideMenuState? _openMenuState;

  bool get _ownsLock => _openMenuState == this;

  OverlayEntry? _overlayEntry;

  Rect? _childRect;
  Offset _pressGlobalPosition = Offset.zero;

  bool _isLockedOpen = false;
  bool _isClosing = false;
  bool _isPressedDown = false;
  bool _showChildReplica = true;
  int _hoveredIndex = -1;

  MenuPosition? _initialPosition;

  Timer? _closeTimer;

  @override
  void initState() {
    super.initState();
    widget.controller?._attach(this);
  }

  @override
  void didUpdateWidget(GlideMenu<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      oldWidget.controller?._detach();
      widget.controller?._attach(this);
    }
  }

  @override
  void dispose() {
    widget.controller?._detach();
    _closeTimer?.cancel();
    // During dispose, skip the exit animation (nobody sees it)
    // and remove the overlay synchronously.
    _overlayEntry?.remove();
    _overlayEntry = null;

    // Release the global lock if we own it
    if (_ownsLock) {
      _openMenuState = null;
    }

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

  void _showOverlay({bool showChildReplica = true}) {
    _showChildReplica = showChildReplica;
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
          showChildReplica: _showChildReplica,
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
    _openMenuState = this;
    setState(() {}); // Trigger rebuild to update child visibility
  }

  void _handleLongPressStart(LongPressStartDetails details) {
    if (!mounted || widget.items.isEmpty) return;
    if (_openMenuState != null) return; // Another menu is already open

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
      menuTop: _initialPosition!.top - _initialPosition!.pushUpAmount,
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
    _showChildReplica = true;

    if (_ownsLock) {
      _openMenuState = null;
    }

    _pressGlobalPosition = Offset.zero;
    _childRect = null;
    _initialPosition = null;
    if (mounted) setState(() {});
  }

  /// Opens the menu in button mode (tap-to-open, no child replica).
  void _openAsButton() {
    if (_overlayEntry != null) return; // Already open
    if (!mounted) return;
    if (_openMenuState != null) return; // Another menu is already open

    // Capture child rect for positioning
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.hasSize) return;

    final size = renderBox.size;
    final position = renderBox.localToGlobal(Offset.zero);
    _childRect = position & size;

    // Use center of child as the press position for positioning math
    _pressGlobalPosition = _childRect?.center ?? Offset.zero;
    _hoveredIndex = -1;
    _isLockedOpen = true; // Skip scrub phase — go straight to locked

    _showOverlay(showChildReplica: false);
    _markNeedsBuild();

    if (widget.enableHaptics) {
      HapticFeedback.mediumImpact();
    }
  }

  /// Opens the menu from the controller.
  void _openFromController() {
    if (_overlayEntry != null) return;
    if (!mounted) return;
    if (_openMenuState != null) return; // Another menu is already open

    if (widget._isButtonMode) {
      _openAsButton();
    } else {
      // For long-press variant opened via controller,
      // open in locked mode WITH child replica
      final renderBox = context.findRenderObject() as RenderBox?;
      if (renderBox == null || !renderBox.hasSize) return;

      final size = renderBox.size;
      final position = renderBox.localToGlobal(Offset.zero);
      _childRect = position & size;

      _pressGlobalPosition = _childRect?.center ?? Offset.zero;
      _hoveredIndex = -1;
      _isLockedOpen = true;

      _showOverlay(showChildReplica: true);
      _markNeedsBuild();

      if (widget.enableHaptics) {
        HapticFeedback.mediumImpact();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Button mode: simple tap, no press animation, child stays visible
    if (widget._isButtonMode) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _openAsButton,
        child: widget.child,
      );
    }

    // Long-press mode: press-down animation, child hides when overlay is up
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
          opacity: (_overlayEntry != null && _showChildReplica) ? 0.0 : 1.0,
          child: widget.child,
        ),
      ),
    );
  }
}
