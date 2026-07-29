import 'package:flutter/material.dart';
import 'src/glide_menu.dart';

class DemoPage extends StatefulWidget {
  const DemoPage({super.key});

  @override
  State<DemoPage> createState() => _DemoPageState();
}

class _DemoPageState extends State<DemoPage> {
  // Theme colors matching premium dark chat apps
  final Color _bgColor = const Color(0xFF0E1621);
  final Color _appBarColor = const Color(0xFF17212B);
  final Color _myBubbleColor = const Color(0xFF2B5278);
  final Color _theirBubbleColor = const Color(0xFF182533);
  final Color _textColor = const Color(0xFFE4E4E4);

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: _bgColor,
        appBarTheme: AppBarTheme(
          backgroundColor: _appBarColor,
          elevation: 2,
        ),
      ),
      child: Scaffold(
        appBar: _buildAppBar(),
        body: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildDateHeader('Today'),
                  const SizedBox(height: 16),
                  _buildTheirBubble('Hey! Did you finish the new GlideMenu physics?'),
                  const SizedBox(height: 8),
                  _buildMyBubble('Yes! It has the iOS squish and the massive Telegram bounce now. Long-press this bubble to see the quick actions!'),
                  const SizedBox(height: 8),
                  _buildTheirBubble('Whoa, that sounds awesome. What about the hybrid scroll? Does it work for insanely long menus?'),
                  const SizedBox(height: 8),
                  // The massive overflow list to showcase push up and hybrid scroll
                  _buildOverflowBubble(),
                  const SizedBox(height: 16),
                  const Center(
                    child: Text(
                      'End of chat',
                      style: TextStyle(color: Colors.white24, fontSize: 12),
                    ),
                  )
                ],
              ),
            ),
            _buildInputArea(),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      leading: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70),
      titleSpacing: 0,
      title: Row(
        children: [
          // GlideMenu wrapping the avatar!
          GlideMenu<String>(
            backgroundColor: const Color(0xFF1E293B), // Deep slate
            textStyle: const TextStyle(color: Colors.white, fontSize: 16),
            margin: 16,
            borderRadius: 16,
            items: const [
              GlideMenuItem(value: 'profile', label: 'View Profile', icon: Icon(Icons.person_outline, color: Colors.white)),
              GlideMenuItem(value: 'mute', label: 'Mute Notifications', icon: Icon(Icons.notifications_off_outlined, color: Colors.white)),
              GlideMenuItem(value: 'call', label: 'Call', icon: Icon(Icons.call_outlined, color: Colors.greenAccent)),
            ],
            footer: const GlideMenuItem(
              value: 'block',
              label: 'Block User',
              icon: Icon(Icons.block, color: Colors.redAccent),
              isDestructive: true,
            ),
            onSelected: (val) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Selected: $val')));
            },
            child: CircleAvatar(
              radius: 18,
              backgroundColor: Colors.blueAccent.withValues(alpha: 0.2),
              child: const Text('JD', style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Jane Doe', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _textColor)),
              const Text('online', style: TextStyle(fontSize: 12, color: Colors.blueAccent)),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(icon: const Icon(Icons.phone_outlined, color: Colors.white70), onPressed: () {}),
        GlideMenu<String>(
          backgroundColor: const Color(0xFF1E293B),
          textStyle: const TextStyle(color: Colors.white, fontSize: 16),
          margin: 16,
          borderRadius: 16,
          items: const [
            GlideMenuItem(value: 'search', label: 'Search', icon: Icon(Icons.search_rounded, color: Colors.white)),
            GlideMenuItem(value: 'clear', label: 'Clear History', icon: Icon(Icons.cleaning_services_rounded, color: Colors.white)),
          ],
          footer: const GlideMenuItem(
            value: 'delete',
            label: 'Delete Chat',
            icon: Icon(Icons.delete_outline, color: Colors.redAccent),
            isDestructive: true,
          ),
          onSelected: (val) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Selected: $val')));
          },
          child: IconButton(icon: const Icon(Icons.more_vert_rounded, color: Colors.white70), onPressed: null),
        ),
      ],
    );
  }

  Widget _buildDateHeader(String text) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(text, style: const TextStyle(fontSize: 12, color: Colors.white54)),
      ),
    );
  }

  Widget _buildTheirBubble(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: GlideMenu<String>(
        backgroundColor: const Color(0xFF1E293B),
        textStyle: const TextStyle(color: Colors.white, fontSize: 16),
        margin: 16,
        borderRadius: 16,
        items: const [
          GlideMenuItem(value: 'reply', label: 'Reply', icon: Icon(Icons.reply_rounded, color: Colors.white)),
          GlideMenuItem(value: 'copy', label: 'Copy Text', icon: Icon(Icons.copy_rounded, color: Colors.white)),
          GlideMenuItem(value: 'forward', label: 'Forward', icon: Icon(Icons.forward_rounded, color: Colors.white)),
          GlideMenuItem(value: 'pin', label: 'Pin', icon: Icon(Icons.push_pin_outlined, color: Colors.white)),
        ],
        footer: const GlideMenuItem(
          value: 'delete',
          label: 'Delete',
          icon: Icon(Icons.delete_outline, color: Colors.redAccent),
          isDestructive: true,
        ),
        onSelected: (val) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Selected: $val')));
        },
        child: Container(
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: _theirBubbleColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
              bottomRight: Radius.circular(16),
              bottomLeft: Radius.circular(4),
            ),
          ),
          child: Text(text, style: TextStyle(color: _textColor, fontSize: 16)),
        ),
      ),
    );
  }

  Widget _buildMyBubble(String text) {
    return Align(
      alignment: Alignment.centerRight,
      child: GlideMenu<String>(
        backgroundColor: const Color(0xFF1E293B),
        textStyle: const TextStyle(color: Colors.white, fontSize: 16),
        margin: 16,
        borderRadius: 16,
        items: const [
          GlideMenuItem(value: 'reply', label: 'Reply', icon: Icon(Icons.reply_rounded, color: Colors.white)),
          GlideMenuItem(value: 'copy', label: 'Copy Text', icon: Icon(Icons.copy_rounded, color: Colors.white)),
          GlideMenuItem(value: 'forward', label: 'Forward', icon: Icon(Icons.forward_rounded, color: Colors.white)),
          GlideMenuItem(value: 'edit', label: 'Edit', icon: Icon(Icons.edit_outlined, color: Colors.white)),
        ],
        footer: const GlideMenuItem(
          value: 'delete',
          label: 'Delete',
          icon: Icon(Icons.delete_outline, color: Colors.redAccent),
          isDestructive: true,
        ),
        onSelected: (val) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Selected: $val')));
        },
        child: Container(
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: _myBubbleColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(4),
            ),
          ),
          child: Text(text, style: TextStyle(color: _textColor, fontSize: 16)),
        ),
      ),
    );
  }

  Widget _buildOverflowBubble() {
    return Align(
      alignment: Alignment.centerRight,
      child: GlideMenu<String>(
        backgroundColor: const Color(0xFF1E293B),
        textStyle: const TextStyle(color: Colors.white, fontSize: 16),
        margin: 16,
        borderRadius: 16,
        items: List.generate(15, (index) {
          return GlideMenuItem(
            value: 'item_$index',
            label: 'Overflow Action ${index + 1}',
            icon: const Icon(Icons.api_rounded, color: Colors.white54),
          );
        }),
        footer: const GlideMenuItem(
          value: 'delete',
          label: 'Delete All',
          icon: Icon(Icons.delete_sweep_rounded, color: Colors.redAccent),
          isDestructive: true,
        ),
        onSelected: (val) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Selected: $val')));
        },
        child: Container(
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: _myBubbleColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(4),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Yes! Try long-pressing this specific bubble. It has 15 items in its menu.', style: TextStyle(color: _textColor, fontSize: 16)),
              const SizedBox(height: 8),
              Container(
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(child: Icon(Icons.touch_app_rounded, color: Colors.white54, size: 48)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      color: _appBarColor,
      padding: EdgeInsets.only(left: 12, right: 12, top: 8, bottom: 8 + MediaQuery.of(context).padding.bottom),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            const Icon(Icons.attach_file_rounded, color: Colors.white54),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: _bgColor,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Text('Message', style: TextStyle(color: Colors.white54, fontSize: 16)),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: Colors.blueAccent,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.mic, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
