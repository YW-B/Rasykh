import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/progress_repository.dart';
import '../theme/app_theme.dart';
import '../theme/glass_widgets.dart';
import '../widgets/ambient_background.dart';

/// Simple settings screen accessible from the Stats dashboard.
class StatsSettingsScreen extends StatefulWidget {
  const StatsSettingsScreen({super.key});

  @override
  State<StatsSettingsScreen> createState() => _StatsSettingsScreenState();
}

class _StatsSettingsScreenState extends State<StatsSettingsScreen> {
  late bool _requireRecall;
  late int _dailyTarget;

  @override
  void initState() {
    super.initState();
    final pc = ProgressController();
    _requireRecall = pc.requireRecallForStats;
    _dailyTarget = pc.dailyTargetAyat;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          const AmbientBackground(),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // App bar
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        GlassButton(
                          onTap: () => Navigator.of(context).pop(),
                          padding: const EdgeInsets.all(8),
                          child: Icon(
                            Icons.arrow_back,
                            size: 20,
                            color: AppColors.emerald100.withValues(alpha: 0.70),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Settings',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Settings cards
                  Expanded(
                    child: ListView(
                      children: [
                        _buildRecallToggle(),
                        const SizedBox(height: 16),
                        _buildDailyTarget(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecallToggle() {
    return GlassPanel(
      borderRadius: 20,
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Require Recall for Stats',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Only count chunks with completed Active Recall in your progress stats.',
                  style: GoogleFonts.inter(
                    color: AppColors.emerald100.withValues(alpha: 0.40),
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Switch.adaptive(
            value: _requireRecall,
            activeTrackColor: AppColors.emerald500,
            onChanged: (v) {
              setState(() => _requireRecall = v);
              ProgressController().setRequireRecallForStats(v);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDailyTarget() {
    return GlassPanel(
      borderRadius: 20,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Daily Target',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Number of ayat you aim to memorize each day.',
            style: GoogleFonts.inter(
              color: AppColors.emerald100.withValues(alpha: 0.40),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              // Minus
              GlassButton(
                onTap: () {
                  if (_dailyTarget > 1) {
                    setState(() => _dailyTarget--);
                    ProgressController().setDailyTargetAyat(_dailyTarget);
                  }
                },
                padding: const EdgeInsets.all(8),
                child: const Icon(
                  Icons.remove,
                  size: 20,
                  color: AppColors.emerald400,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                '$_dailyTarget',
                style: GoogleFonts.amiri(color: Colors.white, fontSize: 32),
              ),
              const SizedBox(width: 4),
              Text(
                'ayat',
                style: GoogleFonts.inter(
                  color: AppColors.emerald200.withValues(alpha: 0.50),
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 16),
              // Plus
              GlassButton(
                onTap: () {
                  if (_dailyTarget < 50) {
                    setState(() => _dailyTarget++);
                    ProgressController().setDailyTargetAyat(_dailyTarget);
                  }
                },
                padding: const EdgeInsets.all(8),
                child: const Icon(
                  Icons.add,
                  size: 20,
                  color: AppColors.emerald400,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
