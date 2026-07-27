import 'package:flutter/material.dart';
import 'package:playground/SpringButton/micro_interactions.dart';
import 'package:playground/AnimatedSearchBar/search_bar.dart';

class DemoPage extends StatefulWidget {
  const DemoPage({super.key});

  @override
  State<DemoPage> createState() => _DemoPageState();
}

class _DemoPageState extends State<DemoPage> {
  final List<DragMenuItem> items = [
    DragMenuItem(
      label: 'Reply',
      icon: const Icon(Icons.reply_rounded),
      onSelected: () => debugPrint('Reply selected'),
    ),
    DragMenuItem(
      label: 'Forward',
      icon: const Icon(Icons.forward_rounded),
      onSelected: () => debugPrint('Forward selected'),
    ),
    DragMenuItem(
      label: 'Copy',
      icon: const Icon(Icons.copy_rounded),
      onSelected: () => debugPrint('Copy selected'),
    ),
    DragMenuItem(
      label: 'Delete',
      icon: const Icon(Icons.delete_outline_rounded),
      onSelected: () => debugPrint('Delete selected'),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Micro-interactions Demo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.arrow_forward_rounded),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const TestScreen()),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SpringButton(
                pressedScale: 0.9,
                dragFriction: 3.0,
                enableTapHaptics: true,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Spring button tapped')),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text(
                    'Spring Button',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
              DragMenu(
                items: items,
                itemHeight: 48,
                menuWidth: 220,
                deadZone: 10,
                child: Container(
                  width: 300,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Long press and drag',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Keep your finger down, drag through actions, '
                        'release to select.',
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
