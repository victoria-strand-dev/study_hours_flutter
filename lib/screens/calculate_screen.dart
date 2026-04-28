import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../state/app_state.dart';
import '../models/models.dart';
import '../widgets/shared_widgets.dart';

// Sub-modes
const int _subTarget = 0; // target grade → hours/day needed
const int _subGrade  = 1; // hours/day given → expected grade

class CalculateScreen extends StatefulWidget {
  final Course? course;
  const CalculateScreen({super.key, this.course});

  @override
  State<CalculateScreen> createState() => _CalculateScreenState();
}

class _CalculateScreenState extends State<CalculateScreen>
    with SingleTickerProviderStateMixin {
  int _subMode = _subTarget;

  final _courseNameCtrl     = TextEditingController();
  final _courseCreditsCtrl  = TextEditingController(text: '10');
  final _hoursPerDayCtrl    = TextEditingController(text: '2');
  final _desiredGradeCtrl   = TextEditingController(text: 'A');
  final _daysPerWeekCtrl    = TextEditingController(text: '2');
  final _hoursStudiedCtrl = TextEditingController(text: '0');
  DateTime? _examDate;
  int _selectedColor = 0; // 0 = auto-assign from presets

  int get _weeksRemaining {
    if (_examDate == null) return 0;
    final today     = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    final examOnly  = DateTime(_examDate!.year, _examDate!.month, _examDate!.day);
    final diff = examOnly.difference(todayOnly).inDays;
    return diff <= 0 ? 0 : ((diff - 1) ~/ 7) + 1;
  }

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 200));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeInOut);
    _animCtrl.forward();

    for (final c in [
      _courseCreditsCtrl, _hoursPerDayCtrl, _desiredGradeCtrl,
      _daysPerWeekCtrl, _hoursStudiedCtrl,
    ]) {
      c.addListener(_refresh);
    }
  }

  void _refresh() => setState(() {});

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final state = AppStateProvider.of(context);

    if (widget.course != null) {
      final c = widget.course!;
      _courseNameCtrl.text = c.name;
      _courseCreditsCtrl.text =
          c.credits % 1 == 0 ? c.credits.toInt().toString() : c.credits.toString();
      _hoursPerDayCtrl.text = c.hoursPerDay.toString();
      _daysPerWeekCtrl.text = c.daysPerWeek.toString();
      _desiredGradeCtrl.text = c.targetGrade;
      _subMode = c.hoursMode ? _subTarget : _subGrade;

      final completed    = state.completedHoursForCourse(c.id);
      final studiedValue = completed > 0 ? completed : c.hoursStudiedSoFar;
      if (studiedValue > 0) {
        _hoursStudiedCtrl.text = studiedValue.toStringAsFixed(1);
      }

      if (c.examDate != null) {
        _examDate = c.examDate;
      }
      _selectedColor = c.color;
    }
  }

  @override
  void dispose() {
    _courseNameCtrl.dispose();
    _courseCreditsCtrl.dispose();
    _hoursPerDayCtrl.dispose();
    _desiredGradeCtrl.dispose();
    _daysPerWeekCtrl.dispose();
    _hoursStudiedCtrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  void _switchSub(int mode) {
    if (_subMode == mode) return;
    _animCtrl.reverse().then((_) {
      setState(() => _subMode = mode);
      _animCtrl.forward();
    });
  }

  Future<void> _pickExamDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _examDate ?? DateTime.now().add(const Duration(days: 60)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 730)),
      helpText: 'Select exam date',
    );
    if (picked != null) setState(() => _examDate = picked);
  }

  void _clearExamDate() => setState(() => _examDate = null);

  void _showError(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  // ─── Calculations ──────────────────────────────────────────────────────────

  /// Hours/day needed from now to reach [grade]
  double? _computeHoursNeeded(int semCredits, int semWeeks,
      double courseCredits, String grade, double hoursStudied,
      int weeksRemaining, int daysPerWeek) {
    if (semCredits <= 0 || semWeeks <= 0 || courseCredits <= 0 ||
        weeksRemaining <= 0 || daysPerWeek <= 0) { return null; }
    final mult = gradeMultiplier(grade);
    if (mult == null) { return null; }
    final totalRequired =
        (courseCredits / semCredits) * 37.5 * semWeeks * mult;
    final remaining = totalRequired - hoursStudied;
    if (remaining <= 0) { return 0.0; }
    return remaining / weeksRemaining / daysPerWeek;
  }

  /// Expected grade based on projected total hours (studied + future)
  String _computeExpectedGrade(int semCredits, int semWeeks,
      double courseCredits, double hoursStudied, double hoursPerDay,
      int daysPerWeek, int weeksRemaining) {
    if (semCredits <= 0 || semWeeks <= 0 || courseCredits <= 0 ||
        hoursPerDay <= 0 || daysPerWeek <= 0 || weeksRemaining <= 0) { return '?'; }
    final projected =
        hoursStudied + (hoursPerDay * daysPerWeek * weeksRemaining);
    final base = (courseCredits / semCredits) * 37.5 * semWeeks;
    final ratio = projected / base;
    if (ratio >= 0.9) { return 'A'; }
    if (ratio >= 0.8) { return 'B'; }
    if (ratio >= 0.6) { return 'C'; }
    if (ratio >= 0.5) { return 'D'; }
    if (ratio >= 0.4) { return 'E'; }
    return 'F';
  }

  // ─── Live result ───────────────────────────────────────────────────────────

  String? _buildResultText(AppState state) {
    final credits  = double.tryParse(_courseCreditsCtrl.text.trim()) ?? 0;
    final days     = int.tryParse(_daysPerWeekCtrl.text.trim()) ?? 0;
    final studied  = double.tryParse(_hoursStudiedCtrl.text.trim()) ?? -1;
    final weeksRem = _weeksRemaining;
    final daysLbl  = days == 1 ? '1 day' : '$days days';

    if (credits <= 0 || days <= 0 || studied < 0 || weeksRem <= 0) return null;

    if (_subMode == _subTarget) {
      final desired = _desiredGradeCtrl.text.trim().toUpperCase();
      if (!_validGrade(desired)) return null;
      final h = _computeHoursNeeded(state.semesterCredits, state.semesterWeeks,
          credits, desired, studied, weeksRem, days);
      if (h == null) return null;
      if (h <= 0) return "You've already studied enough for an $desired!";
      return 'To get an $desired: ${h.toStringAsFixed(1)}h, $daysLbl/week for $weeksRem weeks';
    } else {
      final hpd = double.tryParse(_hoursPerDayCtrl.text.trim()) ?? 0;
      if (hpd <= 0) return null;
      final grade = _computeExpectedGrade(state.semesterCredits,
          state.semesterWeeks, credits, studied, hpd, days, weeksRem);
      return 'With ${hpd.toStringAsFixed(1)}h, $daysLbl/week for $weeksRem weeks → $grade';
    }
  }

  bool _validGrade(String g) => ['A', 'B', 'C', 'D', 'E', 'F'].contains(g);

  // ─── Save ──────────────────────────────────────────────────────────────────

  Future<void> _saveCourse() async {
    final state   = AppStateProvider.of(context);
    final name    = _courseNameCtrl.text.trim();
    final credits = double.tryParse(_courseCreditsCtrl.text.trim()) ?? 0;
    final days    = int.tryParse(_daysPerWeekCtrl.text.trim()) ?? 0;
    final studied  = double.tryParse(_hoursStudiedCtrl.text.trim()) ?? -1;
    final weeksRem = _weeksRemaining;

    if (name.isEmpty || credits <= 0 || days <= 0) {
      _showError('Please fill in all course details.');
      return;
    }
    if (days > 7) {
      _showError('Days per week cannot exceed 7.');
      return;
    }
    if (studied < 0) {
      _showError('Please enter hours studied so far (0 or more).');
      return;
    }
    if (_examDate == null) {
      _showError('Please set an exam date.');
      return;
    }
    if (weeksRem <= 0) {
      _showError('Exam date must be in the future.');
      return;
    }

    String targetGrade;
    double savedHours;

    if (_subMode == _subTarget) {
      final desired = _desiredGradeCtrl.text.trim().toUpperCase();
      if (!_validGrade(desired)) {
        _showError('Please enter a valid target grade (A–F).');
        return;
      }
      final h = _computeHoursNeeded(state.semesterCredits, state.semesterWeeks,
          credits, desired, studied, weeksRem, days);
      if (h == null) {
        _showError('Could not compute hours. Check settings.');
        return;
      }
      targetGrade = desired;
      savedHours  = h <= 0 ? 0 : h;
    } else {
      final hpd = double.tryParse(_hoursPerDayCtrl.text.trim()) ?? 0;
      if (hpd <= 0) {
        _showError('Please enter valid study hours per day.');
        return;
      }
      targetGrade = _computeExpectedGrade(state.semesterCredits,
          state.semesterWeeks, credits, studied, hpd, days, weeksRem);
      savedHours = hpd;
    }

    final newCourse = Course(
      id:                widget.course?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name:              name,
      credits:           credits,
      targetGrade:       targetGrade,
      hoursPerDay:       savedHours,
      daysPerWeek:       days,
      hoursMode:         _subMode == _subTarget,
      catchUpMode:       true,
      examDate:          _examDate,
      hoursStudiedSoFar: studied,
      color:             _selectedColor,
    );

    if (widget.course != null) {
      await state.updateCourse(newCourse);
    } else {
      await state.addCourse(newCourse);
    }
    if (!mounted) return;
    Navigator.pop(context);
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final state      = AppStateProvider.of(context);
    final size       = MediaQuery.of(context).size;
    final double hPad = (size.width * 0.06).clamp(16.0, 48.0);
    final resultText = _buildResultText(state);

    return Scaffold(
      appBar: buildAppBar(context, 'CALCULATE'),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(hPad, 12, hPad, 16),
          child: Column(
            children: [
              _CalcField(
                label: 'Course name',
                controller: _courseNameCtrl,
                inputType: TextInputType.text,
                formatters: const [],
              ),
              const SizedBox(height: 12),
              _SubModeSelector(subMode: _subMode, onSwitch: _switchSub, size: size),
              const SizedBox(height: 12),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: FadeTransition(
                    opacity: _fadeAnim,
                    child: Column(
                      children: [
                        _InputCard(
                          subMode:           _subMode,
                          courseCreditsCtrl: _courseCreditsCtrl,
                          hoursPerDayCtrl:   _hoursPerDayCtrl,
                          desiredGradeCtrl:  _desiredGradeCtrl,
                          daysPerWeekCtrl:   _daysPerWeekCtrl,
                          hoursStudiedCtrl:  _hoursStudiedCtrl,
                        ),
                        const SizedBox(height: 8),
                        _ExamDateRow(
                          examDate: _examDate,
                          onPick:   _pickExamDate,
                          onClear:  _clearExamDate,
                        ),
                        const SizedBox(height: 8),
                        _ColorPickerRow(
                          selectedColor: _selectedColor,
                          onChanged: (c) => setState(() => _selectedColor = c),
                        ),
                        if (resultText != null) ...[
                          const SizedBox(height: 12),
                          _ResultCard(text: resultText),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _saveCourse,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.cardDark,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    widget.course == null ? 'Save Course' : 'Update Course',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16),
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

// ─── RESULT CARD ──────────────────────────────────────────────────────────────

class _ResultCard extends StatelessWidget {
  final String text;
  const _ResultCard({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18), width: 1),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 16,
        ),
      ),
    );
  }
}

// ─── SUB-MODE SELECTOR ────────────────────────────────────────────────────────

class _SubModeSelector extends StatelessWidget {
  final int subMode;
  final void Function(int) onSwitch;
  final Size size;
  const _SubModeSelector(
      {required this.subMode, required this.onSwitch, required this.size});

  @override
  Widget build(BuildContext context) {
    final fs = (size.width * 0.034).clamp(12.0, 16.0);
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18), width: 1),
      ),
      child: Row(
        children: [
          _ModeTab(
            label: 'Hours/day',
            icon: Icons.timer_outlined,
            selected: subMode == _subTarget,
            onTap: () => onSwitch(_subTarget),
            fontSize: fs,
          ),
          _ModeTab(
            label: 'Exp. grade',
            icon: Icons.school_outlined,
            selected: subMode == _subGrade,
            onTap: () => onSwitch(_subGrade),
            fontSize: fs,
          ),
        ],
      ),
    );
  }
}

