import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/quran_repository.dart';
import '../data/progress_repository.dart';
import '../data/mutasawi_logic.dart';
import '../theme/app_theme.dart';
import '../theme/glass_widgets.dart';
import 'mutasawi_session_screen.dart';

// Canonical surah names used for search only.
class SurahSearchNames {
  static const Map<int, String> arabic = {
    1: 'الفاتحة',
    2: 'البقرة',
    3: 'آل عمران',
    4: 'النساء',
    5: 'المائدة',
    6: 'الأنعام',
    7: 'الأعراف',
    8: 'الأنفال',
    9: 'التوبة',
    10: 'يونس',
    11: 'هود',
    12: 'يوسف',
    13: 'الرعد',
    14: 'إبراهيم',
    15: 'الحجر',
    16: 'النحل',
    17: 'الإسراء',
    18: 'الكهف',
    19: 'مريم',
    20: 'طه',
    21: 'الأنبياء',
    22: 'الحج',
    23: 'المؤمنون',
    24: 'النور',
    25: 'الفرقان',
    26: 'الشعراء',
    27: 'النمل',
    28: 'القصص',
    29: 'العنكبوت',
    30: 'الروم',
    31: 'لقمان',
    32: 'السجدة',
    33: 'الأحزاب',
    34: 'سبأ',
    35: 'فاطر',
    36: 'يس',
    37: 'الصافات',
    38: 'ص',
    39: 'الزمر',
    40: 'غافر',
    41: 'فصلت',
    42: 'الشورى',
    43: 'الزخرف',
    44: 'الدخان',
    45: 'الجاثية',
    46: 'الأحقاف',
    47: 'محمد',
    48: 'الفتح',
    49: 'الحجرات',
    50: 'ق',
    51: 'الذاريات',
    52: 'الطور',
    53: 'النجم',
    54: 'القمر',
    55: 'الرحمن',
    56: 'الواقعة',
    57: 'الحديد',
    58: 'المجادلة',
    59: 'الحشر',
    60: 'الممتحنة',
    61: 'الصف',
    62: 'الجمعة',
    63: 'المنافقون',
    64: 'التغابن',
    65: 'الطلاق',
    66: 'التحريم',
    67: 'الملك',
    68: 'القلم',
    69: 'الحاقة',
    70: 'المعارج',
    71: 'نوح',
    72: 'الجن',
    73: 'المزمل',
    74: 'المدثر',
    75: 'القيامة',
    76: 'الإنسان',
    77: 'المرسلات',
    78: 'النبأ',
    79: 'النازعات',
    80: 'عبس',
    81: 'التكوير',
    82: 'الانفطار',
    83: 'المطففين',
    84: 'الانشقاق',
    85: 'البروج',
    86: 'الطارق',
    87: 'الأعلى',
    88: 'الغاشية',
    89: 'الفجر',
    90: 'البلد',
    91: 'الشمس',
    92: 'الليل',
    93: 'الضحى',
    94: 'الشرح',
    95: 'التين',
    96: 'العلق',
    97: 'القدر',
    98: 'البينة',
    99: 'الزلزلة',
    100: 'العاديات',
    101: 'القارعة',
    102: 'التكاثر',
    103: 'العصر',
    104: 'الهمزة',
    105: 'الفيل',
    106: 'قريش',
    107: 'الماعون',
    108: 'الكوثر',
    109: 'الكافرون',
    110: 'النصر',
    111: 'المسد',
    112: 'الإخلاص',
    113: 'الفلق',
    114: 'الناس',
  };

