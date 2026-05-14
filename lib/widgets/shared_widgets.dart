import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';

//<3<3<3<3<3<3<3<3<3<3 Tap Scale Widget <3<3<3<3<3<3<3<3<3>

class TapScaleWidget extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  const TapScaleWidget({super.key, required this.child, this.onTap});

  @override
  State<TapScaleWidget> createState() => _TapScaleWidgetState();
}

class _TapScaleWidgetState extends State<TapScaleWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 90),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeIn),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap?.call();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) =>
            Transform.scale(scale: _scale.value, child: child),
        child: widget.child,
      ),
    );
  }
}

//<3<3<3<3<3<3<3<3<3 App Card <3<3<3<3<3<3<3<3<3

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final double radius;
  final bool light; // true = white card; false = blue card (default)

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.radius = 20,
    this.light = false,
  });

  @override
  Widget build(BuildContext context) {
    final bg = light ? AppColors.surface : AppColors.card;
    final card = Container(
      width: double.infinity,
      padding: padding ?? EdgeInsets.all(Sp.s(context, 16)),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(radius),
        border: light
            ? Border.all(color: AppColors.surfaceBorder, width: 1)
            : Border.all(color: Colors.white.withValues(alpha: 0.18), width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardDark.withValues(alpha: light ? 0.06 : 0.15),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );

    if (onTap != null) {
      return TapScaleWidget(onTap: onTap, child: card);
    }
    return card;
  }
}

//<3<3<3<3<3<3<3<3<3 App Button <3<3<3<3<3<3<3<3<3

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final Color? color;

  const AppButton({
    super.key,
    required this.label,
    this.onTap,
    this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final bg = color ?? AppColors.accent;
    return TapScaleWidget(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: Sp.s(context, 52),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: bg.withValues(alpha: 0.28),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: GoogleFonts.nunito(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: Ts.s(context, 17),
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

//<3<3<3<3<3<3<3<3<3 Section Title <3<3<3<3<3<3<3<3<3

class SectionTitle extends StatelessWidget {
  final String title;
  final Widget? action;

  const SectionTitle({super.key, required this.title, this.action});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.nunito(
            color: AppColors.textDark,
            fontWeight: FontWeight.w900,
            fontSize: Ts.s(context, 20),
            letterSpacing: 0.1,
          ),
        ),
        if (action != null) action!,
      ],
    );
  }
}

//<3<3<3<3<3<3<3<3<3 Progress Widget <3<3<3<3<3<3<3<3<3

class ProgressWidget extends StatelessWidget {
  final double value; // 0.0 – 1.0
  final Color? color;
  final double height;
  final String? label;

  const ProgressWidget({
    super.key,
    required this.value,
    this.color,
    this.height = 8,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    final barColor = color ?? const Color.fromARGB(255, 202, 104, 0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: value.clamp(0.0, 1.0)),
          duration: const Duration(milliseconds: 900),
          curve: Curves.easeOutCubic,
          builder: (_, v, __) => ClipRRect(
            borderRadius: BorderRadius.circular(height),
            child: LinearProgressIndicator(
              value: v,
              minHeight: height,
              backgroundColor: Colors.white.withValues(alpha: 0.28),
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
            ),
          ),
        ),
        if (label != null) ...[
          const SizedBox(height: 4),
          Text(
            label!,
            style: GoogleFonts.nunito(
              color: AppColors.onSurfaceMid,
              fontSize: Ts.s(context, 13),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}

//<3<3<3<3<3<3<3<3<3 App Bar <3<3<3<3<3<3<3<3<3

PreferredSizeWidget buildAppBar(
  BuildContext context,
  String title, {
  Widget? trailing,
  bool showBack = true,
}) {
  final size = MediaQuery.of(context).size;
  final logoH = (size.width * 0.09).clamp(30.0, 44.0);

  return AppBar(
    automaticallyImplyLeading: false,
    leading: showBack
        ? IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () => Navigator.pop(context),
          )
        : Padding(
            padding: const EdgeInsets.only(left: 14),
            child: SvgPicture.asset(
              'assets/images/logoselfmade.svg',
              height: logoH,
            ),
          ),
    title: FittedBox(fit: BoxFit.scaleDown, child: Text(title)),
    actions: trailing != null ? [trailing, const SizedBox(width: 12)] : null,
  );
}

//<3<3<3<3<3<3<3<3<3 Icon Buttons <3<3<3<3<3<3<3<3<3

class SettingsIconButton extends StatelessWidget {
  final VoidCallback onTap;
  const SettingsIconButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 44,
        height: 44,
        child: Center(
          child: Container(
            width: 38,
            height: 38,
            decoration: const BoxDecoration(
              color: AppColors.cardDark,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.edit_calendar_rounded,
                color: Colors.white, size: 20),
          ),
        ),
      ),
    );
  }
}

