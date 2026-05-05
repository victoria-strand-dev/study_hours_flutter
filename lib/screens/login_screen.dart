import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../theme/app_colors.dart';
import '../state/app_state.dart';
import 'main_shell.dart';
import 'privacy_screen.dart';
import 'settings_screen.dart';

// ─── LOGIN SCREEN ─────────────────────────────────────────────────────────────

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;
    if (email.isEmpty || password.isEmpty) {
      _showError('Please enter email and password');
      return;
    }
    setState(() => _loading = true);
    try {
      final cred = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);
      if (!mounted) return;
      await AppStateProvider.of(context)
          .setFirebaseUser(cred.user!.uid, email);
      if (!mounted) return;
      // Existing login → go straight to app
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const MainShell()));
    } on FirebaseAuthException catch (e) {
      _showError(_authMessage(e.code));
    } catch (_) {
      _showError('Login failed — please try again');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.redAccent));
  }

  Future<void> _forgotPassword() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      _showError('Enter your email above first');
      return;
    }
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Password reset email sent'),
        backgroundColor: Color(0xFF2ECC71),
      ));
    } on FirebaseAuthException catch (e) {
      _showError(_authMessage(e.code));
    }
  }

  String _authMessage(String code) {
    switch (code) {
      case 'user-not-found': return 'No account with that email';
      case 'wrong-password': return 'Wrong password';
      case 'invalid-credential': return 'Invalid email or password';
      case 'too-many-requests': return 'Too many attempts — try again later';
      default: return 'Login failed ($code)';
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final double hPad = (size.width * 0.08).clamp(24.0, 56.0);
    final double logoH = (size.width * 0.28).clamp(90.0, 140.0);
    final double titleSize = (size.width * 0.085).clamp(28.0, 42.0);
    final double btnFontSize = (size.width * 0.048).clamp(16.0, 22.0);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 16),
          child: Column(
            children: [
              SizedBox(height: size.height * 0.04),

              SvgPicture.asset(
                'assets/images/logoselfmade.svg',
                height: logoH,
              ),

              SizedBox(height: size.height * 0.02),

              Text(
                'LOGIN',
                style: TextStyle(
                  fontSize: titleSize,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textDark,
                  letterSpacing: 2,
                ),
              ),

              SizedBox(height: size.height * 0.04),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.18), width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.cardDark.withValues(alpha: 0.15),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _LoginField(
                      controller: _emailCtrl,
                      hint: 'Email',
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 10),
                    _LoginField(
                      controller: _passwordCtrl,
                      hint: 'Password',
                      obscure: _obscure,
                      suffix: IconButton(
                        icon: Icon(
                          _obscure ? Icons.visibility_off : Icons.visibility,
                          color: AppColors.textDark,
                          size: 20,
                        ),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _forgotPassword,
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'Forgot password?',
                          style: TextStyle(
                            color: AppColors.textDark.withValues(alpha: 0.7),
                            fontSize: (size.width * 0.035).clamp(12.0, 15.0),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.cardDark,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: _loading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : Text(
                                'LOGIN',
                                style: TextStyle(
                                  fontSize: btnFontSize,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.5,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: size.height * 0.025),

              Text(
                'OR',
                style: TextStyle(
                  fontSize: (size.width * 0.06).clamp(18.0, 26.0),
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                  letterSpacing: 2,
                ),
              ),

              SizedBox(height: size.height * 0.02),

              OutlinedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RegisterScreen()),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textDark,
                  side: const BorderSide(color: AppColors.cardDark, width: 2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: size.width * 0.12,
                    vertical: 12,
                  ),
                ),
                child: Text(
                  'REGISTER',
                  style: TextStyle(
                    fontSize: btnFontSize,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                  ),
                ),
              ),

              SizedBox(height: size.height * 0.02),

              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PrivacyScreen()),
                ),
                child: Text(
                  'Privacy Policy',
                  style: TextStyle(
                    color: AppColors.textDark.withValues(alpha: 0.6),
                    fontSize: (size.width * 0.033).clamp(11.0, 14.0),
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),

              SizedBox(height: size.height * 0.02),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── LOGIN FIELD ──────────────────────────────────────────────────────────────

class _LoginField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool obscure;
  final TextInputType keyboardType;
  final Widget? suffix;

  const _LoginField({
    required this.controller,
    required this.hint,
    this.obscure = false,
    this.keyboardType = TextInputType.text,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18), width: 1),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: AppColors.textDark,
          fontWeight: FontWeight.w600,
          fontSize: (size.width * 0.04).clamp(14.0, 18.0),
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hint,
          hintStyle: TextStyle(
            color: AppColors.textDark.withValues(alpha: 0.4),
            fontSize: (size.width * 0.04).clamp(14.0, 18.0),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          suffixIcon: suffix,
        ),
      ),
    );
  }
}