class _ModeTab extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final double fontSize;

  const _ModeTab({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    required this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          decoration: BoxDecoration(
            color: selected ? AppColors.cardDark : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: fontSize + 2,
                  color: selected ? Colors.white : AppColors.textDark),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : AppColors.textDark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── INPUT CARD ───────────────────────────────────────────────────────────────

class _InputCard extends StatelessWidget {
  final int subMode;
  final TextEditingController courseCreditsCtrl;
  final TextEditingController hoursPerDayCtrl;
  final TextEditingController desiredGradeCtrl;
  final TextEditingController daysPerWeekCtrl;
  final TextEditingController hoursStudiedCtrl;

  const _InputCard({
    required this.subMode,
    required this.courseCreditsCtrl,
    required this.hoursPerDayCtrl,
    required this.desiredGradeCtrl,
    required this.daysPerWeekCtrl,
    required this.hoursStudiedCtrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18), width: 1),
        boxShadow: [
          BoxShadow(
              color: AppColors.cardDark.withValues(alpha: 0.12),
              blurRadius: 10,
              offset: const Offset(0, 3))
        ],
      ),
      child: Column(
        children: [
          _CalcField(
            label: 'Credits for this course',
            controller: courseCreditsCtrl,
            inputType: const TextInputType.numberWithOptions(decimal: true),
            formatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))
            ],
          ),
          _CalcField(
            label: 'Hours studied so far',
            controller: hoursStudiedCtrl,
            inputType: const TextInputType.numberWithOptions(decimal: true),
            formatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))
            ],
          ),
          if (subMode == _subTarget)
            _CalcField(
              label: 'Target grade (A–F)',
              controller: desiredGradeCtrl,
              inputType: TextInputType.text,
              formatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[a-fA-F]')),
                LengthLimitingTextInputFormatter(1),
              ],
              textCapitalization: TextCapitalization.characters,
            ),
          if (subMode == _subGrade)
            _CalcField(
              label: 'Study hours per day',
              controller: hoursPerDayCtrl,
              inputType: const TextInputType.numberWithOptions(decimal: true),
              formatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))
              ],
            ),
          _CalcField(
            label: 'Study days per week',
            controller: daysPerWeekCtrl,
            formatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(1),
            ],
            isLast: true,
          ),
        ],
      ),
    );
  }
}

