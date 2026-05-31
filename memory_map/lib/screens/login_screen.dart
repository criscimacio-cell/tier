import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import 'onboarding_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _signInFormKey = GlobalKey<FormState>();
  final _signUpFormKey = GlobalKey<FormState>();

  final _signInEmailCtrl = TextEditingController();
  final _signInPasswordCtrl = TextEditingController();
  final _signUpNameCtrl = TextEditingController();
  final _signUpEmailCtrl = TextEditingController();
  final _signUpPasswordCtrl = TextEditingController();

  bool _obscureSignIn = true;
  bool _obscureSignUp = true;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _signInEmailCtrl.dispose();
    _signInPasswordCtrl.dispose();
    _signUpNameCtrl.dispose();
    _signUpEmailCtrl.dispose();
    _signUpPasswordCtrl.dispose();
    super.dispose();
  }

  void _signInWithGoogle() async {
    setState(() => _loading = true);
    final error = await context.read<UserProvider>().signInWithGoogle();
    if (!mounted) return;
    setState(() => _loading = false);
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: const Color(0xFFFF6B6B)),
      );
    }
    // Navigation handled automatically by auth state listener in UserProvider
  }

  void _signIn() async {
    if (!_signInFormKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final error = await context.read<UserProvider>().signIn(
      _signInEmailCtrl.text.trim(),
      _signInPasswordCtrl.text,
    );
    if (!mounted) return;
    setState(() => _loading = false);
    if (error == '__not_activated__') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account not activated. Check your email for the activation link.'),
          backgroundColor: Color(0xFFFF6B6B),
          duration: Duration(seconds: 5),
        ),
      );
      return;
    }
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: const Color(0xFFFF6B6B)),
      );
      return;
    }
    // Navigation is handled by Consumer in main.dart once _isLoggedIn = true
  }

  void _signUp() async {
    if (!_signUpFormKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final result = await context.read<UserProvider>().signUp(
      _signUpNameCtrl.text.trim(),
      _signUpEmailCtrl.text.trim(),
      _signUpPasswordCtrl.text,
    );
    if (!mounted) return;
    setState(() => _loading = false);
    if (result == '__confirm__') {
      _showConfirmationDialog(_signUpEmailCtrl.text.trim());
      return;
    }
    if (result != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result), backgroundColor: const Color(0xFFFF6B6B)),
      );
    }
  }

  void _showConfirmationDialog(String email) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.fromLTRB(28, 28, 28, 20),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFF1A535C).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Center(child: Text('📧', style: TextStyle(fontSize: 32))),
            ),
            const SizedBox(height: 16),
            const Text(
              'Check your email',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF1A1A2E)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'We sent a confirmation link to\n$email\n\nClick the link to activate your account, then sign in.',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600, height: 1.5),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () {
                Navigator.pop(context);
                _tabController.animateTo(0); // switch to Sign In tab
              },
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFF1A535C),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('Go to Sign In', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F3E9),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // ── Header ─────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 48, 24, 36),
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A535C),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF1A535C).withValues(alpha: 0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text('🗺️', style: TextStyle(fontSize: 40)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'memorymap',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1A535C),
                        letterSpacing: -1.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'every place, a story.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade500,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),

              // ── Card ───────────────────────────────────────────────────
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.07),
                      blurRadius: 24,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Tab switcher
                    Container(
                      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0EDE8),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TabBar(
                        controller: _tabController,
                        indicator: BoxDecoration(
                          color: const Color(0xFF1A535C),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        indicatorSize: TabBarIndicatorSize.tab,
                        labelColor: Colors.white,
                        unselectedLabelColor: Colors.grey.shade600,
                        labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                        dividerColor: Colors.transparent,
                        tabs: const [Tab(text: 'Sign In'), Tab(text: 'Sign Up')],
                      ),
                    ),

                    SizedBox(
                      height: 320,
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _SignInForm(
                            formKey: _signInFormKey,
                            emailCtrl: _signInEmailCtrl,
                            passwordCtrl: _signInPasswordCtrl,
                            obscure: _obscureSignIn,
                            onToggleObscure: () => setState(() => _obscureSignIn = !_obscureSignIn),
                            loading: _loading,
                            onSubmit: _signIn,
                          ),
                          _SignUpForm(
                            formKey: _signUpFormKey,
                            nameCtrl: _signUpNameCtrl,
                            emailCtrl: _signUpEmailCtrl,
                            passwordCtrl: _signUpPasswordCtrl,
                            obscure: _obscureSignUp,
                            onToggleObscure: () => setState(() => _obscureSignUp = !_obscureSignUp),
                            loading: _loading,
                            onSubmit: _signUp,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
              // ── OR divider ─────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(child: Divider(color: Colors.grey.shade300)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Text('or', style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
                    ),
                    Expanded(child: Divider(color: Colors.grey.shade300)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // ── Google button ──────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _GoogleButton(loading: _loading, onTap: _signInWithGoogle),
              ),
              const SizedBox(height: 24),
              Text(
                'Your memories stay on your device.',
                style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Sign In form ────────────────────────────────────────────────────────────

class _SignInForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController emailCtrl;
  final TextEditingController passwordCtrl;
  final bool obscure;
  final VoidCallback onToggleObscure;
  final bool loading;
  final VoidCallback onSubmit;

  const _SignInForm({
    required this.formKey, required this.emailCtrl, required this.passwordCtrl,
    required this.obscure, required this.onToggleObscure,
    required this.loading, required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
        child: Column(
          children: [
            _Field(
              controller: emailCtrl,
              label: 'Email',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              validator: (v) => (v == null || !v.contains('@')) ? 'Enter a valid email' : null,
            ),
            const SizedBox(height: 14),
            _Field(
              controller: passwordCtrl,
              label: 'Password',
              icon: Icons.lock_outline,
              obscure: obscure,
              suffixIcon: IconButton(
                icon: Icon(obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20, color: Colors.grey),
                onPressed: onToggleObscure,
              ),
              validator: (v) => (v == null || v.length < 6) ? 'Min 6 characters' : null,
            ),
            const Spacer(),
            _SubmitButton(loading: loading, label: 'Sign In', onTap: onSubmit),
          ],
        ),
      ),
    );
  }
}

