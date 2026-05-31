import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'providers/pins_provider.dart';
import 'providers/user_provider.dart';
import 'screens/map_screen.dart';
import 'screens/discover_screen.dart';
import 'screens/friends_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/login_screen.dart';
import 'screens/onboarding_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  await Supabase.initialize(
    url: 'https://uhhvsyzhguwcagniydfr.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVoaHZzeXpoZ3V3Y2Fnbml5ZGZyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODAxNzQ4NDgsImV4cCI6MjA5NTc1MDg0OH0.OVGO4X7g3yblER5M9N95PhF9cwWyt1FHf1fZ4d6A90Q',
  );
  runApp(const MemoryMapApp());
}

class MemoryMapApp extends StatelessWidget {
  const MemoryMapApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PinsProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
      ],
      child: MaterialApp(
        title: 'Memory Map',
        debugShowCheckedModeBanner: false,
        theme: _buildTheme(),
        home: Consumer<UserProvider>(
          builder: (ctx, userP, _) {
            // Auto-restore Supabase session
            final supabaseUser = Supabase.instance.client.auth.currentUser;
            if (supabaseUser != null && !userP.isLoggedIn) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                userP.restoreSession(supabaseUser);
              });
            }
            if (!userP.isLoggedIn) return const LoginScreen();
            if (!userP.onboardingComplete) return const OnboardingScreen();
            return const AppShell();
          },
        ),
      ),
    );
  }

  ThemeData _buildTheme() {
    const primary = Color(0xFF1A535C);
    const accent = Color(0xFFFF6B6B);
    const background = Color(0xFFF7F3E9);

    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: Brightness.light,
        primary: primary,
        secondary: accent,
        surface: Colors.white,
      ),
      scaffoldBackgroundColor: background,
      appBarTheme: const AppBarTheme(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        side: BorderSide.none,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: primary,
        unselectedItemColor: Color(0xFFAAAAAA),
        selectedLabelStyle: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
        unselectedLabelStyle: TextStyle(
          fontWeight: FontWeight.w400,
          fontSize: 11,
        ),
        elevation: 12,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell();

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

  @override
  void initState() {
    super.initState();
    _initData();
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
              Text(
                '🗺️',
                style: TextStyle(fontSize: 64),
              ),
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
          // Floating Glassmorphic Bottom Nav
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

// Floating nav item

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
