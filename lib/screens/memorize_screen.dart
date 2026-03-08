import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/quran_repository.dart';
import '../theme/app_theme.dart';
import '../theme/glass_widgets.dart';
import 'mutasawi_session_screen.dart';

/// Memorize tab — pick a surah, then navigate into a Mutasawi session.
class MemorizeScreen extends StatelessWidget {
  const MemorizeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          ...QuranRepository().getAllSurahs().map(
            (surah) => _buildSurahTile(context, surah),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'MUTASAWI METHOD',
          style: GoogleFonts.inter(
            color: AppColors.emerald200.withValues(alpha: 0.50),
            fontSize: 11,
            letterSpacing: 2,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Choose a Surah to memorize',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w300,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Each surah is split into 3 equal sections for structured review.',
          style: GoogleFonts.inter(
            color: AppColors.emerald100.withValues(alpha: 0.40),
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _buildSurahTile(BuildContext context, Surah surah) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassPanel(
        borderRadius: 16,
        padding: const EdgeInsets.all(18),
        child: InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => MutasawiSessionScreen(surah: surah),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Row(
            children: [
              // Surah number circle
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.emerald500.withValues(alpha: 0.08),
                  border: Border.all(
                    color: AppColors.emerald500.withValues(alpha: 0.25),
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  surah.number.toString(),
                  style: GoogleFonts.amiri(
                    color: AppColors.emerald200,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      surah.name,
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${surah.english} • ${surah.ayat.length} ayat',
                      style: GoogleFonts.inter(
                        color: AppColors.emerald100.withValues(alpha: 0.40),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                size: 20,
                color: AppColors.emerald100.withValues(alpha: 0.40),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
