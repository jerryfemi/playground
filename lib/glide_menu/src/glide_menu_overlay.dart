import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:meta/meta.dart';
import 'package:motor/motor.dart';

import 'glide_menu_item.dart';
import 'glide_hit_test.dart';

/// Pure overlay UI for the drag menu.
///
/// Important:
/// - [IgnorePointer] is used so the overlay does not steal the gesture.
/// - The original [GestureDetector] continues receiving long-press updates.
@internal
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
    required this.hoveredIndexNotifier,
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
    this.showChildReplica = true,
  });

  final Offset pressGlobalPosition;
  final double margin;
  final double anchorGap;
  final double width;
  final double itemHeight;
  final List<GlideMenuItem<T>> items;
  final GlideMenuItem<T>? footer;
  final ValueNotifier<int> hoveredIndexNotifier;
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
  final bool showChildReplica;

  @override
  State<GlideMenuOverlay<T>> createState() => _GlideMenuOverlayState<T>();
}

class _GlideMenuOverlayState<T> extends State<GlideMenuOverlay<T>> {
  double _scale = 0.7;
  double _opacity = 0.0;
  double _animationValue = 0.0;
  int _visualHoverIndex = 0;
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

    if (newIndex != widget.hoveredIndexNotifier.value) {
      widget.hoveredIndexNotifier.value = newIndex;
      if (newIndex != -1) {
        HapticFeedback.selectionClick();
      }
    }
  }

  void _handleTapSelection(T value) {
    widget.onSelected(value);
    widget.onClose();
  }

  @override
  Widget build(BuildContext context) {
    final resolvedBackgroundColor =
        widget.backgroundColor ?? Theme.of(context).colorScheme.surface;

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

        // Compute scale origin: where the button's center falls within the menu
        Alignment scaleAlignment;
        if (!widget.showChildReplica && widget.childRect != null) {
          // Button mode: scale from the button's position relative to the menu
          final menuRect = Rect.fromLTWH(
            position.left,
            position.top,
            widget.width,
            menuHeight,
          );
          final dx =
              ((widget.childRect!.center.dx - menuRect.left) / menuRect.width) *
                      2.0 -
                  1.0;
          final dy =
              ((widget.childRect!.center.dy - menuRect.top) / menuRect.height) *
                      2.0 -
                  1.0;
          scaleAlignment = Alignment(
            dx.clamp(-1.0, 1.0),
            dy.clamp(-1.0, 1.0),
          );
        } else {
          // Long-press mode: keep existing top-center origin
          scaleAlignment = Alignment.topCenter;
        }

        return Stack(
          children: [
            // Fixed blurred background (only in long-press mode)
            if (widget.showChildReplica)
              Positioned.fill(
                child: ClipRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(
                      sigmaX: _opacity * 15.0,
                      sigmaY: _opacity * 15.0,
                    ),
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 150),
                      opacity: _opacity,
                      child: Container(
                        color: Colors.black.withValues(alpha: _opacity * 0.3),
                      ),
                    ),
                  ),
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
                        // Only slide for button mode; long-press should scale in place to keep hit-box perfectly synced.
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
                          if (widget.showChildReplica &&
                              widget.childReplica != null &&
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
                                final localHoveredIndex =
                                    widget.hoveredIndexNotifier.value;
                                if (localHoveredIndex >= 0 &&
                                    localHoveredIndex < totalItems) {
                                  if (localHoveredIndex ==
                                          widget.items.length &&
                                      widget.footer != null) {
                                    widget.onSelected(widget.footer!.value);
                                  } else {
                                    widget.onSelected(
                                        widget.items[localHoveredIndex].value);
                                  }
                                  widget.onClose();
                                } else {
                                  widget.hoveredIndexNotifier.value = -1;
                                }
                              },
                              onPanCancel: () =>
                                  widget.hoveredIndexNotifier.value = -1,
                              child: SingleMotionBuilder(
                                motion: const CupertinoMotion.bouncy(
                                    extraBounce: 0.1),
                                value: _scale,
                                builder: (context, scale, child) {
                                  return Transform.scale(
                                    scale: scale,
                                    alignment: scaleAlignment,
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
                                    child: Stack(
                                      children: [
                                        // 1. Sliding Highlight Box
                                        ValueListenableBuilder<int>(
                                          valueListenable:
                                              widget.hoveredIndexNotifier,
                                          builder: (context, activeHoverIndex,
                                              child) {
                                            if (activeHoverIndex != -1) {
                                              _visualHoverIndex =
                                                  activeHoverIndex;
                                            }
                                            final mathIndex =
                                                activeHoverIndex == -1
                                                    ? _visualHoverIndex
                                                    : activeHoverIndex;

                                            return AnimatedPositioned(
                                              duration: const Duration(
                                                  milliseconds: 150),
                                              curve: Curves.fastOutSlowIn,
                                              left: 0,
                                              right: 0,
                                              height: widget.itemHeight,
                                              top: mathIndex ==
                                                      widget.items.length
                                                  ? (mathIndex *
                                                          widget.itemHeight) +
                                                      17
                                                  : (mathIndex *
                                                          widget.itemHeight)
                                                      .clamp(0, double.infinity)
                                                      .toDouble(),
                                              child: AnimatedOpacity(
                                                duration: const Duration(
                                                    milliseconds: 150),
                                                opacity: activeHoverIndex == -1
                                                    ? 0.0
                                                    : 1.0,
                                                child: AnimatedContainer(
                                                  duration: const Duration(
                                                      milliseconds: 150),
                                                  decoration: BoxDecoration(
                                                    color: (activeHoverIndex >=
                                                                    0 &&
                                                                activeHoverIndex <
                                                                    widget.items
                                                                        .length &&
                                                                widget
                                                                    .items[
                                                                        activeHoverIndex]
                                                                    .isDestructive) ||
                                                            (activeHoverIndex ==
                                                                    widget.items
                                                                        .length &&
                                                                widget.footer
                                                                        ?.isDestructive ==
                                                                    true)
                                                        ? Colors.redAccent
                                                            .withValues(
                                                                alpha: 0.1)
                                                        : (widget.highlightColor ??
                                                            Theme.of(context)
                                                                .colorScheme
                                                                .primary
                                                                .withValues(
                                                                    alpha: 0.08)),
                                                    borderRadius: BorderRadius
                                                        .circular(widget
                                                            .itemBorderRadius),
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                        // 2. The Text Items
                                        Column(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.stretch,
                                          children: [
                                            ...List.generate(
                                                widget.items.length, (index) {
                                              final item = widget.items[index];
                                              return GestureDetector(
                                                behavior:
                                                    HitTestBehavior.opaque,
                                                onTapUp: (_) =>
                                                    _handleTapSelection(
                                                        item.value),
                                                child: _buildMenuItem(item),
                                              );
                                            }),
                                            if (widget.footer != null) ...[
                                              const Divider(
                                                  height: 17,
                                                  indent: 6,
                                                  endIndent: 6),
                                              GestureDetector(
                                                behavior:
                                                    HitTestBehavior.opaque,
                                                onTapUp: (_) =>
                                                    _handleTapSelection(
                                                        widget.footer!.value),
                                                child: _buildMenuItem(
                                                    widget.footer!),
                                              ),
                                            ],
                                          ],
                                        ),
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

  Widget _buildMenuItem(GlideMenuItem<T> item) {
    final effectiveTextStyle =
        widget.textStyle ?? Theme.of(context).textTheme.bodyMedium;
    final color =
        item.isDestructive ? Colors.redAccent : effectiveTextStyle?.color;
    return Container(
      height: widget.itemHeight,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      color: Colors.transparent,
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
                    fontWeight: FontWeight.w500,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
    );
  }
}
