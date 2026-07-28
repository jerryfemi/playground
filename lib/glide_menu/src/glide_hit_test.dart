import 'dart:ui';

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
}
