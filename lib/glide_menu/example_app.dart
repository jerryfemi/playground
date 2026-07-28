import 'package:flutter/material.dart';
import 'package:playground/glide_menu/glide_menu.dart';
import 'package:playground/AnimatedSearchBar/search_bar.dart';

class DemoPage extends StatefulWidget {
  const DemoPage({super.key});

  @override
  State<DemoPage> createState() => _DemoPageState();
}

class _DemoPageState extends State<DemoPage> {
  late final List<GlideMenuItem<String>> backMenuItems = [
    const GlideMenuItem<String>(
      value: 'home',
      label: 'Home',
      icon: Icon(Icons.home_rounded),
    ),
    const GlideMenuItem<String>(
      value: 'settings',
      label: 'Settings',
      icon: Icon(Icons.settings_rounded),
    ),
    const GlideMenuItem<String>(
      value: 'search',
      label: 'Search',
      icon: Icon(Icons.search_rounded),
    ),
    const GlideMenuItem<String>(
      value: 'close',
      label: 'Close Chat',
      icon: Icon(Icons.close_rounded, color: Colors.redAccent),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      body: SafeArea(
        child: Column(
          children: [
            // Custom Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: Colors.white,
              child: Row(
                children: [
                  // The GlideMenu and SpringButton back button
                  GlideMenu<String>(
                    items: backMenuItems,
                    itemHeight: 40,
                    menuWidth: 180,
                    borderRadius: 16,
                    itemBorderRadius: 16,
                    deadZone: 10,
                    onSelected: (value) {
                      if (value == 'search') {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const TestScreen(),
                          ),
                        );
                      } else {
                        debugPrint('$value selected');
                      }
                    },
                    child: SpringButton(
                      pressedScale: 0.85,
                      enableTapHaptics: true,
                      onTap: () {
                        // Action for back button
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
                    child: Text(
                      'JD',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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
            Container(height: 1, color: Colors.black.withValues(alpha: 0.05)),

            // Mock Chat Body
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildChatBubble(
                    'Hey! Are we still on for tomorrow?',
                    isMe: false,
                  ),
                  _buildChatBubble('Yes! See you at 10 AM.', isMe: true),
                  _buildChatBubble(
                    'Long press the back button in the header to see the new context menu in action!',
                    isMe: false,
                  ),
                ],
              ),
            ),

            // Bottom Input Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: Colors.white,
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    // ANOTHER STANDALONE SPRING BUTTON (Attachment)
                    SpringButton(
                      pressedScale: 0.8,
                      enableTapHaptics: true,
                      onTap: () {
                        // Action for attachment
                      },
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: const BoxDecoration(
                          color: Color(0xFFF0F1F5),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.add_rounded,
                          color: Colors.black87,
                          size: 22,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F1F5),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: const Text(
                          'Type a message...',
                          style: TextStyle(color: Colors.black38),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // STANDALONE SPRING BUTTON (Send)
                    SpringButton(
                      pressedScale: 0.8,
                      dragFriction: 5.0,
                      enableTapHaptics: true,
                      onTap: () {
                        // Action for send
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: const BoxDecoration(
                          color: Colors.blueAccent,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.send_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
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
      child: GlideMenu<String>(
        items: const [
          GlideMenuItem<String>(
            value: 'reply',
            label: 'Reply',
            icon: Icon(Icons.reply_rounded),
          ),
          GlideMenuItem<String>(
            value: 'copy',
            label: 'Copy',
            icon: Icon(Icons.copy_rounded),
          ),
        ],
        footer: const GlideMenuItem<String>(
          value: 'delete',
          label: 'Delete',
          icon: Icon(Icons.delete_outline_rounded, color: Colors.red),
          isDestructive: true,
        ),
        onSelected: (value) => debugPrint('$value selected on bubble'),
        menuWidth: 160,

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
      ),
    );
  }
}
