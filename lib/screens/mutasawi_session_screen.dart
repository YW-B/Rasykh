import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/quran_repository.dart';
import '../data/mutasawi_logic.dart';
import '../data/progress_repository.dart';
import '../theme/app_theme.dart';
import '../theme/glass_widgets.dart';
import '../widgets/ambient_background.dart';
import '../widgets/surah_audio_player.dart';
import 'recall_challenge_screen.dart';

//Mutasawi session screen

/// Default repetition target per ayah.
const int kRepetitionTarget = 20;

/// Phases of the Mutasawi session within a single chunk.
enum SessionPhase {
  section1,
  linkSection1,
  section2,
  linkSection2,
  section3,
  linkAll,
  complete,
}

/// Full-screen Mutasawi memorization session for one Surah.
///
/// Flow:  Chunk picker → Overview (3 sections) → Drill → Link → Complete
class MutasawiSessionScreen extends StatefulWidget {
  final Surah surah;

  const MutasawiSessionScreen({super.key, required this.surah});

  @override
  State<MutasawiSessionScreen> createState() => _MutasawiSessionScreenState();
}

class _MutasawiSessionScreenState extends State<MutasawiSessionScreen> {
  late final List<MemorizationChunk> _chunks;

  // null → chunk picker is shown.  non-null → session is active.
  MemorizationChunk? _activeChunk;
  List<List<Ayah>> _sections = [];
  SessionPhase _phase = SessionPhase.section1;
  List<List<int>> _reps = [];
  int _currentAyahIndex = 0;
  bool _isDrilling = false;

  @override
  void initState() {
    super.initState();
    _chunks = buildChunks(widget.surah.ayat);

    final pc = ProgressController();
    debugPrint(
      '[Mutasawi] init for surah ${widget.surah.number}, '
      'chunks=${_chunks.length}',
    );
    debugPrint('[Mutasawi] lastPosition = ${pc.loadLastPosition()}');

    // Auto-select if only one chunk — restore saved state if available.
    if (_chunks.length == 1) {
      final saved = pc.loadChunkProgress(
        widget.surah.number,
        _chunks.first.index,
      );
      final lastPos = pc.loadLastPosition();
      debugPrint('[Mutasawi] auto-select chunk 0, saved=$saved');
      _initChunk(_chunks.first, saved: saved, lastPos: lastPos);
    }
  }

  /// Set up internal state for a chunk, optionally restoring from saved state.
  void _initChunk(
    MemorizationChunk chunk, {
    ChunkProgress? saved,
    LastPosition? lastPos,
  }) {
    _activeChunk = chunk;
    _sections = splitIntoThreeSections(chunk.ayat);
    _reps = _sections.map((s) => List.filled(s.length, 0)).toList();
    _phase = SessionPhase.section1;
    _currentAyahIndex = 0;
    _isDrilling = false;

    // Restore completed sections from saved chunk progress.
    if (saved != null) {
      final completed = saved.completedSections.clamp(0, 3);

      // Mark completed sections' reps as done so they show 100%.
      for (int s = 0; s < completed && s < _sections.length; s++) {
        for (int a = 0; a < _reps[s].length; a++) {
          _reps[s][a] = kRepetitionTarget;
        }
      }

      // Set phase to the next incomplete section.
      if (completed >= 1) _phase = SessionPhase.section2;
      if (completed >= 2) _phase = SessionPhase.section3;

      // If chunk fully completed, jump to complete phase.
      if (saved.completedMemorization) {
        if (completed >= 3) {
          for (int s = 0; s < _sections.length; s++) {
            for (int a = 0; a < _reps[s].length; a++) {
              _reps[s][a] = kRepetitionTarget;
            }
          }
        }
        _phase = SessionPhase.complete;
      }
    }

    // If we have a lastPosition inside this chunk, position the drill there.
    if (lastPos != null &&
        lastPos.surahNumber == widget.surah.number &&
        lastPos.chunkIndex == chunk.index &&
        _phase != SessionPhase.complete) {
      final flatAyat = chunk.ayat;
      final idx = flatAyat.indexWhere((a) => a.number == lastPos.ayahNumber);
      if (idx != -1) {
        // Map flat index to section + index within section.
        int remaining = idx;
        for (int s = 0; s < _sections.length; s++) {
          if (remaining < _sections[s].length) {
            // Only reposition if this section is unlocked (not yet completed).
            final sectionPhase = SessionPhase.values[s * 2];
            if (_phase.index <= sectionPhase.index) {
              _phase = sectionPhase;
              _currentAyahIndex = remaining;
            }
            break;
          } else {
            remaining -= _sections[s].length;
          }
        }
      }
    }
  }

