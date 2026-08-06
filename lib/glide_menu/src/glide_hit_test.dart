import 'package:flutter/material.dart';

/// Shared hit-test logic for GlideMenu.
///
/// Converts a position (either global or local) into a menu item index.
/// Returns -1 if the position is outside the menu bounds.
///
/// This class centralizes all the magic numbers (padding, divider height,
/// horizontal forgiveness) so that [GlideMenu] and [GlideMenuOverlay]
/// always agree on item boundaries.
class GlideHitTest {
  const GlideHitTest._();

  /// The vertical padding inside the menu container (top and bottom).
  static const double menuPaddingVertical = 8.0;

  /// The total height consumed by the divider between items and footer
  /// (Divider widget height: 17px).
  static const double dividerHeight = 17.0;

  /// The horizontal tolerance outside the menu bounds that still
  /// counts as a valid hover (forgiving for fat fingers).
  static const double horizontalForgiveness = 20.0;

  /// Calculates total menu height including padding, items, and optional footer.
  static double menuHeight({
    required int itemCount,
    required double itemHeight,
    required bool hasFooter,
  }) {
    double h = itemCount * itemHeight + (menuPaddingVertical * 2);
    if (hasFooter) {
      h += itemHeight + dividerHeight;
    }
    return h;
  }

  /// Returns the hovered item index from a global screen position.
  ///
  /// Used by [GlideMenu] during the initial long-press drag phase,
  /// where the finger position is in global screen coordinates.
  static int indexFromGlobal({
    required Offset globalPosition,
    required double menuLeft,
    required double menuTop,
    required double menuWidth,
    required double itemHeight,
    required int itemCount,
    required bool hasFooter,
  }) {
    // 1. Check if X is within the menu horizontally (with forgiveness)
    final dx = globalPosition.dx;
    if (dx < menuLeft - horizontalForgiveness ||
        dx > menuLeft + menuWidth + horizontalForgiveness) {
      return -1;
    }

    // 2. Convert global Y to local Y (relative to the first item)
    final localY = globalPosition.dy - menuTop - menuPaddingVertical;

    return _indexFromLocalY(
      localY: localY,
      itemHeight: itemHeight,
      itemCount: itemCount,
      hasFooter: hasFooter,
    );
  }

  /// Returns the hovered item index from a local position within the overlay.
  ///
  /// Used by [GlideMenuOverlay] during the locked-open re-drag phase,
  /// where the position is local to the overlay widget.
  static int indexFromLocal({
    required Offset localPosition,
    required double menuWidth,
    required double paddingTop,
    required double itemHeight,
    required int itemCount,
    required bool hasFooter,
  }) {
    final dy = localPosition.dy - paddingTop;

    if (dy < 0 || localPosition.dx < 0 || localPosition.dx > menuWidth) {
      return -1;
    }

    return _indexFromLocalY(
      localY: dy,
      itemHeight: itemHeight,
      itemCount: itemCount,
      hasFooter: hasFooter,
    );
  }

  /// Core shared logic: convert a local Y offset (relative to the first item)
  /// into an item index.
  static int _indexFromLocalY({
    required double localY,
    required double itemHeight,
    required int itemCount,
    required bool hasFooter,
  }) {
    if (localY < 0) return -1;

    // Check if the finger is in the footer zone
    if (hasFooter && localY > (itemCount * itemHeight)) {
      // Must be past the divider to count as hovering the footer
      if (localY > (itemCount * itemHeight) + dividerHeight) {
        return itemCount; // footer index
      }
      return -1; // In the divider gap — no selection
    }

    final index = (localY / itemHeight).floor();
    if (index >= 0 && index < itemCount) {
      return index;
    }

    return -1;
  }

  /// Clamps [value] between [min] and [max], gracefully handling
  /// the case where max < min (e.g. menu wider than screen).
  static double safeClamp(double value, double min, double max) {
    if (max < min) return min; // Menu doesn't fit; pin to the edge
    return value.clamp(min, max);
  }

  /// Calculates the best X/Y position for the menu, accounting for screen bounds,
  /// safe areas, keyboard, and preferred alignment.
  static MenuPosition calculateMenuPosition({
    required Size screenSize,
    required EdgeInsets safePadding,
    required double keyboardHeight,
    required Rect? childRect,
    required Offset pressGlobalPosition,
    required double menuWidth,
    required double menuHeight,
    required double margin,
    required double anchorGap,
  }) {
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;

    final safeBottom = safePadding.bottom + keyboardHeight;
    final safeLeft = safePadding.left;
    final safeRight = safePadding.right;

    final childBottom = childRect?.bottom ?? pressGlobalPosition.dy;

    double menuLeft = 0;
    if (childRect != null) {
      // If widget is mostly on the right side of the screen, right-align the menu
      if (childRect.center.dx > screenWidth / 2) {
        menuLeft = safeClamp(
          childRect.right - menuWidth,
          margin + safeLeft,
          screenWidth - menuWidth - margin - safeRight,
        );
      } else {
        // Otherwise left-align
        menuLeft = safeClamp(
          childRect.left,
          margin + safeLeft,
          screenWidth - menuWidth - margin - safeRight,
        );
      }
    } else {
      menuLeft = safeClamp(
        pressGlobalPosition.dx + 12,
        margin + safeLeft,
        screenWidth - menuWidth - margin - safeRight,
      );
    }

    // Always attempt to spawn below the child first.
    double menuTop = childBottom + anchorGap;

    // Calculate how much the menu overflows the bottom of the screen.
    final maxAllowedBottom = screenHeight - margin - safeBottom;
    final actualBottom = menuTop + menuHeight;

    double pushUpAmount = 0.0;
    double scrollHeight = screenHeight;

    if (actualBottom > maxAllowedBottom) {
      double requiredShift = actualBottom - maxAllowedBottom;

      // Calculate how high we can push the child before it hits the top safe area
      double childTop = childRect?.top ?? pressGlobalPosition.dy;
      double maxPushUp = childTop - safePadding.top - margin;

      if (maxPushUp < 0) maxPushUp = 0; // Don't push down

      pushUpAmount = requiredShift > maxPushUp ? maxPushUp : requiredShift;

      if (requiredShift > pushUpAmount) {
        // The menu still overflows after maximum push up, expand the scroll canvas!
        scrollHeight = screenHeight + (requiredShift - pushUpAmount);
      }
    }

    return MenuPosition(
      left: menuLeft,
      top: menuTop,
      pushUpAmount: pushUpAmount,
      scrollHeight: scrollHeight,
    );
  }
}

/// Holds calculated position coordinates and animation direction.
class MenuPosition {
  final double left;
  final double top;
  final double pushUpAmount;
  final double scrollHeight;

  const MenuPosition({
    required this.left,
    required this.top,
    required this.pushUpAmount,
    required this.scrollHeight,
  });
}
