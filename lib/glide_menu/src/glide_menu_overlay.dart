import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:motor/motor.dart';

import 'glide_menu_item.dart';
import 'glide_hit_test.dart';

/// Pure overlay UI for the drag menu.
///
/// Important:
/// - [IgnorePointer] is used so the overlay does not steal the gesture.
/// - The original [GestureDetector] continues receiving long-press updates.
class GlideMenuOverlay<T> extends StatefulWidget {
  const GlideMenuOverlay({
    super.key,
    required this.pressGlobalPosition,
    required this.margin,
    required this.anchorGap,
    required this.width,
    required this.itemHeight,
    required this.items,
    this.footer,
    required this.highlightedIndex,
    required this.isLockedOpen,
    required this.isClosing,
    required this.onSelected,
    required this.onClose,
    this.childReplica,
    this.childRect,
    this.backgroundColor,
    this.highlightColor,
    this.borderRadius = 18,
    this.itemBorderRadius = 12,
    this.shadow,
    this.padding = const EdgeInsets.all(8),
    this.textStyle,
  });

  final Offset pressGlobalPosition;
  final double margin;
  final double anchorGap;
  final double width;
  final double itemHeight;
  final List<GlideMenuItem<T>> items;
  final GlideMenuItem<T>? footer;
  final int highlightedIndex;
  final bool isLockedOpen;
  final bool isClosing;
  final ValueChanged<T> onSelected;
  final VoidCallback onClose;
  final Widget? childReplica;
  final Rect? childRect;

  final Color? backgroundColor;
  final Color? highlightColor;
  final double borderRadius;
  final double itemBorderRadius;
  final List<BoxShadow>? shadow;
  final EdgeInsets padding;
  final TextStyle? textStyle;

  @override
  State<GlideMenuOverlay<T>> createState() => _GlideMenuOverlayState<T>();
}

class _GlideMenuOverlayState<T> extends State<GlideMenuOverlay<T>> {
  double _scale = 0.7;
  double _opacity = 0.0;
  double _animationValue = 0.0;
  int _localHoveredIndex = -1;
  ScrollController? _scrollController;

