import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'providers/pins_provider.dart';
import 'providers/user_provider.dart';
import 'screens/app_shell.dart';
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

