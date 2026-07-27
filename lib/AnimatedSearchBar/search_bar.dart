import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AnimatedSearchBar extends StatefulWidget {
  final void Function(String)? onChanged;

  const AnimatedSearchBar({super.key, required this.onChanged});

  @override
  State<AnimatedSearchBar> createState() => _AnimatedSearchBarState();
}

class _AnimatedSearchBarState extends State<AnimatedSearchBar> {
  bool _expanded = false;
  bool _showContent = false;
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    setState(() {
      _expanded = _focusNode.hasFocus;
      if (_expanded) {
        Future.delayed(const Duration(milliseconds: 100), () {
          setState(() {
            _showContent = true;
          });
        });
      } else {
        // When focus is lost, clear the search and collapse
        _showContent = false;
        _controller.clear();
        widget.onChanged?.call('');
      }
    });
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width - 40;

    return AnimatedContainer(
      width: _expanded ? screenWidth : 44,
      duration: Duration(milliseconds: 200),
      curve: Curves.linear,
      child: CupertinoSearchTextField(
        controller: _controller,
        focusNode: _focusNode,
        onChanged: widget.onChanged,
        placeholder: _showContent ? 'Search...' : '',
        style: const TextStyle(fontSize: 16),
        prefixIcon: const Icon(CupertinoIcons.search, size: 18),
        // equal padding on both sides to center the 18px icon in a 44px circle
        prefixInsets: const EdgeInsets.only(left: 13),
        suffixInsets: const EdgeInsets.only(right: 13),
        borderRadius: BorderRadius.circular(22),
        suffixMode: _showContent
            ? OverlayVisibilityMode.always
            : OverlayVisibilityMode.never,
        onSuffixTap: () {
          _controller.clear();
          widget.onChanged?.call('');
          _focusNode.unfocus();
        },
      ),
    );
  }
}

class TestScreen extends StatefulWidget {
  const TestScreen({super.key});

  @override
  State<TestScreen> createState() => _TestScreenState();
}

class _TestScreenState extends State<TestScreen> {
  List<AppColor> filteredColors = AppColor.allColors;

  void _search(String value) {
    setState(() {
      filteredColors = AppColor.allColors
          .where(
            (color) => color.name.toLowerCase().contains(value.toLowerCase()),
          )
          .toList();
    });
  }

