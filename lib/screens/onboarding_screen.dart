import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../state/app_state.dart';
import '../services/storage_service.dart';
import '../widgets/shared_widgets.dart';
import 'main_shell.dart';

// ── Entry point ───────────────────────────────────────────────────────────────
// Call this instead of MainShell when onboarding hasn't been completed yet.

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageCtrl = PageController();
  int _page = 0;

  // Semester setup state (page 2)
  final _creditsCtrl = TextEditingController(text: '30');
  final _weeksCtrl   = TextEditingController(text: '15');
  DateTime? _startDate;

  static const int _totalPages = 4;

  @override
  void dispose() {
    _pageCtrl.dispose();
    _creditsCtrl.dispose();
    _weeksCtrl.dispose();
    super.dispose();
  }

  void _next() {
    if (_page < _totalPages - 1) {
      _pageCtrl.nextPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeInOut,
      );
    } else {
      _finish();
    }
  }

  void _skip() => _finish();

  Future<void> _finish() async {
    // Save semester settings if user filled them in
    final state   = AppStateProvider.of(context);
    final credits = int.tryParse(_creditsCtrl.text.trim()) ?? 30;
    final weeks   = int.tryParse(_weeksCtrl.text.trim()) ?? 15;
    await state.updateSemesterSettings(credits, weeks, _startDate);
    await StorageService.instance.setOnboardingDone();

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const MainShell()),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.cardDark,
            surface: AppColors.card,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _startDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // ── Top bar: Skip + progress dots ─────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // HIG: always provide an escape — Skip is always visible
                  TextButton(
                    onPressed: _skip,
                    child: Text(
                      'Skip',
                      style: GoogleFonts.nunito(
                        color: AppColors.textDark.withValues(alpha: 0.5),
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  Row(
                    children: List.generate(_totalPages, (i) {
                      final active = i == _page;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: active ? 20 : 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: active
                              ? AppColors.cardDark
                              : Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                  // Placeholder to balance the row
                  const SizedBox(width: 56),
                ],
              ),
            ),

            // ── Pages ─────────────────────────────────────────────────────
            Expanded(
              child: PageView(
                controller: _pageCtrl,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _page = i),
                children: [
                  _WelcomePage(size: size),
                  _SemesterPage(
                    size: size,
                    creditsCtrl: _creditsCtrl,
                    weeksCtrl: _weeksCtrl,
                    startDate: _startDate,
                    onPickDate: _pickDate,
                    onClearDate: () => setState(() => _startDate = null),
                  ),
                  _HowItWorksPage(size: size),
                  _ReadyPage(size: size),
                ],
              ),
            ),

            // ── Primary CTA ────────────────────────────────────────────────
            // HIG: one clear primary action per screen
            Padding(
              padding: EdgeInsets.fromLTRB(
                  24, 12, 24, MediaQuery.of(context).padding.bottom + 20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _next,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.cardDark,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: Text(
                    _page == _totalPages - 1 ? "Let's go!" : 'Continue',
                    style: GoogleFonts.nunito(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Page 1: Welcome ───────────────────────────────────────────────────────────

class _WelcomePage extends StatelessWidget {
  final Size size;
  const _WelcomePage({required this.size});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          SizedBox(height: size.height * 0.07),
          SvgPicture.asset(
            'assets/images/logoselfmade.svg',
            height: (size.width * 0.45).clamp(140.0, 200.0),
          ),
          SizedBox(height: size.height * 0.05),
          Text(
            'Welcome to\nStudyHours',
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              fontSize: (size.width * 0.075).clamp(26.0, 36.0),
              fontWeight: FontWeight.w900,
              color: AppColors.textDark,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Plan your semester, track your study sessions, and always know exactly how many hours you need to hit your target grade.',
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              fontSize: (size.width * 0.040).clamp(14.0, 17.0),
              fontWeight: FontWeight.w500,
              color: AppColors.textDark.withValues(alpha: 0.65),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Page 2: Semester setup ────────────────────────────────────────────────────

class _SemesterPage extends StatelessWidget {
  final Size size;
  final TextEditingController creditsCtrl;
  final TextEditingController weeksCtrl;
  final DateTime? startDate;
  final VoidCallback onPickDate;
  final VoidCallback onClearDate;

  const _SemesterPage({
    required this.size,
    required this.creditsCtrl,
    required this.weeksCtrl,
    required this.startDate,
    required this.onPickDate,
    required this.onClearDate,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 32, 28, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon + header
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.cardDark,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.school_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 20),
          Text(
            'Set up your semester',
            style: GoogleFonts.nunito(
              fontSize: (size.width * 0.065).clamp(22.0, 30.0),
              fontWeight: FontWeight.w900,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This lets the app calculate how many hours per week you need to study. You can change this anytime.',
            style: GoogleFonts.nunito(
              fontSize: (size.width * 0.038).clamp(13.0, 16.0),
              fontWeight: FontWeight.w500,
              color: AppColors.textDark.withValues(alpha: 0.6),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 28),

          // Fields in a card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.cardBorder, width: 1),
              boxShadow: [
                BoxShadow(
                  color: AppColors.textDark.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: StyledInput(
                        label: 'Total Credits',
                        controller: creditsCtrl,
                        keyboardType: const TextInputType.numberWithOptions(),
                        hint: 'e.g. 30',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: StyledInput(
                        label: 'Semester Weeks',
                        controller: weeksCtrl,
                        keyboardType: const TextInputType.numberWithOptions(),
                        hint: 'e.g. 15',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: onPickDate,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.inputBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.18), width: 1),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today_rounded,
                            color: AppColors.textDark.withValues(alpha: 0.5),
                            size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Semester start date',
                                style: GoogleFonts.nunito(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  fontSize: Ts.s(context, 13),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                startDate != null
                                    ? DateFormat('d MMM yyyy').format(startDate!)
                                    : 'Tap to set (optional)',
                                style: GoogleFonts.nunito(
                                  color: startDate != null
                                      ? Colors.white
                                      : Colors.white.withValues(alpha: 0.45),
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (startDate != null)
                          GestureDetector(
                            onTap: onClearDate,
                            child: const Icon(Icons.close_rounded,
                                color: Colors.white60, size: 18),
                          )
                        else
                          const Icon(Icons.chevron_right_rounded,
                              color: Colors.white38, size: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Page 3: How it works ──────────────────────────────────────────────────────

class _HowItWorksPage extends StatelessWidget {
  final Size size;
  const _HowItWorksPage({required this.size});

  @override
  Widget build(BuildContext context) {
    const steps = [
      (Icons.add_circle_outline_rounded, 'Add your courses',
          'Enter each subject with credits and target grade.'),
      (Icons.schedule_rounded, 'Generate your schedule',
          'The app calculates exactly how many hours per week you need.'),
      (Icons.check_circle_outline_rounded, 'Track your sessions',
          'Tick off sessions as you complete them — watch your progress grow.'),
      (Icons.bar_chart_rounded, 'Stay on top',
          'Statistics show streaks, time per course, and goal progress.'),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 32, 28, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How it works',
            style: GoogleFonts.nunito(
              fontSize: (size.width * 0.065).clamp(22.0, 30.0),
              fontWeight: FontWeight.w900,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Four simple steps to a better semester.',
            style: GoogleFonts.nunito(
              fontSize: (size.width * 0.038).clamp(13.0, 16.0),
              fontWeight: FontWeight.w500,
              color: AppColors.textDark.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 24),
          ...steps.asMap().entries.map((e) {
            final i    = e.key;
            final step = e.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.cardDark,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Icon(step.$1, color: Colors.white, size: 22),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${i + 1}. ${step.$2}',
                          style: GoogleFonts.nunito(
                            fontSize: (size.width * 0.040).clamp(14.0, 17.0),
                            fontWeight: FontWeight.w800,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          step.$3,
                          style: GoogleFonts.nunito(
                            fontSize: (size.width * 0.035).clamp(12.0, 15.0),
                            fontWeight: FontWeight.w500,
                            color: AppColors.textDark.withValues(alpha: 0.6),
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ── Page 4: Ready ─────────────────────────────────────────────────────────────

class _ReadyPage extends StatelessWidget {
  final Size size;
  const _ReadyPage({required this.size});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: const BoxDecoration(
              color: AppColors.cardDark,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.rocket_launch_rounded,
                color: Colors.white, size: 44),
          ),
          SizedBox(height: size.height * 0.04),
          Text(
            "You're all set!",
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              fontSize: (size.width * 0.072).clamp(24.0, 34.0),
              fontWeight: FontWeight.w900,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Start by adding your courses, then generate a study schedule. You can always adjust things in the Semester settings.',
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              fontSize: (size.width * 0.038).clamp(13.0, 16.0),
              fontWeight: FontWeight.w500,
              color: AppColors.textDark.withValues(alpha: 0.6),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
