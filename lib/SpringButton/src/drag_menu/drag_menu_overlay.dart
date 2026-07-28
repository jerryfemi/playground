import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:motor/motor.dart';

/// Pure overlay UI for the drag menu.
///
/// Important:
/// - [IgnorePointer] is used so the overlay does not steal the gesture.
/// - The original [GestureDetector] continues receiving long-press updates.
class DragMenuOverlay extends StatefulWidget {
  const DragMenuOverlay({
    super.key,
    required this.left,
    required this.top,
    required this.width,
    required this.itemHeight,
    required this.items,
    required this.highlightedIndex,
    required this.isLockedOpen,
    required this.isClosing,
    required this.onClose,
    this.childReplica,
    this.childRect,
    this.backgroundColor = Colors.white,
    this.highlightColor = const Color(0x14007AFF),
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
  final List<DragMenuItem> items;
  final int highlightedIndex;
  final bool isLockedOpen;
  final bool isClosing;
  final VoidCallback onClose;
  final Widget? childReplica;
  final Rect? childRect;

  final Color backgroundColor;
  final Color highlightColor;
  final double borderRadius;
  final double itemBorderRadius;
  final List<BoxShadow>? shadow;
  final EdgeInsets padding;
  final TextStyle? textStyle;

  @override
  State<DragMenuOverlay> createState() => _DragMenuOverlayState();
}

class _DragMenuOverlayState extends State<DragMenuOverlay> {
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
  void didUpdateWidget(DragMenuOverlay oldWidget) {
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
    if (dy >= 0 && localPosition.dx >= 0 && localPosition.dx <= widget.width) {
      newIndex = (dy / widget.itemHeight).floor();
      if (newIndex >= widget.items.length) {
        newIndex = -1;
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
    final effectiveTextStyle =
        widget.textStyle ?? Theme.of(context).textTheme.bodyMedium;

    final activeHoverIndex = widget.isLockedOpen
        ? _localHoveredIndex
        : widget.highlightedIndex;

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
              motion: const CupertinoMotion.snappy(),
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
                if (_localHoveredIndex >= 0 &&
                    _localHoveredIndex < widget.items.length) {
                  widget.items[_localHoveredIndex].onSelected();
                  widget.onClose();
                } else {
                  setState(() => _localHoveredIndex = -1);
                }
              },
              onPanCancel: () => setState(() => _localHoveredIndex = -1),
              child: SingleMotionBuilder(
                motion: const CupertinoMotion.snappy(),
                value: _scale,
                builder: (context, scale, child) {
                  return Transform.scale(
                    scale: scale,
                    alignment: Alignment.center,
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
                      color: widget.backgroundColor,
                      borderRadius: BorderRadius.circular(widget.borderRadius),
                      boxShadow:
                          widget.shadow ??
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
                      children: List.generate(widget.items.length, (index) {
                        final item = widget.items[index];
                        final selected = index == activeHoverIndex;

                        return GestureDetector(
                          onTap: widget.isLockedOpen
                              ? () {
                                  item.onSelected();
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
                                  ? widget.highlightColor
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(
                                widget.itemBorderRadius,
                              ),
                            ),
                            child: Row(
                              children: [
                                if (item.icon != null) ...[
                                  IconTheme(
                                    data: IconThemeData(
                                      size: 20,
                                      color: selected
                                          ? Theme.of(
                                              context,
                                            ).colorScheme.primary
                                          : effectiveTextStyle?.color,
                                    ),
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
                                      fontWeight: selected
                                          ? FontWeight.w600
                                          : FontWeight.w500,
                                      color: selected
                                          ? Theme.of(
                                              context,
                                            ).colorScheme.primary
                                          : effectiveTextStyle.color,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
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
}

/// Clean public model for consumers of the package.
class DragMenuItem {
  const DragMenuItem({
    required this.label,
    required this.onSelected,
    this.icon,
  });

  final String label;
  final VoidCallback onSelected;
  final Widget? icon;
}