  static const Map<int, String> english = {
    1: 'Al-Fatihah',
    2: 'Al-Baqarah',
    3: 'Aal Imran',
    4: 'An-Nisa',
    5: 'Al-Maidah',
    6: 'Al-Anam',
    7: 'Al-Araf',
    8: 'Al-Anfal',
    9: 'At-Tawbah',
    10: 'Yunus',
    11: 'Hud',
    12: 'Yusuf',
    13: 'Ar-Rad',
    14: 'Ibrahim',
    15: 'Al-Hijr',
    16: 'An-Nahl',
    17: 'Al-Isra',
    18: 'Al-Kahf',
    19: 'Maryam',
    20: 'Ta-Ha',
    21: 'Al-Anbiya',
    22: 'Al-Hajj',
    23: 'Al-Muminun',
    24: 'An-Nur',
    25: 'Al-Furqan',
    26: 'Ash-Shuara',
    27: 'An-Naml',
    28: 'Al-Qasas',
    29: 'Al-Ankabut',
    30: 'Ar-Rum',
    31: 'Luqman',
    32: 'As-Sajdah',
    33: 'Al-Ahzab',
    34: 'Saba',
    35: 'Fatir',
    36: 'Ya-Sin',
    37: 'As-Saffat',
    38: 'Sad',
    39: 'Az-Zumar',
    40: 'Ghafir',
    41: 'Fussilat',
    42: 'Ash-Shura',
    43: 'Az-Zukhruf',
    44: 'Ad-Dukhan',
    45: 'Al-Jathiyah',
    46: 'Al-Ahqaf',
    47: 'Muhammad',
    48: 'Al-Fath',
    49: 'Al-Hujurat',
    50: 'Qaf',
    51: 'Adh-Dhariyat',
    52: 'At-Tur',
    53: 'An-Najm',
    54: 'Al-Qamar',
    55: 'Ar-Rahman',
    56: 'Al-Waqiah',
    57: 'Al-Hadid',
    58: 'Al-Mujadilah',
    59: 'Al-Hashr',
    60: 'Al-Mumtahanah',
    61: 'As-Saff',
    62: 'Al-Jumuah',
    63: 'Al-Munafiqun',
    64: 'At-Taghabun',
    65: 'At-Talaq',
    66: 'At-Tahrim',
    67: 'Al-Mulk',
    68: 'Al-Qalam',
    69: 'Al-Haqqah',
    70: 'Al-Maarij',
    71: 'Nuh',
    72: 'Al-Jinn',
    73: 'Al-Muzzammil',
    74: 'Al-Muddathir',
    75: 'Al-Qiyamah',
    76: 'Al-Insan',
    77: 'Al-Mursalat',
    78: 'An-Naba',
    79: 'An-Naziat',
    80: 'Abasa',
    81: 'At-Takwir',
    82: 'Al-Infitar',
    83: 'Al-Mutaffifin',
    84: 'Al-Inshiqaq',
    85: 'Al-Buruj',
    86: 'At-Tariq',
    87: 'Al-Ala',
    88: 'Al-Ghashiyah',
    89: 'Al-Fajr',
    90: 'Al-Balad',
    91: 'Ash-Shams',
    92: 'Al-Layl',
    93: 'Ad-Duha',
    94: 'Ash-Sharh',
    95: 'At-Tin',
    96: 'Al-Alaq',
    97: 'Al-Qadr',
    98: 'Al-Bayyinah',
    99: 'Az-Zalzalah',
    100: 'Al-Adiyat',
    101: 'Al-Qariah',
    102: 'At-Takathur',
    103: 'Al-Asr',
    104: 'Al-Humazah',
    105: 'Al-Fil',
    106: 'Quraysh',
    107: 'Al-Maun',
    108: 'Al-Kawthar',
    109: 'Al-Kafirun',
    110: 'An-Nasr',
    111: 'Al-Masad',
    112: 'Al-Ikhlas',
    113: 'Al-Falaq',
    114: 'An-Nas',
  };
}

