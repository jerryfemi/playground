import 'package:flutter/material.dart';

import 'src/glide_menu.dart';
import 'src/spring_button.dart';

class DemoPage extends StatefulWidget {
  const DemoPage({super.key});

  @override
  State<DemoPage> createState() => _DemoPageState();
}

class _DemoPageState extends State<DemoPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text(
          'GlideMenu',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
        children: [
          _buildSectionTitle('1. Classic Action Menu'),
          const SizedBox(height: 12),
          _buildClassicMenuExample(),
          const SizedBox(height: 48),
          _buildSectionTitle('2. Custom Child Override'),
          const SizedBox(height: 12),
          _buildCustomChildExample(),
          const SizedBox(height: 48),
          _buildSectionTitle('3. Standalone SpringButton'),
          const SizedBox(height: 12),
          _buildSpringButtonShowcase(),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: Colors.black54,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildClassicMenuExample() {
    return Center(
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
          GlideMenuItem<String>(
            value: 'share',
            label: 'Share',
            icon: Icon(Icons.ios_share_rounded),
          ),
        ],
        footer: const GlideMenuItem<String>(
          value: 'delete',
          label: 'Delete',
          icon: Icon(Icons.delete_outline_rounded, color: Colors.red),
          isDestructive: true,
        ),
        onSelected: (value) {
          debugPrint('Selected classic menu action: $value');
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: const Column(
            children: [
              Icon(
                Icons.chat_bubble_outline_rounded,
                size: 32,
                color: Colors.blueAccent,
              ),
              SizedBox(height: 12),
              Text(
                'Long-press for actions',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomChildExample() {
    return Center(
      child: GlideMenu<String>(
        menuWidth: 200,
        items: [
          GlideMenuItem<String>(
            value: 'profile',
            // Here we completely override the item layout with a custom widget
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 14,
                  backgroundColor: Colors.deepPurpleAccent,
                  child: Icon(Icons.person, size: 16, color: Colors.white),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Jane Doe',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        'View Profile',
                        style: TextStyle(fontSize: 11, color: Colors.black54),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 16,
                  color: Colors.black.withValues(alpha: 0.3),
                ),
              ],
            ),
          ),
          const GlideMenuItem<String>(
            value: 'settings',
            label: 'Settings',
            icon: Icon(Icons.settings_rounded),
          ),
          const GlideMenuItem<String>(
            value: 'call',
            label: 'Call',
            icon: Icon(Icons.call_rounded),
          ),
          ...List.generate(6, (index) {
            return GlideMenuItem<String>(
              value: 'item_$index',
              label: 'Long List Item $index',
              icon: const Icon(Icons.circle_outlined),
            );
          }),
          const GlideMenuItem<String>(
            value: 'block',
            label: 'Block User',
            icon: Icon(Icons.block_rounded, color: Colors.redAccent),
            isDestructive: true,
          ),
        ],
        onSelected: (value) {
          debugPrint('Selected custom menu action: $value');
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 24),
          decoration: BoxDecoration(
            color: Colors.deepPurpleAccent.withValues(alpha: 1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.deepPurpleAccent.withValues(alpha: 0.2),
            ),
          ),
          child: const Column(
            children: [
              Icon(
                Icons.dashboard_customize_rounded,
                size: 32,
                color: Colors.deepPurpleAccent,
              ),
              SizedBox(height: 12),
              Text(
                'Long-press for custom child',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.deepPurple,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSpringButtonShowcase() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // 1. Container Button
          SpringButton(
            onTap: () => debugPrint('Container Button Tapped'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Button',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          // 2. Pure Icon
          SpringButton(
            onTap: () => debugPrint('Icon Button Tapped'),
            child: const Icon(
              Icons.favorite_rounded,
              color: Colors.pinkAccent,
              size: 42,
            ),
          ),

          // 3. Pure Text
          SpringButton(
            onTap: () => debugPrint('Text Button Tapped'),
            dragFriction: 30, // Make it very snappy for text
            child: const Text(
              'Tap Me!',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Colors.blueAccent,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
