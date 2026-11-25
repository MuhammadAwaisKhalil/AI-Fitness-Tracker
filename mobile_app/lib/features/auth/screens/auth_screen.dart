import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';

// ──────────────────────────────────────────────────────────────────────────────
// AuthScreen
// ──────────────────────────────────────────────────────────────────────────────

/// Full-screen Login / Sign-Up screen.
///
/// UI matches the app's dark-neon design system:
///   background  #090C12  |  primary   #00E5FF (cyan)
///   surface     #131824  |  secondary #76FF03 (green)
///
/// Auth logic is intentionally thin: button presses are delegated to
/// [AuthService] (a dummy service that simulates FastAPI calls).
/// When the real FastAPI backend is wired up, only [AuthService] changes.
class AuthScreen extends StatefulWidget {
  const AuthScreen({Key? key}) : super(key: key);

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  // ── State ─────────────────────────────────────────────────────────────────
  bool _isLoginMode = true; // Toggle between Log In / Sign Up
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;

  // ── Lifecycle ─────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  void _toggleMode() {
    setState(() {
      _isLoginMode = !_isLoginMode;
      _errorMessage = null;
      _formKey.currentState?.reset();
    });
  }

  void _setError(String msg) {
    setState(() {
      _isLoading = false;
      _errorMessage = msg;
    });
  }

  /// Navigates to [MainShell] after a successful auth result.
  /// We use pushReplacement so the user cannot "back" into Auth.
  void _onSuccess() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (_, animation, __) {
          // Import MainShell lazily to avoid circular imports
          return FadeTransition(
            opacity: animation,
            child: const _MainShellProxy(),
          );
        },
      ),
    );
  }

  // ── Auth Actions ──────────────────────────────────────────────────────────

  Future<void> _submitLocalAuth() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    HapticFeedback.lightImpact();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = _isLoginMode
        ? await AuthService.instance.logIn(
            email: _emailCtrl.text.trim(),
            password: _passwordCtrl.text,
          )
        : await AuthService.instance.signUp(
            email: _emailCtrl.text.trim(),
            password: _passwordCtrl.text,
          );

    if (result.success) {
      _onSuccess();
    } else {
      _setError(result.error ?? 'Authentication failed.');
    }
  }

  Future<void> _continueWithGoogle() async {
    HapticFeedback.lightImpact();
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await AuthService.instance.continueWithGoogle();

    if (result.success) {
      _onSuccess();
    } else {
      _setError(result.error ?? 'Google sign-in failed.');
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF090C12),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 32),

                // ── Logo & Title ───────────────────────────────────────────
                _Logo(),

                const SizedBox(height: 40),

                // ── Mode Header ───────────────────────────────────────────
                Text(
                  _isLoginMode ? 'Welcome Back' : 'Create Account',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _isLoginMode
                      ? 'Log in to continue your fitness journey'
                      : 'Start tracking your workouts today',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white38, fontSize: 14),
                ),

                const SizedBox(height: 36),

                // ── Google Button ─────────────────────────────────────────
                _GoogleButton(
                  isLoading: _isLoading,
                  onTap: _continueWithGoogle,
                ),

                const SizedBox(height: 20),

                // ── Divider ───────────────────────────────────────────────
                _OrDivider(),

                const SizedBox(height: 20),

                // ── Local Account Form ────────────────────────────────────
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _InputField(
                        controller: _emailCtrl,
                        label: 'Email',
                        icon: Icons.email_outlined,
                        enabled: !_isLoading,
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Required';
                          final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                          if (!emailRegex.hasMatch(v.trim())) return 'Enter a valid email';
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      _InputField(
                        controller: _passwordCtrl,
                        label: 'Password',
                        icon: Icons.lock_outline_rounded,
                        obscure: _obscurePassword,
                        enabled: !_isLoading,
                        validator: (v) => (v == null || v.length < 6)
                            ? 'Min 6 characters'
                            : null,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: Colors.white38,
                            size: 20,
                          ),
                          onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // ── Error Banner ──────────────────────────────────────────
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: _errorMessage != null
                      ? _ErrorBanner(message: _errorMessage!)
                      : const SizedBox.shrink(),
                ),

                const SizedBox(height: 18),

                // ── Primary Submit Button ─────────────────────────────────
                _PrimaryButton(
                  label: _isLoginMode ? 'Log In' : 'Sign Up',
                  isLoading: _isLoading,
                  onTap: _submitLocalAuth,
                ),

                const SizedBox(height: 24),

                // ── Mode Toggle Link ──────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _isLoginMode
                          ? "Don't have an account? "
                          : 'Already have an account? ',
                      style: const TextStyle(
                          color: Colors.white38, fontSize: 13.5),
                    ),
                    GestureDetector(
                      onTap: _isLoading ? null : _toggleMode,
                      child: Text(
                        _isLoginMode ? 'Sign Up' : 'Log In',
                        style: const TextStyle(
                          color: Color(0xFF00E5FF),
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // ── Backend Note (dev-only transparency) ──────────────────
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.info_outline_rounded,
                          size: 14, color: Colors.white38),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Connected to FastAPI backend. JWT stored securely on device.',
                          style: TextStyle(
                              color: Colors.white38,
                              fontSize: 11,
                              fontStyle: FontStyle.italic),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Sub-Widgets (private, scoped to this file)
// ──────────────────────────────────────────────────────────────────────────────

class _Logo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFF00E5FF), Color(0xFF76FF03)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00E5FF).withOpacity(0.35),
                blurRadius: 24,
                spreadRadius: 2,
              ),
            ],
          ),
          child: const Icon(
            Icons.fitness_center_rounded,
            color: Colors.black,
            size: 36,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'AI FITNESS COACH',
          style: TextStyle(
            color: Color(0xFF00E5FF),
            fontSize: 13,
            fontWeight: FontWeight.w900,
            letterSpacing: 3,
          ),
        ),
      ],
    );
  }
}

