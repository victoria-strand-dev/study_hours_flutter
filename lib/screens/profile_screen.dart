import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../state/app_state.dart';
import '../widgets/shared_widgets.dart';
import 'start_screen.dart';
import 'privacy_screen.dart';
import 'terms_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.redAccent : const Color(0xFF2ECC71),
    ));
  }

  Future<void> _showChangePasswordDialog() async {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    bool obscureCurrent = true;
    bool obscureNew = true;
    bool obscureConfirm = true;
    bool loading = false;

    Widget toggle(bool obs, VoidCallback onTap) => GestureDetector(
          onTap: onTap,
          child: Icon(obs ? Icons.visibility_off : Icons.visibility,
              color: Colors.white54, size: 20),
        );

    await showDialog(
      context: context,
      barrierDismissible: !loading,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          backgroundColor: AppColors.bg,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Change Password',
              style: TextStyle(
                  color: AppColors.textDark, fontWeight: FontWeight.w800)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                StyledInput(
                  label: 'Current password',
                  controller: currentCtrl,
                  obscure: obscureCurrent,
                  suffix: toggle(obscureCurrent,
                      () => setSt(() => obscureCurrent = !obscureCurrent)),
                ),
                const SizedBox(height: 10),
                StyledInput(
                  label: 'New password',
                  controller: newCtrl,
                  obscure: obscureNew,
                  suffix: toggle(
                      obscureNew, () => setSt(() => obscureNew = !obscureNew)),
                ),
                const SizedBox(height: 10),
                StyledInput(
                  label: 'Confirm new password',
                  controller: confirmCtrl,
                  obscure: obscureConfirm,
                  suffix: toggle(obscureConfirm,
                      () => setSt(() => obscureConfirm = !obscureConfirm)),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: loading ? null : () => Navigator.pop(ctx),
                child: const Text('Cancel',
                    style: TextStyle(
                        color: AppColors.textDark,
                        fontWeight: FontWeight.w600))),
            ElevatedButton(
              onPressed: loading
                  ? null
                  : () async {
                      final current = currentCtrl.text;
                      final newPw = newCtrl.text;
                      final confirm = confirmCtrl.text;
                      if (current.isEmpty || newPw.isEmpty || confirm.isEmpty) {
                        _showSnack('Please fill in all fields', isError: true);
                        return;
                      }
                      if (newPw != confirm) {
                        _showSnack('New passwords do not match', isError: true);
                        return;
                      }
                      if (newPw.length < 6) {
                        _showSnack('Password must be at least 6 characters',
                            isError: true);
                        return;
                      }
                      setSt(() => loading = true);
                      try {
                        final user = FirebaseAuth.instance.currentUser;
                        if (user == null || user.email == null) return;
                        final cred = EmailAuthProvider.credential(
                            email: user.email!, password: current);
                        await user.reauthenticateWithCredential(cred);
                        await user.updatePassword(newPw);
                        if (ctx.mounted) Navigator.pop(ctx);
                        _showSnack('Password updated!');
                      } on FirebaseAuthException catch (e) {
                        setSt(() => loading = false);
                        _showSnack(
                          e.code == 'wrong-password' ||
                                  e.code == 'invalid-credential'
                              ? 'Current password is incorrect'
                              : e.code == 'too-many-requests'
                                  ? 'Too many attempts — try again later'
                                  : 'Failed to update password (${e.code})',
                          isError: true,
                        );
                      }
                    },
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.cardDark,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10))),
              child: loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('Update',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );

    currentCtrl.dispose();
    newCtrl.dispose();
    confirmCtrl.dispose();
  }

  Future<void> _deleteAccount() async {
    final warnConfirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Delete Account',
            style: TextStyle(
                color: Color(0xFFC0392B), fontWeight: FontWeight.w800)),
        content: const Text(
          'This will permanently delete your account and all study data. This cannot be undone.',
          style: TextStyle(color: AppColors.textDark),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel',
                  style: TextStyle(
                      color: AppColors.textDark, fontWeight: FontWeight.w600))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC0392B),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
            child: const Text('Continue',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (warnConfirmed != true || !mounted) return;

    final passwordCtrl = TextEditingController();
    bool obscure = true;
    final reauthed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          backgroundColor: AppColors.bg,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: const Text('Confirm your password',
              style: TextStyle(
                  color: AppColors.textDark, fontWeight: FontWeight.w800)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Enter your current password to confirm account deletion.',
                style: TextStyle(color: AppColors.textDark),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: passwordCtrl,
                obscureText: obscure,
                style: const TextStyle(
                    color: AppColors.textDark, fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  labelText: 'Password',
                  labelStyle: const TextStyle(color: AppColors.textDark),
                  filled: true,
                  fillColor: AppColors.card,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none),
                  suffixIcon: GestureDetector(
                    onTap: () => setState(() => obscure = !obscure),
                    child: Icon(
                        obscure ? Icons.visibility_off : Icons.visibility,
                        color: Colors.white54,
                        size: 20),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel',
                    style: TextStyle(
                        color: AppColors.textDark,
                        fontWeight: FontWeight.w600))),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC0392B),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10))),
              child: const Text('Delete Account',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
    if (reauthed != true || !mounted) return;

    final appState = AppStateProvider.of(context);

    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || user.email == null) {
        if (mounted) Navigator.pop(context);
        _showSnack('Not logged in', isError: true);
        return;
      }

      final cred = EmailAuthProvider.credential(
          email: user.email!, password: passwordCtrl.text);
      await user.reauthenticateWithCredential(cred);
      await appState.deleteFirestoreData();
      await user.delete();
      await appState.clearLocalAfterDelete();

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const StartScreen()),
          (route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) Navigator.pop(context);
      String msg;
      switch (e.code) {
        case 'wrong-password':
        case 'invalid-credential':
          msg = 'Incorrect password';
          break;
        case 'too-many-requests':
          msg = 'Too many attempts — try again later';
          break;
        default:
          msg = 'Failed to delete account (${e.code})';
      }
      _showSnack(msg, isError: true);
    } catch (e) {
      if (mounted) Navigator.pop(context);
      _showSnack('Delete failed: $e', isError: true);
    } finally {
      passwordCtrl.dispose();
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Log out',
            style: TextStyle(
                color: AppColors.textDark, fontWeight: FontWeight.w800)),
        content: const Text('Are you sure you want to log out?',
            style: TextStyle(color: AppColors.textDark)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel',
                  style: TextStyle(
                      color: AppColors.textDark, fontWeight: FontWeight.w600))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC0392B),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
            child: const Text('Log out',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await AppStateProvider.of(context).logout();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const StartScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStateProvider.of(context);

    return Scaffold(
      appBar: buildAppBar(context, 'PROFILE'),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
          physics: const BouncingScrollPhysics(),
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.18), width: 1),
              ),
              child: Column(
                children: [
                  Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      color: AppColors.cardDark,
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.18),
                          width: 1),
                    ),
                    child: const Icon(Icons.person_rounded,
                        color: Colors.white, size: 36),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    state.userEmail ?? '',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.80),
                      fontWeight: FontWeight.w600,
                      fontSize: Ts.s(context, 15),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            //<3<3<3<3<3<3 Account settings <3<3<3<3<3<3
            const _SectionLabel(label: 'ACCOUNT'),
            _SettingsGroup(children: [
              _SettingsRow(
                icon: Icons.lock_outline_rounded,
                label: 'Change Password',
                onTap: _showChangePasswordDialog,
              ),
            ]),

            const SizedBox(height: 20),

            //<3<3<3<3<3<3<3<3 polycies <3<3<3<3<3<3<3<3<3
            const _SectionLabel(label: 'LEGAL'),
            _SettingsGroup(children: [
              _SettingsRow(
                icon: Icons.privacy_tip_outlined,
                label: 'Privacy Policy',
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const PrivacyScreen())),
              ),
              const _Divider(),
              _SettingsRow(
                icon: Icons.description_outlined,
                label: 'Terms of Use',
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const TermsScreen())),
              ),
            ]),

            const SizedBox(height: 28),

            //<3<3<3<3<3<3<3<3<3 logout <3<3<3<3<3<3<3<3<3
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _logout,
                icon: const Icon(Icons.logout_rounded, size: 18),
                label: const Text('Log out',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.card,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
              ),
            ),

            const SizedBox(height: 10),

            //<3<3<3<3<3 Delete account <3<3<3<3<3<3
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _deleteAccount,
                icon: const Icon(Icons.delete_forever_rounded,
                    color: Colors.white, size: 18),
                label: const Text('Delete Account',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC0392B),
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


class _SectionLabel extends StatelessWidget {
  final String label; 
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 6),
      child: Text(
        label,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.55),
          fontWeight: FontWeight.w700,
          fontSize: Ts.s(context, 12),
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  final List<Widget> children;
  const _SettingsGroup({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: Colors.white.withValues(alpha: 0.18), width: 1),
      ),
      child: Column(children: children),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SettingsRow({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: Colors.white.withValues(alpha: 0.80), size: 20),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: Ts.s(context, 15),
                ),
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: Colors.white.withValues(alpha: 0.40), size: 20),
          ],
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      indent: 50,
      endIndent: 0,
      color: Colors.white.withValues(alpha: 0.12),
    );
  }
}
