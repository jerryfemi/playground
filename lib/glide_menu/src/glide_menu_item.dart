import 'package:flutter/widgets.dart';

/// Clean public model for consumers of the package.
class GlideMenuItem<T> {
  const GlideMenuItem({
    required this.value,
    this.label = '',
    this.icon,
    this.child,
    this.isDestructive = false,
  });

  /// The value returned when this item is selected.
  final T value;

  /// The text displayed for this menu item.
  final String label;

  /// An optional leading icon to display next to the text.
  final Widget? icon;

  /// A custom widget that completely overrides [label] and [icon].
  final Widget? child;

  /// If true, applies a red destructive style to the text and highlight.
  final bool isDestructive;
}
