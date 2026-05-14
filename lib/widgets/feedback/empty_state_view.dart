import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';
import '../shared_widgets.dart';

class EmptyStateView extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String title;
  final String subtitle;
  final String? buttonLabel;
  final VoidCallback? onButtonTap;

  const EmptyStateView({
    super.key,
    required this.icon,
    this.iconColor,
    required this.title,
    required this.subtitle,
    this.buttonLabel,
    this.onButtonTap,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final color = iconColor ?? AppColors.textDark.withValues(alpha: 0.35);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: (size.width * 0.18).clamp(56.0, 80.0),
            color: color,
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: GoogleFonts.nunito(
              color: AppColors.textDark,
              fontWeight: FontWeight.w800,
              fontSize: Ts.s(context, 20),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              color: AppColors.textDark.withValues(alpha: 0.65),
              fontSize: Ts.s(context, 14),
              fontWeight: FontWeight.w600,
            ),
          ),
          if (buttonLabel != null && onButtonTap != null) ...[
            const SizedBox(height: 20),
            AppButton(
              label: buttonLabel!,
              icon: Icons.add_rounded,
              onTap: onButtonTap!,
            ),
          ],
        ],
      ),
    );
  }
}