class ProfileIconButton extends StatelessWidget {
  final VoidCallback onTap;
  const ProfileIconButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 44,
        height: 44,
        child: Center(
          child: Container(
            width: 38,
            height: 38,
            decoration: const BoxDecoration(
              color: AppColors.cardDark,
              shape: BoxShape.circle,
            ),
            child:
                const Icon(Icons.person_rounded, color: Colors.white, size: 20),
          ),
        ),
      ),
    );
  }
}

//<3<3<3<3<33<3<<3<3<3 Bottim navigation <3<3<3<3<3<3<3<3<3

class AppBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final void Function(int) onTap;

  const AppBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom > 0
            ? MediaQuery.of(context).padding.bottom
            : 8,
        top: 8,
      ),
      decoration: BoxDecoration(
        color: AppColors.bg,
        border: Border(
            top: BorderSide(
                color: AppColors.cardDark.withValues(alpha: 0.30), width: 1)),
        boxShadow: [
          BoxShadow(
            color: AppColors.textDark.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
              child: _NavItem(
                  icon: Icons.home_rounded,
                  label: 'Home',
                  selected: currentIndex == 0,
                  onTap: () => onTap(0))),
          Expanded(
              child: _NavItem(
                  icon: Icons.calendar_month_rounded,
                  label: 'Calendar',
                  selected: currentIndex == 1,
                  onTap: () => onTap(1))),
          Expanded(
              child: _NavItem(
                  icon: Icons.school_rounded,
                  label: 'Courses',
                  selected: currentIndex == 2,
                  onTap: () => onTap(2))),
          Expanded(
              child: _NavItem(
                  icon: Icons.bar_chart_rounded,
                  label: 'Stats',
                  selected: currentIndex == 3,
                  onTap: () => onTap(3))),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? AppColors.cardDark
        : AppColors.cardDark.withValues(alpha: 0.45);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 24, color: color),
            const SizedBox(height: 3),
            Text(
              label,
              style: GoogleFonts.nunito(
                fontSize: Ts.s(context, 13),
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

//<3<3<3<3<3<3<3<3<3 Input Field <3<3<3<3<3<3<3<3<3

class StyledInput extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final bool obscure;
  final String? hint;
  final Widget? suffix;

  const StyledInput({
    super.key,
    required this.label,
    required this.controller,
    this.keyboardType = TextInputType.text,
    this.obscure = false,
    this.hint,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(
            label,
            style: GoogleFonts.nunito(
              color: Colors.white.withValues(alpha: 0.85),
              fontWeight: FontWeight.w700,
              fontSize: Ts.s(context, 14),
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.inputBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: Colors.white.withValues(alpha: 0.22), width: 1),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            obscureText: obscure,
            style: GoogleFonts.nunito(
              fontSize: Ts.s(context, 16),
              color: AppColors.textDark,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              hintText: hint,
              hintStyle: GoogleFonts.nunito(
                  color: AppColors.textDark.withValues(alpha: 0.4),
                  fontWeight: FontWeight.w500),
              suffixIcon: suffix,
            ),
          ),
        ),
      ],
    );
  }
}

class MenuRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool destructive;

  const MenuRow({
    super.key,
    required this.icon,
    required this.label,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = destructive ? Colors.redAccent : AppColors.textDark;
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(
              color: color, fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ],
    );
  }
}