  /// Called when user explicitly taps a chunk card — loads saved state.
  Future<void> _selectChunk(MemorizationChunk chunk) async {
    final pc = ProgressController();
    final savedChunk = pc.loadChunkProgress(widget.surah.number, chunk.index);
    final lastPos = pc.loadLastPosition();

    debugPrint(
      '[Mutasawi] selectChunk ${chunk.index} for surah '
      '${widget.surah.number}, saved=$savedChunk, lastPos=$lastPos',
    );

    setState(() {
      _initChunk(chunk, saved: savedChunk, lastPos: lastPos);
    });

    // Only set initial lastPosition if there's no existing position for
    // this chunk (first time ever).
    if (chunk.ayat.isNotEmpty &&
        (lastPos == null ||
            lastPos.surahNumber != widget.surah.number ||
            lastPos.chunkIndex != chunk.index)) {
      await pc.saveLastPosition(
        LastPosition(
          surahNumber: widget.surah.number,
          chunkIndex: chunk.index,
          ayahNumber: chunk.ayat.first.number,
        ),
      );
    }
  }

  void _backToChunkPicker() {
    setState(() {
      _activeChunk = null;
      _sections = [];
      _reps = [];
      _phase = SessionPhase.section1;
      _currentAyahIndex = 0;
      _isDrilling = false;
    });
  }

  // ---- Helpers ----

  int get _activeSectionIndex {
    switch (_phase) {
      case SessionPhase.section1:
      case SessionPhase.linkSection1:
        return 0;
      case SessionPhase.section2:
      case SessionPhase.linkSection2:
        return 1;
      case SessionPhase.section3:
      case SessionPhase.linkAll:
      case SessionPhase.complete:
        return 2;
    }
  }

  bool _isSectionUnlocked(int sectionIndex) {
    switch (sectionIndex) {
      case 0:
        return true;
      case 1:
        return _phase.index >= SessionPhase.section2.index;
      case 2:
        return _phase.index >= SessionPhase.section3.index;
      default:
        return false;
    }
  }

  bool _isSectionComplete(int sectionIndex) {
    if (!_isSectionUnlocked(sectionIndex)) return false;
    if (_sections[sectionIndex].isEmpty) return true;
    return _reps[sectionIndex].every((r) => r >= kRepetitionTarget);
  }

  double _sectionProgress(int sectionIndex) {
    final section = _sections[sectionIndex];
    if (section.isEmpty) return 1.0;
    final total = section.length * kRepetitionTarget;
    final done = _reps[sectionIndex].fold<int>(
      0,
      (sum, r) => sum + r.clamp(0, kRepetitionTarget),
    );
    return done / total;
  }

  bool get _isLinkPhase =>
      _phase == SessionPhase.linkSection1 ||
      _phase == SessionPhase.linkSection2 ||
      _phase == SessionPhase.linkAll;

  String get _linkLabel {
    switch (_phase) {
      case SessionPhase.linkSection1:
        return 'Link Section 1';
      case SessionPhase.linkSection2:
        return 'Link Sections 1 & 2';
      case SessionPhase.linkAll:
        return 'Link All 3 Sections';
      default:
        return '';
    }
  }

  int _computeCompletedSections() {
    int count = 0;
    for (int i = 0; i < _sections.length; i++) {
      if (_isSectionComplete(i)) count++;
    }
    return count;
  }

