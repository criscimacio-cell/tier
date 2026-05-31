import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/pins_provider.dart';
import '../providers/user_provider.dart';
import 'login_screen.dart';
import 'map_screen.dart';
import 'discover_screen.dart';
import 'friends_screen.dart';
import 'profile_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;
  bool _initialized = false;

  static const List<Widget> _screens = [
    MapScreen(),
    DiscoverScreen(),
    FriendsScreen(),
    ProfileScreen(),
  ];

  void _onAuthChanged() {
    if (!mounted) return;
    if (!context.read<UserProvider>().isLoggedIn) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<UserProvider>().addListener(_onAuthChanged);
    });
    _initData();
  }

  @override
  void dispose() {
    try {
      context.read<UserProvider>().removeListener(_onAuthChanged);
    } catch (_) {}
    super.dispose();
  }

  Future<void> _initData() async {
    final pinsProvider = context.read<PinsProvider>();
    final userProvider = context.read<UserProvider>();
    if (userProvider.user.id.isNotEmpty) {
      await pinsProvider.loadPins(userProvider.user.id);
    }
    if (mounted) setState(() => _initialized = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const Scaffold(
        backgroundColor: Color(0xFF0A1628),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('🗺️', style: TextStyle(fontSize: 64)),
              SizedBox(height: 20),
              Text(
                'memorymap',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1.0,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'every place, a story.',
                style: TextStyle(
                  color: Color(0xFF8899BB),
                  fontSize: 15,
                  fontStyle: FontStyle.italic,
                ),
              ),
              SizedBox(height: 48),
              CircularProgressIndicator(
                color: Color(0xFFFF6B6B),
                strokeWidth: 2,
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          IndexedStack(
            index: _currentIndex,
            children: _screens,
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              margin: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(32),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 24,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        _NavItem(
                          icon: Icons.map_outlined,
                          activeIcon: Icons.map,
                          label: 'Map',
                          isActive: _currentIndex == 0,
                          onTap: () => setState(() => _currentIndex = 0),
                        ),
                        _NavItem(
                          icon: Icons.explore_outlined,
                          activeIcon: Icons.explore,
                          label: 'Discover',
                          isActive: _currentIndex == 1,
                          onTap: () => setState(() => _currentIndex = 1),
                        ),
                        _NavItem(
                          icon: Icons.people_outline,
                          activeIcon: Icons.people,
                          label: 'Friends',
                          isActive: _currentIndex == 2,
                          onTap: () => setState(() => _currentIndex = 2),
                        ),
                        _NavItem(
                          icon: Icons.person_outline,
                          activeIcon: Icons.person,
                          label: 'Profile',
                          isActive: _currentIndex == 3,
                          onTap: () => setState(() => _currentIndex = 3),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const activeColor = Color(0xFF1A535C);
    final inactiveColor = Colors.grey.shade400;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              color: isActive ? activeColor : inactiveColor,
              size: 24,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                color: isActive ? activeColor : inactiveColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
