import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../state/app_state.dart';
import '../widgets/shared_widgets.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  Future<void> _exportData(BuildContext context, AppState state) async {
    final export = {
      'exportedAt': DateTime.now().toIso8601String(),
      'email': state.userEmail,
      'data': state.data.toJson(),
    };
    final json = const JsonEncoder.withIndent('  ').convert(export);
    await Clipboard.setData(ClipboardData(text: json));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your data has been copied to the clipboard as JSON'),
          backgroundColor: Color(0xFF2ECC71),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStateProvider.of(context);

    return Scaffold(
      appBar: buildAppBar(context, 'PRIVACY POLICY'),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
          physics: const BouncingScrollPhysics(),
          children: [
            const _Section(
              icon: Icons.business_outlined,
              title: 'Data controller',
              items: [
                'Data controller: StudyHours App — contact: victoriaskjstr@outlook.com',
                'This app complies with the General Data Protection Regulation (GDPR) and the Norwegian Personal Data Act (personopplysningsloven).',
                'This app is not intended for users under 13 years of age. In the EU, the minimum age is 16 unless parental consent is provided.',
              ],
            ),

            const _Section(
              icon: Icons.track_changes_outlined,
              title: 'Purpose of data processing',
              items: [
                'We process your data only to provide core app functionality: study tracking, scheduling, and progress calculation.',
                'Your data is never used for advertising, profiling, or sold to third parties.',
              ],
            ),

            const _Section(
              icon: Icons.inventory_2_outlined,
              title: 'What data we collect',
              items: [
                'Email address — used to identify your account. Never shared with third parties.',
                'Password — stored as a secure hash by Firebase Authentication. We never see your plain-text password.',
                'Study data — your courses, schedule entries, and semester settings. This is the core content of the app.',
                'We collect nothing else. No location, no contacts, no analytics, no advertising identifiers.',
              ],
            ),

            const _Section(
              icon: Icons.gavel_outlined,
              title: 'Legal basis (GDPR Art. 6)',
              items: [
                'We process your data on the basis of your explicit consent (Art. 6(1)(a)), given when you register an account.',
                'You may withdraw consent at any time by deleting your account (Profile → Delete Account).',
              ],
            ),

            const _Section(
              icon: Icons.cloud_outlined,
              title: 'Where data is stored',
              items: [
                'Data is stored using Google Firebase (Firestore and Authentication). Google may process data outside the EU/EEA in accordance with GDPR safeguards (Standard Contractual Clauses).',
                'A local cache is kept on your device so the app works offline. It is cleared when you log out or delete your account.',
                'Firestore security rules ensure only you — authenticated with your unique user ID — can read or write your data.',
              ],
            ),

            const _Section(
              icon: Icons.lock_outline_rounded,
              title: 'Security measures',
              items: [
                'We use industry-standard security measures including encrypted authentication (Firebase Auth) and server-side access control (Firestore security rules).',
                'Passwords are never stored in plain text — Firebase Authentication uses secure hashing.',
                'Only authenticated users can access their own data. No one else — including the developer — can read your data.',
              ],
            ),

            const _Section(
              icon: Icons.timer_outlined,
              title: 'Data retention',
              items: [
                'Your data is retained for as long as you have an active account.',
                'When you delete your account, all Firestore data is permanently deleted immediately. Local device data is cleared at the same time.',
                'No backups of your personal data are kept beyond Firebase\'s standard infrastructure.',
              ],
            ),

            const _Section(
              icon: Icons.shield_outlined,
              title: 'Your rights (GDPR Art. 15–21)',
              items: [
                'Right to access (Art. 15) — view all your data in the app at any time.',
                'Right to portability (Art. 20) — export all your data as JSON (see button below).',
                'Right to erasure (Art. 17) — delete your account to permanently erase all data.',
                'Right to rectification (Art. 16) — edit your courses, schedule, and settings directly in the app.',
                'Right to withdraw consent — delete your account at any time. This immediately stops all processing.',
                'To exercise any other right or file a complaint, contact victoriaskjstr@outlook.com or the Norwegian Data Protection Authority (Datatilsynet, datatilsynet.no).',
              ],
            ),

            const _Section(
              icon: Icons.notifications_outlined,
              title: 'Notifications',
              items: [
                'Push notifications are generated entirely on your device. No data is sent to external servers for this purpose.',
                'You can disable notifications at any time in your device settings.',
              ],
            ),

            const SizedBox(height: 4),

            // ── Export data ───────────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _exportData(context, state),
                icon: const Icon(Icons.download_rounded, size: 18),
                label: const Text(
                  'Export my data (copy JSON)',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.cardDark,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<String> items;

  const _Section({
    required this.icon,
    required this.title,
    required this.items,
  });

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
            Row(
              children: [
                Icon(icon, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: Ts.s(context, 15),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ...items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 7),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 6, right: 8),
                        child: Container(
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.5),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          item,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontWeight: FontWeight.w500,
                            fontSize: Ts.s(context, 13.5),
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}
