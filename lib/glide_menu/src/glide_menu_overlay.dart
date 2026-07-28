import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:motor/motor.dart';

import 'glide_menu_item.dart';

/// Pure overlay UI for the drag menu.
///
/// Important:
/// - [IgnorePointer] is used so the overlay does not steal the gesture.
/// - The original [GestureDetector] continues receiving long-press updates.
class GlideMenuOverlay<T> extends StatefulWidget {
  const GlideMenuOverlay({
    super.key,
    required this.left,
    required this.top,
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

  final double left;
  final double top;
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
  double _scale = 0.8;
  double _opacity = 0.0;
  int _localHoveredIndex = -1;

  @override
  void initState() {
    super.initState();
    // Trigger entrance animation on mount
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _scale = 1.0;
          _opacity = 1.0;
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
        _scale = 0.8;
        _opacity = 0.0;
      });
    }
  }

  void _updateLocalHover(Offset localPosition) {
    final dy = localPosition.dy - widget.padding.top;
    int newIndex = -1;

    // We account for the divider height (1px + 16px padding = 17px) when calculating footer intersection
    if (dy >= 0 && localPosition.dx >= 0 && localPosition.dx <= widget.width) {
      if (widget.footer != null &&
          dy > (widget.items.length * widget.itemHeight)) {
        if (dy > (widget.items.length * widget.itemHeight) + 17) {
          newIndex = widget.items.length;
        }
      } else {
        newIndex = (dy / widget.itemHeight).floor();
        if (newIndex >= widget.items.length) {
          newIndex = -1;
        }
      }
    }

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

    return Stack(
      children: [
        // Dimmed background
        Positioned.fill(
          child: GestureDetector(
            onTap: widget.isLockedOpen ? widget.onClose : null,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 150),
              opacity: _opacity,
              child: Container(color: Colors.black26),
            ),
          ),
        ),

        // Child Replica (Lifting effect)
        if (widget.childReplica != null && widget.childRect != null)
          Positioned(
            left: widget.childRect!.left,
            top: widget.childRect!.top,
            width: widget.childRect!.width,
            height: widget.childRect!.height,
            child: SingleMotionBuilder(
              motion: const CupertinoMotion.bouncy(extraBounce: 0.3),
              value: _scale > 0.8 ? 1.05 : 1.0, // Scale up slightly to "lift"
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
          left: widget.left,
          top: widget.top,
          width: widget.width,
          child: IgnorePointer(
            ignoring: !widget.isLockedOpen,
            child: GestureDetector(
              onPanDown: (details) => _updateLocalHover(details.localPosition),
              onPanUpdate: (details) =>
                  _updateLocalHover(details.localPosition),
              onPanEnd: (details) {
                final totalItems =
                    widget.items.length + (widget.footer != null ? 1 : 0);
                if (_localHoveredIndex >= 0 &&
                    _localHoveredIndex < totalItems) {
                  if (_localHoveredIndex == widget.items.length &&
                      widget.footer != null) {
                    widget.onSelected(widget.footer!.value);
                  } else {
                    widget.onSelected(widget.items[_localHoveredIndex].value);
                  }
                  widget.onClose();
                } else {
                  setState(() => _localHoveredIndex = -1);
                }
              },
              onPanCancel: () => setState(() => _localHoveredIndex = -1),
              child: SingleMotionBuilder(
                motion: const CupertinoMotion.bouncy(extraBounce: 0.3),
                value: _scale,
                builder: (context, scale, child) {
                  // If the menu is rendered ABOVE the child, it should spring up from its bottom.
                  // If the menu is rendered BELOW the child, it should spring down from its top.
                  final bool isAboveChild =
                      widget.top < (widget.childRect?.top ?? 0);

                  return Transform.scale(
                    scale: scale,
                    alignment: isAboveChild
                        ? Alignment.bottomCenter
                        : Alignment.topCenter,
                    child: AnimatedOpacity(
                      opacity: _opacity,
                      duration: const Duration(milliseconds: 150),
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
                      borderRadius: BorderRadius.circular(widget.borderRadius),
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
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ...List.generate(widget.items.length, (index) {
                          final item = widget.items[index];
                          final selected = index == activeHoverIndex;
                          return _buildMenuItem(item, selected);
                        }),
                        if (widget.footer != null) ...[
                          const Divider(height: 17, indent: 6, endIndent: 6),
                          _buildMenuItem(
                            widget.footer!,
                            activeHoverIndex == widget.items.length,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
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

    return GestureDetector(
      onTap: widget.isLockedOpen
          ? () {
              widget.onSelected(item.value);
              widget.onClose();
            }
          : null,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
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
      ),
    );
  }
}
