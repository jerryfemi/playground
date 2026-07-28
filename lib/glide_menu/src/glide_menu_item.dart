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

  final T value;
  final String label;
  final Widget? icon;
  final Widget? child;
  final bool isDestructive;
}
