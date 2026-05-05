import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../state/app_state.dart';
import '../widgets/shared_widgets.dart';
import 'main_shell.dart';

class SettingsScreen extends StatefulWidget {
  final bool firstTime;
  const SettingsScreen({super.key, this.firstTime = false});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _semesterCreditsCtrl = TextEditingController();
  final _semesterWeeksCtrl   = TextEditingController();
  DateTime? _startDate;
  bool _saved = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final state = AppStateProvider.of(context);
    if (_semesterCreditsCtrl.text.isEmpty) {
      _semesterCreditsCtrl.text = state.semesterCredits.toString();
    }
    if (_semesterWeeksCtrl.text.isEmpty) {
      _semesterWeeksCtrl.text = state.semesterWeeks.toString();
    }
    _startDate ??= state.semesterStartDate;
  }

  @override
  void dispose() {
    _semesterCreditsCtrl.dispose();
    _semesterWeeksCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickStartDate() async {
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

  Future<void> _clearStartDate() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Clear start date',
            style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w800)),
        content: const Text('Remove the semester start date?',
            style: TextStyle(color: AppColors.textDark)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.cardDark,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Clear',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirmed == true) setState(() => _startDate = null);
  }

  Future<void> _save() async {
    final state   = AppStateProvider.of(context);
    final credits = int.tryParse(_semesterCreditsCtrl.text.trim()) ?? state.semesterCredits;
    final weeks   = int.tryParse(_semesterWeeksCtrl.text.trim()) ?? state.semesterWeeks;

    await state.updateSemesterSettings(
      credits,
      weeks,
      _startDate,
      clearStartDate: _startDate == null,
    );

    if (!mounted) return;

    if (widget.firstTime) {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const MainShell()));
      return;
    }

    setState(() => _saved = true);
    Future.delayed(const Duration(seconds: 2),
        () { if (mounted) setState(() => _saved = false); });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final double hPad = (size.width * 0.07).clamp(20.0, 52.0);

    return Scaffold(
      appBar: buildAppBar(context, 'SEMESTER',
          showBack: !widget.firstTime),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 16),
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.18), width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Semester',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: Ts.s(context, 17),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: StyledInput(
                            label: 'Total Credits',
                            controller: _semesterCreditsCtrl,
                            keyboardType: const TextInputType.numberWithOptions(),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: StyledInput(
                            label: 'Total Weeks',
                            controller: _semesterWeeksCtrl,
                            keyboardType: const TextInputType.numberWithOptions(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: _pickStartDate,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                        decoration: BoxDecoration(
                          color: AppColors.inputBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.18), width: 1),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today_rounded,
                                color: Colors.white70, size: 18),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Semester start date',
                                  style: TextStyle(
                                    color: AppColors.textDark,
                                    fontSize: Ts.s(context, 13),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _startDate != null
                                      ? DateFormat('d MMM yyyy').format(_startDate!)
                                      : 'Not set',
                                  style: TextStyle(
                                    color: _startDate != null
                                        ? AppColors.card
                                        : AppColors.card,
                                    fontSize: Ts.s(context, 15),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            if (_startDate != null)
                              GestureDetector(
                                onTap: _clearStartDate,
                                child: const Icon(Icons.close_rounded,
                                    color: AppColors.card, size: 18),
                              )
                            else
                              Icon(Icons.chevron_right_rounded,
                                  color: AppColors.card.withValues(alpha: 0.4), size: 20),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        _saved ? const Color(0xFF2ECC71) : AppColors.cardDark,
                    padding: EdgeInsets.symmetric(
                        vertical: (size.height * 0.018).clamp(12.0, 18.0)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 3,
                  ),
                  child: widget.firstTime
                      ? const Text(
                          'Get Started',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 17,
                            letterSpacing: 0.5,
                          ),
                        )
                      : AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: _saved
                              ? const Row(
                                  key: ValueKey('saved'),
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.check_rounded, color: Colors.white, size: 20),
                                    SizedBox(width: 8),
                                    Text('Saved!',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 16)),
                                  ],
                                )
                              : Text(
                                  key: const ValueKey('save'),
                                  'SAVE',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: Ts.s(context, 17),
                                    letterSpacing: 1.5,
                                  ),
                                ),
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