// ─── REGISTER SCREEN ──────────────────────────────────────────────────────────

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  bool _consented = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;
    final confirm = _confirmCtrl.text;

    if (email.isEmpty || password.isEmpty) {
      _showError('Please enter email and password');
      return;
    }
    if (password != confirm) {
      _showError('Passwords do not match');
      return;
    }
    if (password.length < 6) {
      _showError('Password must be at least 6 characters');
      return;
    }
    if (!_consented) {
      _showError('You must accept the Privacy Policy to register');
      return;
    }

    setState(() => _loading = true);
    try {
      final cred = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);
      if (!mounted) return;
      await AppStateProvider.of(context)
          .setFirebaseUser(cred.user!.uid, email);
      if (!mounted) return;
      Navigator.pushReplacement(
          context, MaterialPageRoute(
              builder: (_) => const SettingsScreen(firstTime: true)));
    } on FirebaseAuthException catch (e) {
      _showError(_authMessage(e.code));
    } catch (_) {
      _showError('Registration failed — please try again');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.redAccent));
  }

  String _authMessage(String code) {
    switch (code) {
      case 'email-already-in-use': return 'An account already exists with that email';
      case 'invalid-email': return 'Invalid email address';
      case 'weak-password': return 'Password is too weak';
      default: return 'Registration failed ($code)';
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final double hPad = (size.width * 0.08).clamp(24.0, 56.0);
    final double logoH = (size.width * 0.25).clamp(80.0, 120.0);
    final double titleSize = (size.width * 0.085).clamp(28.0, 42.0);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 16),
          child: Column(
            children: [
              SizedBox(height: size.height * 0.03),
              SvgPicture.asset('assets/images/logoselfmade.svg', height: logoH),
              SizedBox(height: size.height * 0.015),
              Text(
                'REGISTER',
                style: TextStyle(
                  fontSize: titleSize,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textDark,
                  letterSpacing: 2,
                ),
              ),
              SizedBox(height: size.height * 0.03),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.18), width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.cardDark.withValues(alpha: 0.15),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _LoginField(
                      controller: _emailCtrl,
                      hint: 'Email',
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 10),
                    _LoginField(
                      controller: _passwordCtrl,
                      hint: 'Password',
                      obscure: _obscure,
                      suffix: IconButton(
                        icon: Icon(
                          _obscure ? Icons.visibility_off : Icons.visibility,
                          color: AppColors.textDark,
                          size: 20,
                        ),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _LoginField(
                      controller: _confirmCtrl,
                      hint: 'Confirm Password',
                      obscure: true,
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () => setState(() => _consented = !_consented),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 22,
                            height: 22,
                            child: Checkbox(
                              value: _consented,
                              onChanged: (v) =>
                                  setState(() => _consented = v ?? false),
                              activeColor: AppColors.cardDark,
                              checkColor: Colors.white,
                              side: const BorderSide(
                                  color: AppColors.textDark, width: 1.5),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4)),
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const PrivacyScreen()),
                              ),
                              child: RichText(
                                text: TextSpan(
                                  style: TextStyle(
                                    color: AppColors.textDark
                                        .withValues(alpha: 0.85),
                                    fontSize:
                                        (size.width * 0.033).clamp(11.0, 14.0),
                                    fontWeight: FontWeight.w500,
                                  ),
                                  children: const [
                                    TextSpan(text: 'I accept the '),
                                    TextSpan(
                                      text: 'Privacy Policy',
                                      style: TextStyle(
                                        decoration: TextDecoration.underline,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    TextSpan(
                                        text:
                                            ' and consent to the processing of my personal data.'),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _register,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: _loading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : Text(
                                'REGISTER',
                                style: TextStyle(
                                  fontSize: (size.width * 0.048).clamp(16.0, 22.0),
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.5,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: size.height * 0.025),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Already have an account? Login',
                  style: TextStyle(
                    color: AppColors.textDark,
                    fontWeight: FontWeight.w600,
                    fontSize: (size.width * 0.038).clamp(13.0, 17.0),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