// ─── EXAM DATE ROW ────────────────────────────────────────────────────────────

class _ExamDateRow extends StatelessWidget {
  final DateTime? examDate;
  final VoidCallback onPick;
  final VoidCallback onClear;

  const _ExamDateRow({
    required this.examDate,
    required this.onPick,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final size  = MediaQuery.of(context).size;
    final fs    = (size.width * 0.033).clamp(11.0, 15.0);
    final label = examDate != null
        ? 'Exam: ${DateFormat('d MMM yyyy').format(examDate!)}'
        : 'Set exam date (required)';

    return GestureDetector(
      onTap: onPick,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: examDate != null ? AppColors.cardDark : AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.18), width: 1),
        ),
        child: Row(
          children: [
            Icon(Icons.event_rounded,
                size: fs + 4,
                color: examDate != null ? Colors.white : AppColors.textDark),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: fs,
                  fontWeight: FontWeight.w700,
                  color: examDate != null
                      ? Colors.white
                      : AppColors.accent,
                ),
              ),
            ),
            if (examDate != null)
              GestureDetector(
                onTap: onClear,
                child: const Icon(Icons.close_rounded,
                    size: 18, color: Colors.white70),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── COLOR PICKER ROW ─────────────────────────────────────────────────────────

class _ColorPickerRow extends StatelessWidget {
  final int selectedColor;
  final void Function(int) onChanged;
  const _ColorPickerRow({required this.selectedColor, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.palette_rounded, color: Colors.white70, size: 18),
              const SizedBox(width: 8),
              const Text(
                'Course colour',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              if (selectedColor != 0)
                GestureDetector(
                  onTap: () => onChanged(0),
                  child: Text(
                    'Auto',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.55),
                      fontWeight: FontWeight.w600,
                      fontSize: Ts.s(context, 13),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: CourseColors.presets.map((c) {
              final isSelected = selectedColor == c;
              return GestureDetector(
                onTap: () => onChanged(c),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: Color(c),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? Colors.white : Colors.transparent,
                      width: 3,
                    ),
                    boxShadow: isSelected
                        ? [BoxShadow(color: Color(c).withValues(alpha: 0.6), blurRadius: 8)]
                        : null,
                  ),
                  child: isSelected
                      ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
                      : null,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ─── CALC FIELD ───────────────────────────────────────────────────────────────

class _CalcField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final TextInputType inputType;
  final List<TextInputFormatter> formatters;
  final bool isLast;
  final TextCapitalization textCapitalization;

  const _CalcField({
    required this.label,
    required this.controller,
    this.inputType = const TextInputType.numberWithOptions(),
    required this.formatters,
    this.isLast = false,
    this.textCapitalization = TextCapitalization.none,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 8),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.inputBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.18), width: 1),
        ),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                  vertical: (size.height * 0.011).clamp(7.0, 13.0),
                  horizontal: 12),
              decoration: const BoxDecoration(
                color: AppColors.cardDark,
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              child: TextField(
                controller: controller,
                textAlign: TextAlign.center,
                keyboardType: inputType,
                inputFormatters: formatters,
                textCapitalization: textCapitalization,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
