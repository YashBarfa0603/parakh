import 'package:flutter/material.dart';
import '../core/theme.dart';
import 'home/home_screen.dart';
import 'more/profile_screen.dart';
import 'reports/reports_list_screen.dart';
import 'scan/camera_screen.dart';

class MainShell extends StatefulWidget {
  final int initialTab;
  const MainShell({super.key, this.initialTab = 0});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell>
    with SingleTickerProviderStateMixin {
  late int _currentIndex;

  // Single source of truth — no per-item selected booleans
  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTab;
  }

  static const List<_NavItem> _navItems = [
    _NavItem(
      index: 0,
      label: 'Home',
      activeIcon: Icons.home_rounded,
      inactiveIcon: Icons.home_outlined,
    ),
    _NavItem(
      index: 1,
      label: 'Scan',
      activeIcon: Icons.qr_code_scanner_rounded,
      inactiveIcon: Icons.qr_code_scanner_rounded,
      isProminent: true,
    ),
    _NavItem(
      index: 2,
      label: 'Reports',
      activeIcon: Icons.description_rounded,
      inactiveIcon: Icons.description_outlined,
    ),
    _NavItem(
      index: 3,
      label: 'Profile',
      activeIcon: Icons.person_rounded,
      inactiveIcon: Icons.person_outline_rounded,
    ),
  ];

  final List<Widget> _screens = const [
    HomeScreen(),
    CameraScreen(),
    ReportsListScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ParakhColors.background,
      body: Stack(
        children: [
          // Screen content
          Positioned.fill(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.015, 0),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    )),
                    child: child,
                  ),
                );
              },
              child: KeyedSubtree(
                key: ValueKey<int>(_currentIndex),
                child: _screens[_currentIndex],
              ),
            ),
          ),

          // Floating pill navigation
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              child: _FloatingNavBar(
                currentIndex: _currentIndex,
                items: _navItems,
                onTap: (index) => setState(() => _currentIndex = index),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Data class for nav items
class _NavItem {
  final int index;
  final String label;
  final IconData activeIcon;
  final IconData inactiveIcon;
  final bool isProminent;

  const _NavItem({
    required this.index,
    required this.label,
    required this.activeIcon,
    required this.inactiveIcon,
    this.isProminent = false,
  });
}

// Floating nav bar with single sliding indicator
class _FloatingNavBar extends StatelessWidget {
  final int currentIndex;
  final List<_NavItem> items;
  final ValueChanged<int> onTap;

  const _FloatingNavBar({
    required this.currentIndex,
    required this.items,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 20, bottom: 14, top: 4),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            decoration: BoxDecoration(
              color: ParakhColors.surface,
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: ParakhColors.border, width: 1.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 20,
                  spreadRadius: 0,
                  offset: const Offset(0, 6),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 4,
                  spreadRadius: 0,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: items.map((item) {
                final isSelected = currentIndex == item.index;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => onTap(item.index),
                    behavior: HitTestBehavior.opaque,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOutCubic,
                      padding: EdgeInsets.symmetric(
                        horizontal: item.isProminent ? 10 : 8,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        // Single selected background — only active item
                        color: isSelected
                            ? (item.isProminent
                                ? ParakhColors.accent
                                : ParakhColors.veryLightBlue)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedScale(
                            scale: isSelected ? 1.1 : 1.0,
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeOutCubic,
                            child: Icon(
                              isSelected ? item.activeIcon : item.inactiveIcon,
                              size: 20,
                              color: isSelected
                                  ? (item.isProminent
                                      ? ParakhColors.textOnPrimary
                                      : ParakhColors.accent)
                                  : ParakhColors.textTertiary,
                            ),
                          ),
                          const SizedBox(height: 3),
                          AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeOutCubic,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 10,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: isSelected
                                  ? (item.isProminent
                                      ? ParakhColors.textOnPrimary
                                      : ParakhColors.accent)
                                  : ParakhColors.textTertiary,
                            ),
                            child: Text(item.label),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}