  // Determine contrasting text color for readability on any background
  Color _contrastText(Color bg) {
    final luminance = bg.computeLuminance();
    return luminance > 0.45 ? const Color(0xFF0F172A) : Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(centerTitle: true, title: const Text('Color Palette')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Align(
              alignment: Alignment.centerRight,
              child: AnimatedSearchBar(onChanged: _search),
            ),
          ),
          const SizedBox(height: 12),
          // Color count badge
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${filteredColors.length} colors',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Grid
          Expanded(
            child: GridView.builder(
              physics: const BouncingScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 200,
                mainAxisExtent: 120,
              ),
              itemCount: filteredColors.length,
              itemBuilder: (context, index) {
                final color = filteredColors[index];
                final textColor = _contrastText(color.color);
                return Material(
                  color: color.color,
                  elevation: 2,
                  child: InkWell(
                    onTap: () {},
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          color.hex,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: textColor,
                            fontSize: 15,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          color.name,
                          style: TextStyle(
                            color: textColor.withValues(alpha: 0.75),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class AppColor {
  final String name;
  final String hex;
  final Color color;
  const AppColor({required this.color, required this.hex, required this.name});

  static const List<AppColor> allColors = [
    // Whites
    AppColor(name: 'Pure White', hex: '#FFFFFF', color: Color(0xFFFFFFFF)),
    AppColor(name: 'Off White', hex: '#F8F8F8', color: Color(0xFFF8F8F8)),
    AppColor(name: 'White Smoke', hex: '#F5F5F5', color: Color(0xFFF5F5F5)),
    AppColor(name: 'Ghost White', hex: '#F8F8FF', color: Color(0xFFF8F8FF)),
    AppColor(name: 'Snow', hex: '#FFFAFA', color: Color(0xFFFFFAFA)),

    // Greys
    AppColor(name: 'Light Grey', hex: '#D3D3D3', color: Color(0xFFD3D3D3)),
    AppColor(name: 'Grey', hex: '#808080', color: Color(0xFF808080)),
    AppColor(name: 'Dark Grey', hex: '#A9A9A9', color: Color(0xFFA9A9A9)),
    AppColor(name: 'Charcoal', hex: '#36454F', color: Color(0xFF36454F)),
    AppColor(name: 'Slate', hex: '#708090', color: Color(0xFF708090)),

    // Blues
    AppColor(name: 'Sky Blue', hex: '#87CEEB', color: Color(0xFF87CEEB)),
    AppColor(name: 'Light Blue', hex: '#ADD8E6', color: Color(0xFFADD8E6)),
    AppColor(name: 'Royal Blue', hex: '#4169E1', color: Color(0xFF4169E1)),
    AppColor(name: 'Navy Blue', hex: '#000080', color: Color(0xFF000080)),
    AppColor(name: 'Teal', hex: '#008080', color: Color(0xFF008080)),

    // Purples
    AppColor(name: 'Lavender', hex: '#E6E6FA', color: Color(0xFFE6E6FA)),
    AppColor(name: 'Purple', hex: '#800080', color: Color(0xFF800080)),
    AppColor(name: 'Indigo', hex: '#4B0082', color: Color(0xFF4B0082)),
    AppColor(name: 'Violet', hex: '#EE82EE', color: Color(0xFFEE82EE)),
    AppColor(name: 'Magenta', hex: '#FF00FF', color: Color(0xFFFF00FF)),

    // Greens
    AppColor(name: 'Mint', hex: '#ACFFAC', color: Color(0xFFACFFAC)),
    AppColor(name: 'Light Green', hex: '#90EE90', color: Color(0xFF90EE90)),
    AppColor(name: 'Green', hex: '#008000', color: Color(0xFF008000)),
    AppColor(name: 'Forest Green', hex: '#228B22', color: Color(0xFF228B22)),
    AppColor(name: 'Olive', hex: '#808000', color: Color(0xFF808000)),

    // Reds
    AppColor(name: 'Salmon', hex: '#FA8072', color: Color(0xFFFA8072)),
    AppColor(name: 'Light Coral', hex: '#F08080', color: Color(0xFFF08080)),
    AppColor(name: 'Red', hex: '#FF0000', color: Color(0xFFFF0000)),
    AppColor(name: 'Crimson', hex: '#DC143C', color: Color(0xFFDC143C)),
    AppColor(name: 'Maroon', hex: '#800000', color: Color(0xFF800000)),

    // Oranges/Yellows
    AppColor(name: 'Peach', hex: '#FFDAB9', color: Color(0xFFFFDAB9)),
    AppColor(name: 'Orange', hex: '#FFA500', color: Color(0xFFFFA500)),
    AppColor(name: 'Gold', hex: '#FFD700', color: Color(0xFFFFD700)),
    AppColor(name: 'Yellow', hex: '#FFFF00', color: Color(0xFFFFFF00)),
    AppColor(name: 'Mustard', hex: '#FFDB58', color: Color(0xFFFFDB58)),

    // Browns/Blacks
    AppColor(name: 'Tan', hex: '#D2B48C', color: Color(0xFFD2B48C)),
    AppColor(name: 'Brown', hex: '#A52A2A', color: Color(0xFFA52A2A)),
    AppColor(name: 'Sienna', hex: '#A0522D', color: Color(0xFFA0522D)),
    AppColor(name: 'Black', hex: '#000000', color: Color(0xFF000000)),
    AppColor(name: 'Dark Brown', hex: '#654321', color: Color(0xFF654321)),
  ];
}
