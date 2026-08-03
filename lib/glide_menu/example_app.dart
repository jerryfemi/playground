import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'src/glide_menu.dart';

class DemoPage extends StatefulWidget {
  const DemoPage({super.key});

  @override
  State<DemoPage> createState() => _DemoPageState();
}

class _DemoPageState extends State<DemoPage> {
  // Classic iOS-style menu styling
  final Color _menuBgColor = const Color(0xFF1E1E1E).withValues(alpha: 0.85);
  final TextStyle _menuTextStyle =
      const TextStyle(color: Colors.white, fontSize: 16);

  void _showSnackbar(String text) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          _buildPhotoGrid(),
          const SliverPadding(
              padding: EdgeInsets.only(bottom: 90)), // Spacer for bottom bar
        ],
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      backgroundColor: Colors.black.withValues(alpha: 0.85),
      surfaceTintColor: Colors.transparent,
      pinned: true,
      floating: false,
      elevation: 0,
      expandedHeight: 100,
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: const FlexibleSpaceBar(
            titlePadding: EdgeInsets.only(left: 16, bottom: 12),
            title: Text(
              'Recents',
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 28,
                  letterSpacing: -0.5,
                  color: Colors.white),
            ),
          ),
        ),
      ),
      leadingWidth: 100,
      leading: CupertinoButton(
        padding: EdgeInsets.zero,
        child: const Row(
          children: [
            Icon(CupertinoIcons.back,
                color: CupertinoColors.activeBlue, size: 28),
            Text('Albums',
                style:
                    TextStyle(color: CupertinoColors.activeBlue, fontSize: 17)),
          ],
        ),
        onPressed: () {},
      ),
      actions: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
          ),
          child: CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
            onPressed: () {},
            minimumSize: Size(0, 0),
            child: const Text('Select',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600)),
          ),
        ),
        const SizedBox(width: 12),
        // THE BUTTON MODE MENU
        GlideMenu<String>.button(
          backgroundColor: _menuBgColor,
          textStyle: _menuTextStyle,
          margin: 16,
          items: const [
            GlideMenuItem(
                value: 'zoom_in',
                label: 'Zoom In',
                icon: Icon(CupertinoIcons.zoom_in, color: Colors.white)),
            GlideMenuItem(
                value: 'zoom_out',
                label: 'Zoom Out',
                icon: Icon(CupertinoIcons.zoom_out, color: Colors.white)),
            GlideMenuItem(
                value: 'aspect',
                label: 'Aspect Ratio Grid',
                icon:
                    Icon(CupertinoIcons.square_grid_2x2, color: Colors.white)),
          ],
          footer: const GlideMenuItem(
              value: 'filter',
              label: 'Filter',
              icon: Icon(CupertinoIcons.slider_horizontal_3,
                  color: Colors.white)),
          onSelected: (val) => _showSnackbar('Action: $val'),
          child: Container(
            width: 32,
            height: 32,
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.15),
            ),
            child: const Icon(CupertinoIcons.ellipsis,
                color: Colors.white, size: 20),
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoGrid() {
    return SliverGrid(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 1.5,
        crossAxisSpacing: 1.5,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          // A mix of regular photos and some simulated videos
          final isVideo = index % 7 == 0;

          return GlideMenu<String>(
            backgroundColor: _menuBgColor,
            textStyle: _menuTextStyle,
            margin: 16,
            items: const [
              GlideMenuItem(
                  value: 'copy',
                  label: 'Copy',
                  icon: Icon(CupertinoIcons.doc_on_clipboard,
                      color: Colors.white)),
              GlideMenuItem(
                  value: 'share',
                  label: 'Share',
                  icon: Icon(CupertinoIcons.share, color: Colors.white)),
              GlideMenuItem(
                  value: 'favorite',
                  label: 'Favorite',
                  icon: Icon(CupertinoIcons.heart, color: Colors.white)),
              GlideMenuItem(
                  value: 'hide',
                  label: 'Hide',
                  icon: Icon(CupertinoIcons.eye_slash, color: Colors.white)),
            ],
            footer: const GlideMenuItem(
                value: 'delete',
                label: 'Delete',
                icon: Icon(CupertinoIcons.trash,
                    color: CupertinoColors.destructiveRed),
                isDestructive: true),
            onSelected: (val) => _showSnackbar('Photo action: $val'),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  'https://picsum.photos/id/${index + 10}/300/300',
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                        color:
                            const Color(0xFF1E1E1E)); // Dark gray placeholder
                  },
                ),
                if (isVideo)
                  const Positioned(
                    bottom: 4,
                    right: 4,
                    child: Text(
                      '0:30',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
        childCount: 60,
      ),
    );
  }

  Widget _buildBottomBar() {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: BottomNavigationBar(
          backgroundColor: const Color(0xFF1E1E1E).withValues(alpha: 0.8),
          type: BottomNavigationBarType.fixed,
          selectedItemColor: CupertinoColors.activeBlue,
          unselectedItemColor: Colors.grey,
          currentIndex: 2,
          selectedFontSize: 11,
          unselectedFontSize: 11,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.photo),
              label: 'Library',
            ),
            BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.heart_solid),
              label: 'For You',
            ),
            BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.rectangle_stack_fill),
              label: 'Albums',
            ),
            BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.search),
              label: 'Search',
            ),
          ],
        ),
      ),
    );
  }
}
