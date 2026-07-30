# GlideMenu

<div align="center">
  <img width="240" height="426" alt="GlideMenu Demo" src="https://github.com/user-attachments/assets/79bc6ded-017b-4d31-9ba3-4631d6b75aa9" />
</div>

A fluid, continuous drag-to-select context menu and spring button package for Flutter. 


`GlideMenu` provides a highly premium, iOS-style scrubbable action menu. Users can long-press to open the menu, continuously drag their finger to scrub through options with haptic feedback, and release to select an action—all in one seamless gesture.

## Features

- **Continuous Drag Selection**: Keep your finger on the screen to scrub through items.
- **Spring Animations**: Powered by [Motor](https://pub.dev/packages/motor) for incredibly smooth, physics-based spring interactions.
- **`GlideMenu.button()` Mode**: A dedicated tap-to-open dropdown constructor. Ideal for `⋮` more icons and toolbar actions. It opens instantly, skips the child lift effect, and floats on top of the UI without dimming the background.
- **Programmatic Control**: Pass a `GlideMenuController` to open, close, and check the state of the menu from anywhere in the widget tree (great for keyboard shortcuts or custom buttons).
- **Hybrid Scrolling**: Automatically handles menus that exceed the screen boundaries. Short menus snap open; massive menus gracefully fall back to a scrollable list, exactly like native OS menus..
- **Destructive Actions**: Built-in support for a pinned `footer` with dangerous actions (like Delete) separated by a native divider.
- **Fully Customizable**: Override default text/icons with a custom `child` widget. 
- **Theme Integration**: Automatically inherits your app's `Theme.of(context).colorScheme` for seamless Light/Dark mode support.
- **SpringButton included**: A standalone bouncy, spring-animated button that scales down when pressed.

## Acknowledgements

This package heavily relies on the amazing [motor](https://pub.dev/packages/motor) package.

## Installation

Since this package is currently hosted inside a larger repository, you can install it directly from GitHub by adding this to your `pubspec.yaml`:

```yaml
dependencies:
  glide_menu:
    git:
      url: https://github.com/jerryfemi/playground.git
      path: lib/glide_menu
```

Then, import it wherever you need it:
```dart
import 'package:glide_menu/glide_menu.dart';
```

## Usage

### 1. Classic Long-Press Context Menu (Telegram Style)

Wrap any widget in a `GlideMenu` to give it a drag-to-select context menu.

```dart
import 'package:playground/glide_menu/glide_menu.dart';

GlideMenu<String>(
  items: const [
    GlideMenuItem(
      value: 'reply',
      label: 'Reply',
      icon: Icon(Icons.reply_rounded),
    ),
    GlideMenuItem(
      value: 'copy',
      label: 'Copy',
      icon: Icon(Icons.copy_rounded),
    ),
  ],
  footer: const GlideMenuItem(
    value: 'delete',
    label: 'Delete',
    icon: Icon(Icons.delete_outline, color: Colors.red),
    isDestructive: true,
  ),
  onSelected: (value) {
    print('User selected: $value');
  },
  child: Container(
    padding: const EdgeInsets.all(16),
    color: Colors.blueAccent,
    child: const Text('Long press me!'),
  ),
)
```

### 2. Tap-to-Open Dropdown Button

For standard dropdown menus like an app bar `⋮` icon, use the `.button()` constructor. This skips the long-press squish animation and background dimming.

```dart
GlideMenu<String>.button(
  items: const [
    GlideMenuItem(value: 'settings', label: 'Settings', icon: Icon(Icons.settings)),
  ],
  onSelected: (value) => print('Selected: $value'),
  child: const IconButton(
    icon: Icon(Icons.more_vert),
    onPressed: null, // Let GlideMenu handle the tap
  ),
)
```

### 3. Programmatic Controller

Use a `GlideMenuController` to trigger the menu from external buttons or events.

```dart
final controller = GlideMenuController();

// Wrap your target
GlideMenu<String>(
  controller: controller,
  items: const [
    GlideMenuItem(value: 'action', label: 'Action', icon: Icon(Icons.api)),
  ],
  child: const CircleAvatar(child: Text('JD')),
)

// Trigger it from anywhere
ElevatedButton(
  onTap: () => controller.open(),
  child: const Text('Open Menu remotely!'),
)
```

### 2. SpringButton

A standalone, bouncy button that scales down on press with configurable friction.

```dart
import 'package:playground/glide_menu/glide_menu.dart';

SpringButton(
  onTap: () => print('Bounced!'),
  dragFriction: 19.0, // Higher value means less drag distance
  child: Container(
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    decoration: BoxDecoration(
      color: Colors.black,
      borderRadius: BorderRadius.circular(12),
    ),
    child: const Text('Tap Me', style: TextStyle(color: Colors.white)),
  ),
)
```
