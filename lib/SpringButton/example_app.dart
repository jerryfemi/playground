import 'package:flutter/material.dart';
import 'package:playground/SpringButton/micro_interactions.dart';
import 'package:playground/AnimatedSearchBar/search_bar.dart';

class DemoPage extends StatefulWidget {
  const DemoPage({super.key});

  @override
  State<DemoPage> createState() => _DemoPageState();
}

class _DemoPageState extends State<DemoPage> {
  final List<DragMenuItem> backMenuItems = [
    DragMenuItem(
      label: 'Home',
      icon: const Icon(Icons.home_rounded),
      onSelected: () => debugPrint('Home selected'),
    ),
    DragMenuItem(
      label: 'Settings',
      icon: const Icon(Icons.settings_rounded),
      onSelected: () => debugPrint('Settings selected'),
    ),
    DragMenuItem(
      label: 'Search',
      icon: const Icon(Icons.search_rounded),
      onSelected: () => debugPrint('Search selected'),
    ),
    DragMenuItem(
      label: 'Close Chat',
      icon: const Icon(Icons.close_rounded, color: Colors.redAccent),
      onSelected: () => debugPrint('Close Chat selected'),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6), // Light gray background
      body: SafeArea(
        child: Column(
          children: [
            // Custom Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: Colors.white,
              child: Row(
                children: [
                  // The DragMenu and SpringButton back button
                  DragMenu(
                    items: backMenuItems,
                    itemHeight: 44,
                    menuWidth: 180,
                    deadZone: 10,
                    child: SpringButton(
                      pressedScale: 0.85,
                      dragFriction: 4.0, // tighter rubber band
                      enableTapHaptics: true,
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Back button tapped!')),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: const BoxDecoration(
                          color: Color(0xFFF0F1F5),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 20,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // User Profile Info
                  const CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.blueAccent,
                    child: Text('JD', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Jane Doe',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          'Online',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.green,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.more_vert_rounded),
                    color: Colors.black54,
                    onPressed: () {},
                  ),
                ],
              ),
            ),
            
            // Divider
            Container(
              height: 1,
              color: Colors.black.withOpacity(0.05),
            ),

            // Mock Chat Body
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildChatBubble('Hey! Are we still on for tomorrow?', isMe: false),
                  _buildChatBubble('Yes! See you at 10 AM.', isMe: true),
                  _buildChatBubble('Long press the back button in the header to see the new context menu in action!', isMe: false),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatBubble(String text, {required bool isMe}) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isMe ? Colors.blueAccent : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 15,
            color: isMe ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }
}
