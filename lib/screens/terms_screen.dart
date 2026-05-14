import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../widgets/shared_widgets.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar(context, 'TERMS OF USE'),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
          physics: const BouncingScrollPhysics(),
          children: const [
            _TermsSection(
              title: 'Acceptance',
              body:
                  'By creating an account and using StudyHours, you agree to these Terms of Use. '
                  'If you do not agree, please do not use the app.',
            ),
            _TermsSection(
              title: 'Who can use StudyHours',
              body: 'StudyHours is intended for users aged 13 and above. '
                  'In the EU/EEA the minimum age is 16 unless a parent or legal guardian provides consent. '
                  'By registering you confirm that you meet the applicable age requirement.',
            ),
            _TermsSection(
              title: 'Your account',
              body:
                  'You are responsible for keeping your login credentials secure. '
                  'Do not share your password with others. '
                  'You are responsible for all activity that occurs under your account.',
            ),
            _TermsSection(
              title: 'Acceptable use',
              body: 'StudyHours is a personal study-tracking tool. '
                  'You may not use the app to violate any applicable law, infringe third-party rights, '
                  'or attempt to reverse-engineer the service.',
            ),
            _TermsSection(
              title: 'Your data',
              body: 'You own the study data you enter into the app. '
                  'We process it solely to provide the service. '
                  'See our Privacy Policy for full details on data handling.',
            ),
            _TermsSection(
              title: 'Service availability',
              body:
                  'We aim to keep StudyHours available at all times, but we do not guarantee uninterrupted access. '
                  'The app is provided "as is" without warranty of any kind.',
            ),
            _TermsSection(
              title: 'Changes to these terms',
              body: 'We may update these terms from time to time. '
                  'Continued use of the app after changes constitutes acceptance of the updated terms. '
                  'We will notify you of significant changes.',
            ),
            _TermsSection(
              title: 'Governing law',
              body: 'These terms are governed by Norwegian law. '
                  'Any disputes shall be resolved in Norwegian courts.',
            ),
            _TermsSection(
              title: 'Contact',
              body:
                  'Questions about these terms? Contact us at victoriaskjstr@outlook.com.',
            ),
          ],
        ),
      ),
    );
  }
}

class _TermsSection extends StatelessWidget {
  final String title;
  final String body;

  const _TermsSection({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border:
              Border.all(color: Colors.white.withValues(alpha: 0.18), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: Ts.s(context, 15),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              body,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontWeight: FontWeight.w500,
                fontSize: Ts.s(context, 14),
                height: 1.55,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
