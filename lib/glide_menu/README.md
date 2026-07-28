# GlideMenu

A fluid, continuous drag-to-select context menu and spring button package for Flutter. 

`GlideMenu` provides a highly premium, iOS-style scrubbable action menu. Users can long-press to open the menu, continuously drag their finger to scrub through options with haptic feedback, and release to select an action—all in one seamless gesture.

## Features

- **Continuous Drag Selection**: Keep your finger on the screen to scrub through items.
- **Spring Animations**: Powered by [Motor](https://pub.dev/packages/motor) for incredibly smooth, physics-based spring interactions.
- **Destructive Actions**: Built-in support for a pinned `footer` with dangerous actions (like Delete) separated by a native divider.
- **Fully Customizable**: Override default text/icons with a custom `child` widget. 
- **Theme Integration**: Automatically inherits your app's `Theme.of(context).colorScheme` for seamless Light/Dark mode support.
- **SpringButton included**: A standalone bouncy, spring-animated button that scales down when pressed.

## Acknowledgements

This package heavily relies on the amazing [motor](https://pub.dev/packages/motor) package.

## Usage

### 1. GlideMenu

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
