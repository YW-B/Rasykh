import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/maqamat_data.dart';
import '../theme/app_theme.dart';
import '../theme/glass_widgets.dart';

/// Scrollable list of Maqam lessons drawn from [kMaqamLessons].
class MaqamatScreen extends StatelessWidget {
  const MaqamatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      itemCount: kMaqamLessons.length,
      separatorBuilder: (_, _) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        final lesson = kMaqamLessons[index];
        return GlassPanel(
          borderRadius: 20,
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Title
              Text(
                lesson.title,
                textDirection: TextDirection.rtl,
                style: GoogleFonts.scheherazadeNew(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 12),
              // Divider
              Container(
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.emerald500.withValues(alpha: 0.40),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              // Body
              Text(
                lesson.body,
                textDirection: TextDirection.rtl,
                style: GoogleFonts.scheherazadeNew(
                  color: AppColors.emerald100.withValues(alpha: 0.70),
                  fontSize: 18,
                  height: 2.0,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
