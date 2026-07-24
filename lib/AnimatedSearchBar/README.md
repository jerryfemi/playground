# Animated Search Bar

An elegant, expandable search bar built with Flutter.

##  Features
- Smoothly expands and collapses using an `AnimatedContainer`.
- Uses iOS-style `CupertinoSearchTextField` for a sleek native look.
- Manages focus dynamically, collapsing automatically when the user taps away or removes focus.

##  How it works
- **`AnimatedContainer`**: Drives the expansion and contraction animation based on the width changing when focused.
- **`FocusNode`**: Listens for focus changes to determine when the user is interacting with the search field so it knows when to collapse.
- **`TextEditingController`**: Captures and handles the search input.

##  Usage

To use this component in your project, simply import the widget and place it in your UI. It provides an `onChanged` callback to handle the text input.

```dart
import 'package:playground/AnimatedSearchBar/search_bar.dart';

// ... inside your widget tree
AnimatedSearchBar(
  onChanged: (value) {
    print("User is searching for: $value");
  },
)
```