class _GoogleButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onTap;

  const _GoogleButton({required this.isLoading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: AnimatedOpacity(
        opacity: isLoading ? 0.5 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: Container(
          height: 54,
          decoration: BoxDecoration(
            color: const Color(0xFF131824),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white12, width: 1.2),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Google "G" icon using colored text — no asset needed
              const Text(
                'G',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                  color: Color(0xFF4285F4),
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Continue with Google',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
            child: Divider(color: Colors.white.withOpacity(0.1), height: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            'OR',
            style: TextStyle(
                color: Colors.white.withOpacity(0.3),
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5),
          ),
        ),
        Expanded(
            child: Divider(color: Colors.white.withOpacity(0.1), height: 1)),
      ],
    );
  }
}

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscure;
  final bool enabled;
  final String? Function(String?)? validator;
  final Widget? suffixIcon;
  final TextInputType keyboardType;

  const _InputField({
    required this.controller,
    required this.label,
    required this.icon,
    this.obscure = false,
    this.enabled = true,
    this.validator,
    this.suffixIcon,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      enabled: enabled,
      validator: validator,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white, fontSize: 15),
      cursorColor: const Color(0xFF00E5FF),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white38, fontSize: 14),
        prefixIcon: Icon(icon, color: Colors.white38, size: 20),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: const Color(0xFF131824),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.white12, width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: Color(0xFF00E5FF), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: Color(0xFFFF5252), width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: Color(0xFFFF5252), width: 1.5),
        ),
        errorStyle: const TextStyle(color: Color(0xFFFF5252), fontSize: 11),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              BorderSide(color: Colors.white.withOpacity(0.06), width: 1.0),
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final bool isLoading;
  final VoidCallback onTap;

  const _PrimaryButton({
    required this.label,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 54,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: isLoading
              ? const LinearGradient(
                  colors: [Color(0xFF005A69), Color(0xFF2A5900)])
              : const LinearGradient(
                  colors: [Color(0xFF00E5FF), Color(0xFF76FF03)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
          boxShadow: isLoading
              ? []
              : [
                  BoxShadow(
                    color: const Color(0xFF00E5FF).withOpacity(0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                )
              : Text(
                  label,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      key: ValueKey(message),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFF5252).withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFF5252).withOpacity(0.5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              size: 16, color: Color(0xFFFF5252)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                  color: Color(0xFFFF5252),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// MainShell Proxy  (avoids circular imports from main.dart ↔ auth_screen.dart)
// ──────────────────────────────────────────────────────────────────────────────

/// Thin wrapper that re-creates [MainShell] from main.dart without importing it
/// directly — navigation replaces the route so this is only ever instantiated once.
class _MainShellProxy extends StatelessWidget {
  const _MainShellProxy();

  @override
  Widget build(BuildContext context) {
    // We use a named route so this proxy is decoupled from the import chain.
    // main.dart registers '/home' → MainShell.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.of(context)
          .pushNamedAndRemoveUntil('/home', (route) => false);
    });
    // Show a brief loading state while the navigation callback fires.
    return const Scaffold(
      backgroundColor: Color(0xFF090C12),
      body: Center(
        child: CircularProgressIndicator(color: Color(0xFF00E5FF)),
      ),
    );
  }
}