/// Library / Home screen — live Hifz dashboard.
class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final _progress = ProgressController();
  final _repo = QuranRepository();
  String _searchQuery = '';

  // Normalizes Arabic/English strings for search.
  static String normalizeQuery(String value) {
    var v = value.trim().toLowerCase();

    // Normalize common variations of "Al" at the start.
    if (v.startsWith('al-')) v = v.substring(3);
    if (v.startsWith('al ')) v = v.substring(3);

    // Remove optional "sura/surah" in English.
    if (v.startsWith('sura ')) v = v.substring(5);
    if (v.startsWith('surah ')) v = v.substring(6);

    // Remove optional "سورة" prefix in Arabic (with or without space).
    if (v.startsWith('سورة ')) v = v.substring('سورة '.length);
    if (v.startsWith('سورة')) v = v.substring('سورة'.length);

    // Strip common Arabic diacritics (harakat) so text without
    // tashkeel still matches.
    const diacritics = [
      '\u064E',
      '\u064B',
      '\u064F',
      '\u064C',
      '\u0650',
      '\u064D',
      '\u0652',
      '\u0651',
    ];
    for (final d in diacritics) {
      v = v.replaceAll(d, '');
    }

    return v;
  }

  List<Surah> _filterSurahs(List<Surah> source) {
    final q = normalizeQuery(_searchQuery);
    if (q.isEmpty) return source;
    return source.where((s) {
      final canonicalArabic = normalizeQuery(
        SurahSearchNames.arabic[s.number] ?? s.name,
      );
      final canonicalEnglish = normalizeQuery(
        SurahSearchNames.english[s.number] ?? s.english,
      );
      return canonicalArabic.contains(q) || canonicalEnglish.contains(q);
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _progress.addListener(_onChanged);
  }

  @override
  void dispose() {
    _progress.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  void _openSurah(Surah surah) {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (_) => MutasawiSessionScreen(surah: surah),
          ),
        )
        .then((_) {
          // Refresh when coming back from session
          if (mounted) setState(() {});
        });
  }

  @override
  Widget build(BuildContext context) {
    final surahProgress = _progress.loadAllSurahProgress();
    final allSurahs = _repo.getAllSurahs();
    final lastPos = _progress.lastPosition;

    final startedNumbers = <int>{
      ...surahProgress.keys,
      if (lastPos != null) lastPos.surahNumber,
    };

    final notStarted = <Surah>[];
    final inProgress = <Surah>[];
    final completed = <Surah>[];

    for (final s in allSurahs) {
      final sp = surahProgress[s.number];
      final totalChunks = buildChunks(s.ayat).length;

      if (!startedNumbers.contains(s.number)) {
        notStarted.add(s);
      } else if (sp != null &&
          sp.chunksCompleted >= totalChunks &&
          totalChunks > 0) {
        completed.add(s);
      } else {
        inProgress.add(s);
      }
    }

    final inProgressFiltered = _filterSurahs(inProgress);
    final completedFiltered = _filterSurahs(completed);
    final notStartedFiltered = _filterSurahs(notStarted);

    final noResults =
        _searchQuery.trim().isNotEmpty &&
        inProgressFiltered.isEmpty &&
        completedFiltered.isEmpty &&
        notStartedFiltered.isEmpty;

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          _buildSearchBar(),
          const SizedBox(height: 28),
          _buildContinueCard(lastPos),
          const SizedBox(height: 28),

          if (noResults)
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Text(
                '\u0644\u0627 \u062a\u0648\u062c\u062f \u0633\u0648\u0631\u0629 \u0645\u0637\u0627\u0628\u0642\u0629 \u0644\u0628\u062d\u062b\u0643.',
                textDirection: TextDirection.rtl,
                style: GoogleFonts.scheherazadeNew(
                  color: Colors.white.withValues(alpha: 0.60),
                  fontSize: 15,
                ),
              ),
            ),

          // In Progress surahs
          if (inProgressFiltered.isNotEmpty) ...[
            _sectionTitle('قيد الحفظ', count: inProgressFiltered.length),
            const SizedBox(height: 12),
            ...inProgressFiltered.map(
              (s) => _buildSurahCard(s, surahProgress[s.number]),
            ),
            const SizedBox(height: 24),
          ],

          // Completed surahs
          if (completedFiltered.isNotEmpty) ...[
            _sectionTitle('مكتمل', count: completedFiltered.length),
            const SizedBox(height: 12),
            ...completedFiltered.map(
              (s) => _buildSurahCard(s, surahProgress[s.number]),
            ),
            const SizedBox(height: 24),
          ],

          // Not Started surahs
          if (notStartedFiltered.isNotEmpty) ...[
            _sectionTitle('لم يبدأ بعد', count: notStartedFiltered.length),
            const SizedBox(height: 12),
            ...notStartedFiltered.map((s) => _buildSurahCard(s, null)),
          ],
        ],
      ),
    );
  }

  // ===========================================================================
  // Header
  // ===========================================================================
  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _progress.streakDays > 0
                  ? '🔥 ${_progress.streakDays} DAY STREAK'
                  : 'RASYKH',
              style: GoogleFonts.inter(
                color: AppColors.emerald200,
                fontSize: 12,
                fontWeight: FontWeight.w500,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 4),
            RichText(
              text: TextSpan(
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w300,
                ),
                children: [
                  const TextSpan(text: 'Welcome back, '),
                  TextSpan(
                    text: 'Hafiz',
                    style: GoogleFonts.inter(
                      color: AppColors.emerald400,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        GlassButton(
          child: Icon(
            Icons.settings_outlined,
            size: 20,
            color: AppColors.emerald100.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // Search Bar
  // ===========================================================================
  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: TextField(
        style: GoogleFonts.inter(color: AppColors.emerald100),
        textDirection: TextDirection.ltr,
        onChanged: (value) => setState(() => _searchQuery = value),
        decoration: InputDecoration(
          hintText: 'Search Surah, Ayah, or Topic...',
          hintStyle: GoogleFonts.inter(
            color: AppColors.emerald100.withValues(alpha: 0.30),
          ),
          prefixIcon: Icon(
            Icons.search,
            color: AppColors.emerald100.withValues(alpha: 0.40),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 18,
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // Continue Memorizing card
  // ===========================================================================
  Widget _buildContinueCard(LastPosition? lastPos) {
    final Surah? surah = lastPos != null
        ? _repo.getSurah(lastPos.surahNumber)
        : null;

    final String surahName = surah?.name ?? 'Start Memorizing';
    final String surahNum = surah != null ? '${surah.number}' : '—';
    final String subtitle = lastPos != null
        ? 'Ayah ${lastPos.ayahNumber} • Chunk ${lastPos.chunkIndex + 1}'
        : 'Pick a surah below to begin';

    return GestureDetector(
      onTap: surah != null ? () => _openSurah(surah) : null,
      child: GlassPanel(
        borderRadius: 24,
        padding: const EdgeInsets.all(20),
        child: Stack(
          children: [
            Positioned(
              top: -40,
              right: -40,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.emerald500.withValues(alpha: 0.10),
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Number badge
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.emerald500.withValues(alpha: 0.05),
                        border: Border.all(
                          color: AppColors.emerald500.withValues(alpha: 0.30),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        surahNum,
                        style: GoogleFonts.amiri(
                          color: AppColors.emerald200,
                          fontSize: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'CONTINUE MEMORIZING',
                            style: GoogleFonts.inter(
                              color: AppColors.emerald200,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            surahName,
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            style: GoogleFonts.inter(
                              color: AppColors.emerald100.withValues(
                                alpha: 0.60,
                              ),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Stats chips
                Row(
                  children: [
                    _statChip(
                      Icons.auto_awesome,
                      '${_progress.totalAyatMemorized} ayat',
                    ),
                    const SizedBox(width: 12),
                    _statChip(
                      Icons.local_fire_department,
                      '${_progress.streakDays} day streak',
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Expanded(child: SizedBox.shrink()),
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.emerald500,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.emerald500.withValues(alpha: 0.4),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.play_arrow, color: Colors.white),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.emerald400),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              color: AppColors.emerald100.withValues(alpha: 0.60),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // Section Title
  // ===========================================================================
  Widget _sectionTitle(String title, {int? count}) {
    return Row(
      children: [
        Text(
          title,
          textDirection: TextDirection.rtl,
          style: GoogleFonts.scheherazadeNew(
            color: Colors.white.withValues(alpha: 0.80),
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (count != null) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.emerald500.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$count',
              style: GoogleFonts.inter(
                color: AppColors.emerald400,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );
  }

  // ===========================================================================
  // Surah Card
  // ===========================================================================
  Widget _buildSurahCard(Surah surah, SurahProgress? sp) {
    final totalAyat = surah.ayat.length;
    final memorized = sp?.totalAyatMemorized ?? 0;
    final fraction = totalAyat > 0 ? memorized / totalAyat : 0.0;
    final totalChunks = buildChunks(surah.ayat).length;
    final chunksCompleted = sp?.chunksCompleted ?? 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () => _openSurah(surah),
        child: GlassPanel(
          borderRadius: 16,
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Number
                  SizedBox(
                    width: 32,
                    child: Text(
                      surah.number.toString().padLeft(2, '0'),
                      style: GoogleFonts.robotoMono(
                        color: AppColors.emerald500.withValues(alpha: 0.50),
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Name + english
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          surah.name,
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          surah.english,
                          style: GoogleFonts.inter(
                            color: AppColors.emerald100.withValues(alpha: 0.40),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Type + verse count
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          surah.type,
                          style: GoogleFonts.inter(
                            color: AppColors.emerald200.withValues(alpha: 0.50),
                            fontSize: 11,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${surah.verses} Ayahs',
                        style: GoogleFonts.inter(
                          color: AppColors.emerald200.withValues(alpha: 0.50),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              // Per-surah progress bar (only if started)
              if (sp != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: fraction.clamp(0.0, 1.0),
                          minHeight: 4,
                          backgroundColor: Colors.white.withValues(alpha: 0.08),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            fraction >= 1.0
                                ? AppColors.emerald400
                                : AppColors.emerald500,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '$memorized / $totalAyat ayat · $chunksCompleted/$totalChunks chunks',
                      style: GoogleFonts.inter(
                        color: AppColors.emerald100.withValues(alpha: 0.40),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
