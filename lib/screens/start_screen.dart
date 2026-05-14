import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../theme/app_colors.dart';
import '../state/app_state.dart';
import 'login_screen.dart';
import 'main_shell.dart';

class StartScreen extends StatefulWidget {
  const StartScreen({super.key});

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen>
    with TickerProviderStateMixin {
  late AnimationController _mainCtrl;
  late AnimationController _wingCtrl;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;
  late Animation<Offset> _slideAnim;
  late Animation<double> _wingAnim;

  @override
  void initState() {
    super.initState();
    _mainCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _wingCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _fadeAnim = CurvedAnimation(
      parent: _mainCtrl,
      curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
    );
    _scaleAnim = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainCtrl,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _mainCtrl,
        curve: const Interval(0.3, 0.8, curve: Curves.easeOut),
      ),
    );
    _wingAnim = Tween<double>(begin: -0.08, end: 0.08).animate(
      CurvedAnimation(
        parent: _wingCtrl,
        curve: Curves.easeInOut,
      ),
    );

    _mainCtrl.forward();
  }

  @override
  void dispose() {
    _mainCtrl.dispose();
    _wingCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final double logoSize = (size.width * 0.5).clamp(160.0, 240.0);
    final double titleSize = (size.width * 0.1).clamp(32.0, 48.0);
    final double subtitleSize = (size.width * 0.06).clamp(20.0, 30.0);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: (size.width * 0.08).clamp(24.0, 60.0),
          ),
          child: Column(
            children: [
              SizedBox(height: size.height * 0.12),

              FadeTransition(
                opacity: _fadeAnim,
                child: ScaleTransition(
                  scale: _scaleAnim,
                  child: AnimatedBuilder(
                    animation: _wingAnim,
                    builder: (context, child) => Transform.rotate(
                      angle: _wingAnim.value,
                      child: child,
                    ),
                    child: SvgPicture.asset(
                      'assets/images/logoselfmade.svg',
                      height: logoSize,
                      width: logoSize,
                    ),
                  ),
                ),
              ),

              SizedBox(height: size.height * 0.04),

              // Welcome text
              SlideTransition(
                position: _slideAnim,
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: Column(
                    children: [
                      Text(
                        'WELCOME TO',
                        style: TextStyle(
                          fontSize: titleSize * 0.55,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark,
                          letterSpacing: 3,
                        ),
                      ),
                      Text(
                        'StudyHours',
                        style: TextStyle(
                          fontSize: subtitleSize,
                          fontWeight: FontWeight.w900,
                          color: AppColors.cardDark,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const Spacer(),

              // Get started button
              SlideTransition(
                position: _slideAnim,
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        final state = AppStateProvider.of(context);
                        final dest = state.firebaseUid != null
                            ? const MainShell()
                            : const LoginScreen();
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => dest),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.cardDark,
                        padding: EdgeInsets.symmetric(
                          vertical: (size.height * 0.022).clamp(14.0, 20.0),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 4,
                        shadowColor: AppColors.cardDark.withValues(alpha: 0.4),
                      ),
                      child: Text(
                        'Get Started',
                        style: TextStyle(
                          fontSize: (size.width * 0.05).clamp(16.0, 22.0),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              SizedBox(height: size.height * 0.06),
            ],
          ),
        ),
      ),
    );
  }
}
