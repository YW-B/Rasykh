import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import 'maqamat_screen.dart';

/// Voice module tab with sub-tabs (Maqamat, more to come).
class QuizScreen extends StatelessWidget {
  const QuizScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Voice',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Tab bar
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                indicatorSize: TabBarIndicatorSize.tab,
                indicator: BoxDecoration(
                  color: AppColors.emerald500.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.emerald500.withValues(alpha: 0.30),
                  ),
                ),
                dividerHeight: 0,
                labelStyle: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                unselectedLabelStyle: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                ),
                labelColor: AppColors.emerald400,
                unselectedLabelColor: AppColors.emerald100.withValues(
                  alpha: 0.40,
                ),
                tabs: const [
                  Tab(text: 'Maqamat'),
                  Tab(text: 'Voice Quiz'),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Tab views
            Expanded(
              child: TabBarView(
                children: [
                  const MaqamatScreen(),
                  // Voice Quiz placeholder
                  Center(
                    child: Text(
                      'Voice Quiz coming soon…',
                      style: GoogleFonts.inter(
                        color: AppColors.emerald100.withValues(alpha: 0.50),
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