  /// Advance to the next session phase. Handles chunk completion.
  void _advancePhase() {
    setState(() {
      final nextIndex = _phase.index + 1;
      if (nextIndex < SessionPhase.values.length) {
        _phase = SessionPhase.values[nextIndex];
        _currentAyahIndex = 0;
        _isDrilling = false;
      }
    });

    // If we just entered the complete phase, mark the chunk as done.
    if (_phase == SessionPhase.complete && _activeChunk != null) {
      final currentIdx = _activeChunk!.index;
      final hasNext = currentIdx + 1 < _chunks.length;
      final nextChunk = hasNext ? _chunks[currentIdx + 1] : null;

      // Last ayah number of this chunk.
      final lastAyah = _activeChunk!.ayat.isNotEmpty
          ? _activeChunk!.ayat.last.number
          : 0;

      ProgressController().markChunkCompleted(
        surahNumber: widget.surah.number,
        chunkIndex: currentIdx,
        ayatCount: _activeChunk!.ayat.length,
        lastAyahNumber: lastAyah,
        nextChunkIndex: nextChunk?.index,
        nextChunkFirstAyah: nextChunk != null && nextChunk.ayat.isNotEmpty
            ? nextChunk.ayat.first.number
            : null,
      );
    }
  }

  Future<void> _incrementRep() async {
    final chunk = _activeChunk;
    if (chunk == null) return;

    final si = _activeSectionIndex;

    // Increment the rep counter.
    setState(() {
      _reps[si][_currentAyahIndex]++;
    });

    // Save position + chunk progress at the CURRENT ayah before any
    // phase change.
    final currentAyah = _sections[si][_currentAyahIndex];
    final completedSections = _computeCompletedSections();
    final pc = ProgressController();

    await pc.saveChunkProgress(
      ChunkProgress(
        surahNumber: widget.surah.number,
        chunkIndex: chunk.index,
        ayatCount: chunk.ayat.length,
        completedMemorization: false,
        lastAyahNumberInsideChunk: currentAyah.number,
        completedSections: completedSections,
      ),
    );

    await pc.saveLastPosition(
      LastPosition(
        surahNumber: widget.surah.number,
        chunkIndex: chunk.index,
        ayahNumber: currentAyah.number,
      ),
    );

    // Check if this ayah is now done.
    if (_reps[si][_currentAyahIndex] >= kRepetitionTarget) {
      if (_currentAyahIndex < _sections[si].length - 1) {
        // Move to next ayah within the section.
        setState(() {
          _currentAyahIndex++;
        });
        // Save position at the NEW ayah.
        final nextAyah = _sections[si][_currentAyahIndex];
        await pc.saveLastPosition(
          LastPosition(
            surahNumber: widget.surah.number,
            chunkIndex: chunk.index,
            ayahNumber: nextAyah.number,
          ),
        );
      } else {
        // Section finished → advance phase.
        _advancePhase();
      }
    }
  }

  void _startDrilling(int sectionIndex) {
    if (!_isSectionUnlocked(sectionIndex)) return;
    if (_isSectionComplete(sectionIndex)) return;
    setState(() {
      _isDrilling = true;
      _currentAyahIndex = _reps[sectionIndex]
          .indexWhere((r) => r < kRepetitionTarget)
          .clamp(0, _sections[sectionIndex].length - 1);
    });
    // Save position when user starts drilling.
    if (_activeChunk != null) {
      final ayah = _sections[sectionIndex][_currentAyahIndex];
      ProgressController().saveLastPosition(
        LastPosition(
          surahNumber: widget.surah.number,
          chunkIndex: _activeChunk!.index,
          ayahNumber: ayah.number,
        ),
      );
    }
  }

  // ---- Build ----