  @override
  void dispose() {
    _scrollController?.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Trigger entrance animation on mount
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _scale = 1.0;
          _opacity = 1.0;
          _animationValue = 1.0;
        });
      }
    });
  }

  @override
  void didUpdateWidget(GlideMenuOverlay<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isClosing && !oldWidget.isClosing) {
      // Trigger reverse animation
      setState(() {
        _scale = 0.7;
        _opacity = 0.0;
        _animationValue = 0.0;
      });
    }
  }

  void _updateLocalHover(Offset localPosition) {
    final newIndex = GlideHitTest.indexFromLocal(
      localPosition: localPosition,
      menuWidth: widget.width,
      paddingTop: widget.padding.top,
      itemHeight: widget.itemHeight,
      itemCount: widget.items.length,
      hasFooter: widget.footer != null,
    );

    if (newIndex != _localHoveredIndex) {
      setState(() => _localHoveredIndex = newIndex);
      if (newIndex != -1) {
        HapticFeedback.selectionClick();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final resolvedBackgroundColor =
        widget.backgroundColor ?? Theme.of(context).colorScheme.surface;

    final activeHoverIndex =
        widget.isLockedOpen ? _localHoveredIndex : widget.highlightedIndex;

    return LayoutBuilder(
      builder: (context, constraints) {
        final media = MediaQuery.of(context);

        final menuHeight = GlideHitTest.menuHeight(
          itemCount: widget.items.length,
          itemHeight: widget.itemHeight,
          hasFooter: widget.footer != null,
        );

        final position = GlideHitTest.calculateMenuPosition(
          screenSize: media.size,
          safePadding: media.padding,
          keyboardHeight: media.viewInsets.bottom,
          childRect: widget.childRect,
          pressGlobalPosition: widget.pressGlobalPosition,
          menuWidth: widget.width,
          menuHeight: menuHeight,
          margin: widget.margin,
          anchorGap: widget.anchorGap,
        );

        _scrollController ??=
            ScrollController(initialScrollOffset: position.pushUpAmount);

        return Stack(
          children: [
            // Fixed Dimmed background (not hit testable)
            Positioned.fill(
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 150),
                opacity: _opacity,
                child: Container(color: Colors.black26),
              ),
            ),

            // Scrolling content canvas
            Positioned.fill(
              child: IgnorePointer(
                ignoring: !widget.isLockedOpen,
                child: SingleChildScrollView(
                  controller: _scrollController,
                  physics: const ClampingScrollPhysics(),
                  child: SizedBox(
                    height: position.scrollHeight + position.pushUpAmount,
                    child: SingleMotionBuilder(
                      motion: const CupertinoMotion.bouncy(extraBounce: 0.1),
                      value: _animationValue,
                      builder: (context, val, child) {
                        // Animate from visually unshifted (shiftAmount) to shifted (0)
                        final translateY = position.pushUpAmount * (1.0 - val);
                        return Transform.translate(
                          offset: Offset(0, translateY),
                          child: child,
                        );
                      },
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          // Hit testable background for scrolling AND tap-to-close
                          Positioned.fill(
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap:
                                  widget.isLockedOpen ? widget.onClose : null,
                              child: const SizedBox.expand(),
                            ),
                          ),

                          // Child Replica (Lifting effect)
                          if (widget.childReplica != null &&
                              widget.childRect != null)
                            Positioned(
                              left: widget.childRect!.left,
                              top: widget.childRect!.top,
                              width: widget.childRect!.width,
                              height: widget.childRect!.height,
                              child: SingleMotionBuilder(
                                motion: const CupertinoMotion.bouncy(
                                    extraBounce: 0.1),
                                value: _animationValue == 1.0 ? 1.05 : 0.95,
                                builder: (context, scale, child) {
                                  return Transform.scale(
                                    scale: scale,
                                    alignment: Alignment.center,
                                    child: child,
                                  );
                                },
                                child: Material(
                                  type: MaterialType.transparency,
                                  child: widget.childReplica!,
                                ),
                              ),
                            ),

                          // The Menu
                          Positioned(
                            left: position.left,
                            top: position.top,
                            width: widget.width,
                            child: GestureDetector(
                              onPanDown: (details) =>
                                  _updateLocalHover(details.localPosition),
                              onPanUpdate: (details) =>
                                  _updateLocalHover(details.localPosition),
                              onPanEnd: (details) {
                                final totalItems = widget.items.length +
                                    (widget.footer != null ? 1 : 0);
                                if (_localHoveredIndex >= 0 &&
                                    _localHoveredIndex < totalItems) {
                                  if (_localHoveredIndex ==
                                          widget.items.length &&
                                      widget.footer != null) {
                                    widget.onSelected(widget.footer!.value);
                                  } else {
                                    widget.onSelected(
                                        widget.items[_localHoveredIndex].value);
                                  }
                                  widget.onClose();
                                } else {
                                  setState(() => _localHoveredIndex = -1);
                                }
                              },
                              onPanCancel: () =>
                                  setState(() => _localHoveredIndex = -1),
                              child: SingleMotionBuilder(
                                motion: const CupertinoMotion.bouncy(
                                    extraBounce: 0.1),
                                value: _scale,
                                builder: (context, scale, child) {
                                  return Transform.scale(
                                    scale: scale,
                                    alignment: Alignment.topCenter,
                                    child: AnimatedOpacity(
                                      opacity: _opacity,
                                      duration:
                                          const Duration(milliseconds: 150),
                                      child: child,
                                    ),
                                  );
                                },
                                child: Material(
                                  color: Colors.transparent,
                                  child: Container(
                                    padding: widget.padding,
                                    decoration: BoxDecoration(
                                      color: resolvedBackgroundColor,
                                      borderRadius: BorderRadius.circular(
                                          widget.borderRadius),
                                      boxShadow: widget.shadow ??
                                          const [
                                            BoxShadow(
                                              color: Color(0x22000000),
                                              blurRadius: 18,
                                              offset: Offset(0, 8),
                                            ),
                                          ],
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        ...List.generate(widget.items.length,
                                            (index) {
                                          final item = widget.items[index];
                                          final selected =
                                              index == activeHoverIndex;
                                          return _buildMenuItem(item, selected);
                                        }),
                                        if (widget.footer != null) ...[
                                          const Divider(
                                              height: 17,
                                              indent: 6,
                                              endIndent: 6),
                                          _buildMenuItem(
                                            widget.footer!,
                                            activeHoverIndex ==
                                                widget.items.length,
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ], // Ends inner Stack children
                      ), // Ends inner Stack
                    ), // Ends SingleMotionBuilder
                  ), // Ends SizedBox
                ), // Ends SingleChildScrollView
              ), // Ends IgnorePointer
            ), // Ends Positioned.fill
          ], // Ends outer Stack children
        ); // Ends outer Stack
      }, // Ends LayoutBuilder builder
    ); // Ends LayoutBuilder
  }

  Widget _buildMenuItem(GlideMenuItem<T> item, bool selected) {
    final effectiveTextStyle =
        widget.textStyle ?? Theme.of(context).textTheme.bodyMedium;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final color = item.isDestructive
        ? Colors.redAccent
        : (selected ? primaryColor : effectiveTextStyle?.color);
    final resolvedHighlightColor = widget.highlightColor ??
        Theme.of(context).colorScheme.primary.withValues(alpha: 0.08);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 70),
      curve: Curves.easeOut,
      height: widget.itemHeight,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: selected
            ? (item.isDestructive
                ? Colors.redAccent.withValues(alpha: 0.1)
                : resolvedHighlightColor)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(widget.itemBorderRadius),
      ),
      child: item.child ??
          Row(
            children: [
              if (item.icon != null) ...[
                IconTheme(
                  data: IconThemeData(size: 20, color: color),
                  child: item.icon!,
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: effectiveTextStyle?.copyWith(
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
    );
  }
}
