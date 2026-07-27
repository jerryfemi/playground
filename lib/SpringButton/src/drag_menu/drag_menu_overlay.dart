import 'package:flutter/material.dart';

/// Pure overlay UI for the drag menu.
///
/// Important:
/// - [IgnorePointer] is used so the overlay does not steal the gesture.
/// - The original [GestureDetector] continues receiving long-press updates.
class DragMenuOverlay extends StatelessWidget {
  const DragMenuOverlay({
    super.key,
    required this.left,
    required this.top,
    required this.width,
    required this.itemHeight,
    required this.items,
    required this.highlightedIndex,
    this.backgroundColor = Colors.white,
    this.highlightColor = const Color(0x14007AFF),
    this.borderRadius = 18,
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

  final Color backgroundColor;
  final Color highlightColor;
  final double borderRadius;
  final List<BoxShadow>? shadow;
  final EdgeInsets padding;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    final effectiveTextStyle =
        textStyle ?? Theme.of(context).textTheme.bodyMedium;

    return Positioned(
      left: left,
      top: top,
      width: width,
      child: IgnorePointer(
        ignoring: true,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(borderRadius),
              boxShadow:
                  shadow ??
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
              children: List.generate(items.length, (index) {
                final item = items[index];
                final selected = index == highlightedIndex;

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 70),
                  curve: Curves.easeOut,
                  height: itemHeight,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: selected ? highlightColor : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      if (item.icon != null) ...[
                        IconTheme(
                          data: IconThemeData(
                            size: 20,
                            color: selected
                                ? Theme.of(context).colorScheme.primary
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
                                ? Theme.of(context).colorScheme.primary
                                : effectiveTextStyle.color,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ),
      ),
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
