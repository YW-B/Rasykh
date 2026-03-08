import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../data/progress_repository.dart';
import '../data/quran_repository.dart';
import '../data/mutasawi_logic.dart';
import '../theme/app_theme.dart';
import '../theme/glass_widgets.dart';
import 'mutasawi_session_screen.dart';
import 'privacy_policy_screen.dart';
import 'recall_challenge_screen.dart';
import 'stats_settings_screen.dart';

/// Progress / Stats dashboard — fully data‑driven from ProgressController.
class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  final _progress = ProgressController();

  @override
  void initState() {
    super.initState();
    _progress.addListener(_rebuild);
  }

  @override
  void dispose() {
    _progress.removeListener(_rebuild);
    super.dispose();
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final stats = _progress.loadStats();
    final surahProgress = _progress.loadAllSurahProgress();
    final items = surahProgress.values.toList()
      ..sort((a, b) => a.surahNumber.compareTo(b.surahNumber));
    final needsRecall = _progress.chunksNeedingRecall();

    const totalQuranAyat = 6236;
    final percent = stats.totalAyatMemorized == 0
        ? 0.0
        : stats.totalAyatMemorized / totalQuranAyat;

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          _buildStreakCard(stats),
          const SizedBox(height: 10),
          _buildDailyTarget(),
          const SizedBox(height: 16),
          _buildGlobalStats(stats, percent),
          const SizedBox(height: 16),
          if (needsRecall.isNotEmpty) ...[
            _buildNeedsRecall(needsRecall),
            const SizedBox(height: 16),
          ],
          if (items.isNotEmpty) ...[
            _buildSurahProgressHeader(),
            const SizedBox(height: 10),
            ...items.map(
              (p) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _buildSurahCard(p),
              ),
            ),
          ],
          if (items.isEmpty) _buildEmptyState(),
          const SizedBox(height: 16),
          _buildSupportCard(),
          const SizedBox(height: 16),
          InkWell(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
              );
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              child: Row(
                children: [
                  const Icon(
                    Icons.privacy_tip,
                    color: AppColors.emerald100,
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Privacy Policy',
                    style: GoogleFonts.inter(
                      color: AppColors.emerald100,
                      fontSize: 15,
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

  // ---- Header ----
  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your Journey',
                style: GoogleFonts.amiri(color: Colors.white, fontSize: 28),
              ),
              const SizedBox(height: 4),
              Text(
                'Consistency is the key to Hifz.',
                style: GoogleFonts.inter(
                  color: AppColors.emerald100.withValues(alpha: 0.50),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        GlassButton(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const StatsSettingsScreen()),
          ),
          padding: const EdgeInsets.all(10),
          child: Icon(
            Icons.settings_outlined,
            size: 20,
            color: AppColors.emerald100.withValues(alpha: 0.60),
          ),
        ),
      ],
    );
  }

  // ---- Streak Card ----
  Widget _buildStreakCard(ProgressStats stats) {
    final days = stats.streakDays;
    final subtitle = days == 0
        ? 'ابدأ اليوم الأول من رحلتك مع الحفظ.'
        : 'استمر على هذا الإيقاع المبارك.';

    return GlassPanel(
      borderRadius: 24,
      padding: const EdgeInsets.all(24),
      child: Stack(
        children: [
          Positioned(
            bottom: -24,
            left: -24,
            right: -24,
            height: 60,
            child: CustomPaint(painter: _WavePainter()),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.amber500.withValues(alpha: 0.20),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.local_fire_department,
                      size: 20,
                      color: AppColors.amber400,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Current Streak',
                    style: GoogleFonts.inter(
                      color: AppColors.emerald100,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '$days ',
                      style: GoogleFonts.amiri(
                        color: Colors.white,
                        fontSize: 44,
                      ),
                    ),
                    TextSpan(
                      text: 'Days',
                      style: GoogleFonts.inter(
                        color: AppColors.emerald200.withValues(alpha: 0.50),
                        fontSize: 16,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                textDirection: TextDirection.rtl,
                style: GoogleFonts.scheherazadeNew(
                  color: AppColors.emerald100.withValues(alpha: 0.50),
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---- Daily target ----
  Widget _buildDailyTarget() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Icon(
            Icons.flag_outlined,
            size: 16,
            color: AppColors.emerald400.withValues(alpha: 0.60),
          ),
          const SizedBox(width: 6),
          Text(
            'الهدف اليومي: ${_progress.dailyTargetAyat} آية',
            textDirection: TextDirection.rtl,
            style: GoogleFonts.scheherazadeNew(
              color: AppColors.emerald200.withValues(alpha: 0.50),
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  // ---- Global Stats ----
  Widget _buildGlobalStats(ProgressStats stats, double percent) {
    return GlassPanel(
      borderRadius: 24,
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'إجمالي الآيات المحفوظة',
                  textDirection: TextDirection.rtl,
                  style: GoogleFonts.scheherazadeNew(
                    color: AppColors.emerald100,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${stats.totalAyatMemorized}',
                  style: GoogleFonts.amiri(color: Colors.white, fontSize: 40),
                ),
                const SizedBox(height: 4),
                Text(
                  'من مجموع ٦٢٣٦ آية تقريبًا',
                  textDirection: TextDirection.rtl,
                  style: GoogleFonts.scheherazadeNew(
                    color: AppColors.emerald100.withValues(alpha: 0.40),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 110,
            height: 110,
            child: CustomPaint(
              painter: _ProgressRingPainter(progress: percent.clamp(0.0, 1.0)),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${(percent * 100).toStringAsFixed(1)}%',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'OF QUR\'AN',
                      style: GoogleFonts.inter(
                        color: AppColors.emerald200.withValues(alpha: 0.50),
                        fontSize: 8,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---- Needs Recall ----
  Widget _buildNeedsRecall(List<ChunkProgress> chunks) {
    return GlassPanel(
      borderRadius: 24,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.psychology, size: 18, color: AppColors.amber400),
              const SizedBox(width: 8),
              Text(
                'تحتاج إلى مراجعة',
                textDirection: TextDirection.rtl,
                style: GoogleFonts.scheherazadeNew(
                  color: AppColors.emerald100,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...chunks.map((cp) {
            final surah = QuranRepository().getSurah(cp.surahNumber);
            final name = surah?.name ?? 'Surah ${cp.surahNumber}';
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GestureDetector(
                onTap: () {
                  if (surah == null) return;
                  final chunkList = buildChunks(surah.ayat);
                  if (cp.chunkIndex < chunkList.length) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => RecallChallengeScreen(
                          surah: surah,
                          chunk: chunkList[cp.chunkIndex],
                        ),
                      ),
                    );
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.05),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.amber500,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.amber500.withValues(alpha: 0.60),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'سورة $name – المقطع رقم ${cp.chunkIndex + 1}',
                              textDirection: TextDirection.rtl,
                              style: GoogleFonts.scheherazadeNew(
                                color: Colors.white,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'بدء التذكّر',
                              textDirection: TextDirection.rtl,
                              style: GoogleFonts.scheherazadeNew(
                                color: AppColors.emerald400,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        size: 18,
                        color: AppColors.emerald100.withValues(alpha: 0.30),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // ---- Per-surah progress ----
  Widget _buildSurahProgressHeader() {
    return Text(
      'PER-SURAH PROGRESS',
      style: GoogleFonts.inter(
        color: AppColors.emerald200.withValues(alpha: 0.40),
        fontSize: 11,
        letterSpacing: 2,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildSurahCard(SurahProgress p) {
    final surah = QuranRepository().getSurah(p.surahNumber);
    final name = surah?.name ?? 'Surah ${p.surahNumber}';
    final totalAyat = surah?.ayat.length ?? 1;
    final fraction = (p.totalAyatMemorized / totalAyat).clamp(0.0, 1.0);

    return GlassPanel(
      borderRadius: 16,
      padding: const EdgeInsets.all(16),
      child: InkWell(
        onTap: () {
          if (surah == null) return;
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => MutasawiSessionScreen(surah: surah),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    name,
                    style: GoogleFonts.amiri(color: Colors.white, fontSize: 16),
                  ),
                ),
                Text(
                  '${(fraction * 100).toInt()}%',
                  style: GoogleFonts.inter(
                    color: AppColors.emerald400,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: fraction,
                minHeight: 4,
                backgroundColor: Colors.white.withValues(alpha: 0.08),
                valueColor: const AlwaysStoppedAnimation(AppColors.emerald500),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'تم حفظ ${p.totalAyatMemorized} آية  •  عدد الصفحات المكتملة: ${p.chunksCompleted}',
              textDirection: TextDirection.rtl,
              style: GoogleFonts.scheherazadeNew(
                color: AppColors.emerald100.withValues(alpha: 0.40),
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---- Empty state ----
  Widget _buildEmptyState() {
    return GlassPanel(
      borderRadius: 24,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      child: Column(
        children: [
          Icon(
            Icons.menu_book_outlined,
            size: 48,
            color: AppColors.emerald100.withValues(alpha: 0.30),
          ),
          const SizedBox(height: 16),
          Text(
            'ابدأ حفظك الأول من تبويب المكتبة',
            textDirection: TextDirection.rtl,
            style: GoogleFonts.scheherazadeNew(
              color: AppColors.emerald100.withValues(alpha: 0.50),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  // ---- Support / Donation Card ----
  Widget _buildSupportCard() {
    return GlassPanel(
      borderRadius: 24,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '\u062f\u0639\u0645 \u062a\u0637\u0628\u064a\u0642 \u0631\u0627\u0633\u062e',
            textDirection: TextDirection.rtl,
            style: GoogleFonts.scheherazadeNew(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '\u0627\u0644\u062a\u0637\u0628\u064a\u0642 \u0645\u062c\u0627\u0646\u064a \u0628\u0627\u0644\u0643\u0627\u0645\u0644 \u0648\u0628\u062f\u0648\u0646 \u0625\u0639\u0644\u0627\u0646\u0627\u062a. \u0623\u064a \u062a\u0628\u0631\u0639 \u062a\u062f\u0639\u0645\u0647 \u0644\u0646\u0627 \u064a\u064f\u0635\u0631\u0641 \u0628\u0625\u0630\u0646 \u0627\u0644\u0644\u0647 \u0641\u064a \u0633\u062f\u0627\u062f \u062a\u0643\u0627\u0644\u064a\u0641 \u062a\u0637\u0648\u064a\u0631 \u0627\u0644\u062a\u0637\u0628\u064a\u0642 \u0648\u062e\u062f\u0645\u0627\u062a\u0647\u060c \u0648\u0641\u064a \u0635\u062f\u0642\u0629 \u062c\u0627\u0631\u064a\u0629 \u0644\u062f\u0639\u0645 \u062a\u0639\u0644\u064a\u0645 \u0627\u0644\u0642\u0631\u0622\u0646 \u062d\u0648\u0644 \u0627\u0644\u0639\u0627\u0644\u0645.',
            textDirection: TextDirection.rtl,
            style: GoogleFonts.scheherazadeNew(
              color: AppColors.emerald100.withValues(alpha: 0.70),
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 16),
          _donationRow(
            icon: Icons.account_balance,
            label: '\u062a\u062d\u0648\u064a\u0644 \u0628\u0646\u0643\u064a',
            value: '5330383000001966',
          ),
          const SizedBox(height: 10),
          _donationRow(
            icon: Icons.send,
            label: 'InstaPay',
            value: 'yehiawaleed@instapay',
          ),
          const SizedBox(height: 10),
          _donationRow(
            icon: Icons.language,
            label: 'PayPal',
            value: 'paypal.me/SepsM',
            isLink: true,
          ),
          const SizedBox(height: 16),
          Text(
            '\u062e\u0627\u0631\u0637\u0629 \u0627\u0644\u0637\u0631\u064a\u0642: \u0639\u0646\u062f \u0648\u0635\u0648\u0644 \u0627\u0644\u062f\u0639\u0645 \u0625\u0644\u0649 \u062d\u062f \u0645\u0639\u064a\u0651\u0646 \u0633\u0646\u0636\u064a\u0641 \u0628\u0625\u0630\u0646 \u0627\u0644\u0644\u0647 \u0645\u0632\u0627\u0645\u0646\u0629 \u0633\u062d\u0627\u0628\u064a\u0629 \u0628\u064a\u0646 \u0627\u0644\u0623\u062c\u0647\u0632\u0629\u060c \u0644\u0648\u062d\u0629 \u0645\u062a\u0627\u0628\u0639\u0629 \u0644\u0644\u062d\u0641\u0638\u060c \u0648\u0645\u0632\u0627\u064a\u0627 \u0623\u062e\u0631\u0649 \u0644\u062a\u062d\u0633\u064a\u0646 \u062a\u062c\u0631\u0628\u062a\u0643 \u0645\u0639 \u0627\u0644\u062d\u0641\u0638 \u0648\u0627\u0644\u0645\u0631\u0627\u062c\u0639\u0629.',
            textDirection: TextDirection.rtl,
            style: GoogleFonts.scheherazadeNew(
              color: AppColors.emerald100.withValues(alpha: 0.70),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _donationRow({
    required IconData icon,
    required String label,
    required String value,
    bool isLink = false,
  }) {
    return InkWell(
      onTap: () async {
        if (isLink) {
          final uri = Uri.parse('https://$value');
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        } else {
          await Clipboard.setData(ClipboardData(text: value));
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('\u062a\u0645 \u0646\u0633\u062e $label'),
                duration: const Duration(seconds: 2),
              ),
            );
          }
        }
      },
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.emerald400),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  textDirection: TextDirection.rtl,
                  style: GoogleFonts.scheherazadeNew(
                    color: Colors.white,
                    fontSize: 15,
                  ),
                ),
                Text(
                  value,
                  textDirection: TextDirection.ltr,
                  style: GoogleFonts.inter(
                    color: AppColors.emerald100.withValues(alpha: 0.80),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---- Custom Painters ----

/// Decorative wave for the streak card.
class _WavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.emerald500.withValues(alpha: 0.20)
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, size.height)
      ..lineTo(0, size.height * 0.5)
      ..quadraticBezierTo(
        size.width * 0.25,
        0,
        size.width * 0.5,
        size.height * 0.75,
      )
      ..quadraticBezierTo(
        size.width * 0.75,
        size.height * 0.4,
        size.width,
        size.height * 0.25,
      )
      ..lineTo(size.width, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Circular progress ring for memorization percentage.
class _ProgressRingPainter extends CustomPainter {
  final double progress; // 0.0 to 1.0

  _ProgressRingPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;
    const strokeWidth = 8.0;

    final bgPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.10)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, bgPaint);

    final fgPaint = Paint()
      ..color = AppColors.emerald500
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ProgressRingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