  @override
  Widget build(BuildContext context) {
    late final Widget content;

    if (_activeChunk == null) {
      content = _buildChunkPicker();
    } else if (_phase == SessionPhase.complete) {
      content = _buildComplete();
    } else if (_isLinkPhase) {
      content = _buildLinkStep();
    } else if (_isDrilling) {
      content = _buildDrill();
    } else {
      content = _buildOverview();
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          const AmbientBackground(),
          SafeArea(bottom: false, child: content),
        ],
      ),
    );
  }

  // ---- App Bar ----
  Widget _buildAppBar({required String title, VoidCallback? onBack}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Row(
        children: [
          GlassButton(
            onTap:
                onBack ??
                () {
                  if (_isDrilling) {
                    setState(() => _isDrilling = false);
                  } else if (_activeChunk != null && _chunks.length > 1) {
                    _backToChunkPicker();
                  } else {
                    Navigator.of(context).pop();
                  }
                },
            padding: const EdgeInsets.all(8),
            child: Icon(
              Icons.arrow_back,
              size: 20,
              color: AppColors.emerald100.withValues(alpha: 0.70),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // CHUNK PICKER
  // ===========================================================================
  Widget _buildChunkPicker() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAppBar(
            title: widget.surah.name,
            onBack: () => Navigator.of(context).pop(),
          ),
          const SizedBox(height: 8),
          Text(
            'CHOOSE A CHUNK',
            style: GoogleFonts.inter(
              color: AppColors.emerald200.withValues(alpha: 0.50),
              fontSize: 11,
              letterSpacing: 2,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${widget.surah.ayat.length} ayat in ${_chunks.length} chunks of up to 10',
            style: GoogleFonts.inter(
              color: AppColors.emerald100.withValues(alpha: 0.40),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView.separated(
              itemCount: _chunks.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, i) => _buildChunkCard(_chunks[i]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChunkCard(MemorizationChunk chunk) {
    final completed = ProgressController().isChunkCompleted(
      widget.surah.number,
      chunk.index,
    );
    final recallDone = ProgressController().isRecallCompleted(
      widget.surah.number,
      chunk.index,
    );
    return GlassPanel(
      borderRadius: 16,
      padding: const EdgeInsets.all(18),
      child: InkWell(
        onTap: () => _selectChunk(chunk),
        borderRadius: BorderRadius.circular(16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: completed
                    ? AppColors.emerald400.withValues(alpha: 0.15)
                    : AppColors.emerald500.withValues(alpha: 0.10),
                border: Border.all(
                  color: completed
                      ? AppColors.emerald400.withValues(alpha: 0.40)
                      : AppColors.emerald500.withValues(alpha: 0.25),
                ),
              ),
              alignment: Alignment.center,
              child: completed
                  ? const Icon(
                      Icons.check,
                      size: 20,
                      color: AppColors.emerald400,
                    )
                  : Text(
                      '${chunk.index + 1}',
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
                    'الجزء ${chunk.index + 1}',
                    textDirection: TextDirection.rtl,
                    style: GoogleFonts.scheherazadeNew(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        '${chunk.rangeLabel} • ${chunk.ayat.length} ayat',
                        style: GoogleFonts.inter(
                          color: AppColors.emerald100.withValues(alpha: 0.40),
                          fontSize: 12,
                        ),
                      ),
                      if (recallDone) ...[
                        const SizedBox(width: 6),
                        Icon(
                          Icons.psychology,
                          size: 12,
                          color: AppColors.emerald400.withValues(alpha: 0.70),
                        ),
                        const SizedBox(width: 2),
                        Text(
                          'Recall ✓',
                          style: GoogleFonts.inter(
                            color: AppColors.emerald400.withValues(alpha: 0.70),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Icon(
              completed ? Icons.replay : Icons.chevron_right,
              size: 20,
              color: AppColors.emerald100.withValues(alpha: 0.40),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // OVERVIEW — 3 section cards for the active chunk
  // ===========================================================================
  Widget _buildOverview() {
    final chunk = _activeChunk!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAppBar(title: widget.surah.name),
          const SizedBox(height: 8),
          Text(
            'MUTASAWI METHOD — ${chunk.rangeLabel}'.toUpperCase(),
            style: GoogleFonts.inter(
              color: AppColors.emerald200.withValues(alpha: 0.50),
              fontSize: 11,
              letterSpacing: 2,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${chunk.ayat.length} ayat split into 3 sections',
            style: GoogleFonts.inter(
              color: AppColors.emerald100.withValues(alpha: 0.40),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),
          SurahAudioPlayer(surahNumber: widget.surah.number),
          const SizedBox(height: 24),
          Expanded(
            child: ListView(
              children: [
                for (int i = 0; i < 3; i++) ...[
                  _buildSectionCard(i),
                  const SizedBox(height: 14),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
  // I manually edited Line 620 to 623 to add the SurahAudioPlayer widget

  Widget _buildSectionCard(int index) {
    final section = _sections[index];
    final unlocked = _isSectionUnlocked(index);
    final complete = _isSectionComplete(index);
    final progress = _sectionProgress(index);

    final isActive =
        index == _activeSectionIndex &&
        !_isLinkPhase &&
        _phase != SessionPhase.complete;

    final rangeLabel = section.isEmpty
        ? '(empty)'
        : 'Ayah ${section.first.number} – ${section.last.number}';

    return GlassPanel(
      borderRadius: 20,
      borderColor: isActive
          ? AppColors.emerald500.withValues(alpha: 0.40)
          : null,
      padding: const EdgeInsets.all(20),
      child: InkWell(
        onTap: unlocked && !complete ? () => _startDrilling(index) : null,
        borderRadius: BorderRadius.circular(20),
        child: Opacity(
          opacity: unlocked ? 1.0 : 0.45,
          child: Row(
            children: [
              SizedBox(
                width: 56,
                height: 56,
                child: CustomPaint(
                  painter: _MiniRingPainter(
                    progress: progress,
                    color: complete
                        ? AppColors.emerald400
                        : AppColors.emerald500,
                  ),
                  child: Center(
                    child: complete
                        ? const Icon(
                            Icons.check,
                            size: 22,
                            color: AppColors.emerald400,
                          )
                        : Text(
                            '${(progress * 100).toInt()}%',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'المقطع ${index + 1}',
                      textDirection: TextDirection.rtl,
                      style: GoogleFonts.scheherazadeNew(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      rangeLabel,
                      style: GoogleFonts.inter(
                        color: AppColors.emerald100.withValues(alpha: 0.50),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              if (!unlocked)
                Icon(
                  Icons.lock_outline,
                  size: 20,
                  color: AppColors.emerald100.withValues(alpha: 0.30),
                )
              else if (!complete)
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

  // ===========================================================================
  // DRILL — current ayah + repetition counter
  // ===========================================================================
  Widget _buildDrill() {
    final si = _activeSectionIndex;
    final ayah = _sections[si][_currentAyahIndex];
    final reps = _reps[si][_currentAyahIndex];
    final progress = reps / kRepetitionTarget;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: Column(
        children: [
          _buildAppBar(title: 'Section ${si + 1} — Ayah ${ayah.number}'),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 100),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  SurahAudioPlayer(surahNumber: widget.surah.number),
                  const SizedBox(height: 24),

                  // Ayah card — grows as needed.
                  GlassPanel(
                    borderRadius: 24,
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      children: [
                        Text(
                          ayah.arabic,
                          textDirection: TextDirection.rtl,
                          textAlign: TextAlign.center,
                          style: AppTheme.quranTextStyle.copyWith(fontSize: 32),
                        ),
                        if (ayah.english.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Text(
                            ayah.english,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              color: AppColors.emerald100.withValues(
                                alpha: 0.60,
                              ),
                              fontSize: 14,
                              fontWeight: FontWeight.w300,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Repetition counter ring
                  SizedBox(
                    width: 100,
                    height: 100,
                    child: CustomPaint(
                      painter: _MiniRingPainter(
                        progress: progress.clamp(0.0, 1.0),
                        color: AppColors.emerald500,
                        strokeWidth: 6,
                      ),
                      child: Center(
                        child: Text(
                          '$reps / $kRepetitionTarget',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Tap button
                  GestureDetector(
                    onTap: _incrementRep,
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.emerald500,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.emerald500.withValues(alpha: 0.40),
                            blurRadius: 20,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.add,
                        size: 32,
                        color: Colors.white,
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),
                  Text(
                    'اقرأ الآية واضغط على الزر مرة واحدة فقط في كل قراءة',
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.scheherazadeNew(
                      color: AppColors.emerald100.withValues(alpha: 0.30),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // LINK STEP
  // ===========================================================================
  Widget _buildLinkStep() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
      child: Column(
        children: [
          _buildAppBar(title: widget.surah.name),
          const Spacer(),

          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.emerald500.withValues(alpha: 0.15),
              border: Border.all(
                color: AppColors.emerald500.withValues(alpha: 0.30),
              ),
            ),
            child: const Icon(
              Icons.link,
              size: 44,
              color: AppColors.emerald400,
            ),
          ),

          const SizedBox(height: 28),

          Text(
            _linkLabel,
            style: GoogleFonts.amiri(color: Colors.white, fontSize: 26),
          ),

          const SizedBox(height: 12),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'Recite the completed section(s) together from memory to strengthen the links between ayat.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: AppColors.emerald100.withValues(alpha: 0.50),
                fontSize: 14,
                height: 1.6,
              ),
            ),
          ),

          const SizedBox(height: 36),

          GestureDetector(
            onTap: _advancePhase,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              decoration: BoxDecoration(
                color: AppColors.emerald500,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.emerald500.withValues(alpha: 0.40),
                    blurRadius: 20,
                  ),
                ],
              ),
              child: Text(
                'Complete & Continue',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          const Spacer(),
        ],
      ),
    );
  }

  // ===========================================================================
  // COMPLETE — chunk finished
  // ===========================================================================
  Widget _buildComplete() {
    final chunk = _activeChunk!;
    final hasMoreChunks = _chunks.length > 1;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
      child: Column(
        children: [
          _buildAppBar(
            title: widget.surah.name,
            onBack: () => Navigator.of(context).pop(),
          ),
          const Spacer(),

          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.emerald500.withValues(alpha: 0.15),
              border: Border.all(
                color: AppColors.emerald400.withValues(alpha: 0.40),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.emerald500.withValues(alpha: 0.30),
                  blurRadius: 40,
                ),
              ],
            ),
            child: const Icon(
              Icons.check_circle_outline,
              size: 56,
              color: AppColors.emerald400,
            ),
          ),

          const SizedBox(height: 28),

          Text(
            'Chunk Complete!',
            style: GoogleFonts.amiri(color: Colors.white, fontSize: 28),
          ),
          const SizedBox(height: 8),
          Text(
            '${widget.surah.name} — ${chunk.rangeLabel}\nAll 3 sections memorized & linked.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: AppColors.emerald100.withValues(alpha: 0.50),
              fontSize: 14,
            ),
          ),

          const SizedBox(height: 36),

          if (hasMoreChunks)
            GestureDetector(
              onTap: _backToChunkPicker,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: AppColors.emerald500,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  'Next Chunk',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          if (hasMoreChunks) const SizedBox(height: 16),

          GestureDetector(
            onTap: () {
              setState(() {
                _initChunk(_activeChunk!);
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.emerald500.withValues(alpha: 0.40),
                ),
              ),
              child: Text(
                'إعادة الحفظ بالطريقة المتساوي',
                textDirection: TextDirection.rtl,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              decoration: BoxDecoration(
                color: hasMoreChunks
                    ? Colors.transparent
                    : AppColors.emerald500,
                borderRadius: BorderRadius.circular(16),
                border: hasMoreChunks
                    ? Border.all(
                        color: AppColors.emerald500.withValues(alpha: 0.40),
                      )
                    : null,
              ),
              child: Text(
                'Back to Surahs',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: hasMoreChunks ? FontWeight.w400 : FontWeight.w600,
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Recall challenge button
          GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      RecallChallengeScreen(surah: widget.surah, chunk: chunk),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.emerald400.withValues(alpha: 0.40),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.psychology,
                    size: 18,
                    color: AppColors.emerald400.withValues(alpha: 0.80),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Start Recall Challenge',
                    style: GoogleFonts.inter(
                      color: AppColors.emerald400,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const Spacer(),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Small progress ring painter
// ---------------------------------------------------------------------------
class _MiniRingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;

  _MiniRingPainter({
    required this.progress,
    required this.color,
    this.strokeWidth = 5,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final bg = Paint()
      ..color = Colors.white.withValues(alpha: 0.10)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, bg);

    if (progress > 0) {
      final fg = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        fg,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _MiniRingPainter old) =>
      old.progress != progress || old.color != color;
}