// ── Sign Up form ────────────────────────────────────────────────────────────

class _SignUpForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController nameCtrl;
  final TextEditingController emailCtrl;
  final TextEditingController passwordCtrl;
  final bool obscure;
  final VoidCallback onToggleObscure;
  final bool loading;
  final VoidCallback onSubmit;

  const _SignUpForm({
    required this.formKey, required this.nameCtrl,
    required this.emailCtrl, required this.passwordCtrl,
    required this.obscure, required this.onToggleObscure,
    required this.loading, required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
        child: Column(
          children: [
            _Field(
              controller: nameCtrl,
              label: 'Full Name',
              icon: Icons.person_outline,
              textCapitalization: TextCapitalization.words,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter your name' : null,
            ),
            const SizedBox(height: 12),
            _Field(
              controller: emailCtrl,
              label: 'Email',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              validator: (v) => (v == null || !v.contains('@')) ? 'Enter a valid email' : null,
            ),
            const SizedBox(height: 12),
            _Field(
              controller: passwordCtrl,
              label: 'Password',
              icon: Icons.lock_outline,
              obscure: obscure,
              suffixIcon: IconButton(
                icon: Icon(obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20, color: Colors.grey),
                onPressed: onToggleObscure,
              ),
              validator: (v) => (v == null || v.length < 6) ? 'Min 6 characters' : null,
            ),
            const Spacer(),
            _SubmitButton(loading: loading, label: 'Create Account', onTap: onSubmit),
          ],
        ),
      ),
    );
  }
}

// ── Shared widgets ──────────────────────────────────────────────────────────

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscure;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final String? Function(String?)? validator;

  const _Field({
    required this.controller, required this.label, required this.icon,
    this.obscure = false, this.suffixIcon, this.keyboardType,
    this.textCapitalization = TextCapitalization.none, this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      validator: validator,
      style: const TextStyle(fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20, color: Colors.grey.shade500),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: const Color(0xFFF7F3E9),
        labelStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF1A535C), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFFF6B6B)),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}

class _GoogleButton extends StatelessWidget {
  final bool loading;
  final VoidCallback onTap;

  const _GoogleButton({required this.loading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: loading ? null : onTap,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          side: BorderSide(color: Colors.grey.shade300),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 22, height: 22,
              decoration: BoxDecoration(
                color: const Color(0xFF4285F4),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Center(
                child: Text('G', style: TextStyle(
                  color: Colors.white, fontSize: 14,
                  fontWeight: FontWeight.w800,
                )),
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Continue with Google',
              style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A2E),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SubmitButton extends StatelessWidget {
  final bool loading;
  final String label;
  final VoidCallback onTap;

  const _SubmitButton({required this.loading, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: loading ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1A535C),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: loading
            ? const SizedBox(
                width: 20, height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
      ),
    );
  }
}
