import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/quran_repository.dart';
import '../data/mutasawi_logic.dart';
import '../data/progress_repository.dart';
import '../theme/app_theme.dart';
import '../theme/glass_widgets.dart';
import '../widgets/ambient_background.dart';

/// Active recall challenge: Game A (order) + Game B (next ayah).
class RecallChallengeScreen extends StatefulWidget {
  final Surah surah;
  final MemorizationChunk chunk;

  const RecallChallengeScreen({
    super.key,
    required this.surah,
    required this.chunk,
  });

  @override
  State<RecallChallengeScreen> createState() => _RecallChallengeScreenState();
}

enum _RecallStep { gameA, gameB, complete }

class _RecallChallengeScreenState extends State<RecallChallengeScreen> {
  _RecallStep _step = _RecallStep.gameA;

  // ---- Game A state ----
  late List<Ayah> _shuffledAyat;
  bool _orderChecked = false;
  Set<int> _wrongIndices = {};

  // ---- Game B state ----
  int _questionIndex = 0;
  late List<_NextAyahQuestion> _questions;
  int? _selectedOption;
  bool _answered = false;

  @override
  void initState() {
    super.initState();
    _initGameA();
    _initGameB();
  }

  void _initGameA() {
    _shuffledAyat = List<Ayah>.from(widget.chunk.ayat);
    // Keep shuffling until the order is different from the original.
    final original = widget.chunk.ayat;
    if (original.length > 1) {
      do {
        _shuffledAyat.shuffle(Random());
      } while (_listsEqual(_shuffledAyat, original));
    }
    _orderChecked = false;
    _wrongIndices = {};
  }

  bool _listsEqual(List<Ayah> a, List<Ayah> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i].number != b[i].number) return false;
    }
    return true;
  }

  void _initGameB() {
    _questions = [];
    final ayat = widget.chunk.ayat;
    if (ayat.length < 2) return;

    final rng = Random();
    for (int i = 0; i < ayat.length - 1; i++) {
      final correct = ayat[i + 1];
      // Pick 2 distinct incorrect ayat from the chunk.
      final pool = <Ayah>[
        for (final a in ayat)
          if (a.number != ayat[i].number && a.number != correct.number) a,
      ];
      pool.shuffle(rng);
      final incorrects = pool.take(2).toList();

      final options = <Ayah>[correct, ...incorrects];
      options.shuffle(rng);

      _questions.add(
        _NextAyahQuestion(
          prompt: ayat[i],
          correctAnswer: correct,
          options: options,
        ),
      );
    }
    _questionIndex = 0;
    _selectedOption = null;
    _answered = false;
  }

  // ---- Game A actions ----

  void _checkOrder() {
    final correct = widget.chunk.ayat;
    final wrong = <int>{};
    for (int i = 0; i < _shuffledAyat.length; i++) {
      if (_shuffledAyat[i].number != correct[i].number) {
        wrong.add(i);
      }
    }
    setState(() {
      _orderChecked = true;
      _wrongIndices = wrong;
      if (wrong.isEmpty) {
        // Perfect — move to Game B after brief delay.
        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted) setState(() => _step = _RecallStep.gameB);
        });
      }
    });
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex--;
      final item = _shuffledAyat.removeAt(oldIndex);
      _shuffledAyat.insert(newIndex, item);
      _orderChecked = false;
      _wrongIndices = {};
    });
  }

  // ---- Game B actions ----

  void _selectOption(int index) {
    if (_answered) return;
    final q = _questions[_questionIndex];
    final isCorrect = q.options[index].number == q.correctAnswer.number;

    setState(() {
      _selectedOption = index;
      if (isCorrect) {
        _answered = true;
        // Auto-advance after brief pause.
        Future.delayed(const Duration(milliseconds: 600), () {
          if (!mounted) return;
          if (_questionIndex < _questions.length - 1) {
            setState(() {
              _questionIndex++;
              _selectedOption = null;
              _answered = false;
            });
          } else {
            // All done — mark recall complete & schedule next review.
            final pc = ProgressController();
            pc.markRecallCompleted(widget.surah.number, widget.chunk.index);
            pc.scheduleRecall(
              surahNumber: widget.surah.number,
              chunkIndex: widget.chunk.index,
              wasEasy: true,
            );
            setState(() => _step = _RecallStep.complete);
          }
        });
      } else {
        // Wrong answer — schedule sooner review (chunk stays in queue).
        ProgressController().scheduleRecall(
          surahNumber: widget.surah.number,
          chunkIndex: widget.chunk.index,
          wasEasy: false,
        );
      }
    });
  }

  // ---- Build ----

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
                children: [
                  _buildAppBar(),
                  const SizedBox(height: 8),
                  _buildStepIndicator(),
                  const SizedBox(height: 16),
                  Expanded(child: _buildContent()),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
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
          Expanded(
            child: Text(
              'Recall – ${widget.surah.name}',
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

  Widget _buildStepIndicator() {
    final steps = ['Order Ayat', 'Next Ayah', 'Done'];
    final currentIdx = _step == _RecallStep.gameA
        ? 0
        : (_step == _RecallStep.gameB ? 1 : 2);

    return Row(
      children: List.generate(steps.length, (i) {
        final isActive = i == currentIdx;
        final isDone = i < currentIdx;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i < steps.length - 1 ? 8 : 0),
            child: Column(
              children: [
                Container(
                  height: 4,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    color: isDone
                        ? AppColors.emerald400
                        : isActive
                        ? AppColors.emerald500
                        : Colors.white.withValues(alpha: 0.10),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  steps[i],
                  style: GoogleFonts.inter(
                    color: isActive || isDone
                        ? AppColors.emerald200
                        : AppColors.emerald100.withValues(alpha: 0.30),
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildContent() {
    switch (_step) {
      case _RecallStep.gameA:
        return _buildGameA();
      case _RecallStep.gameB:
        return _buildGameB();
      case _RecallStep.complete:
        return _buildComplete();
    }
  }

  // ===========================================================================
  // GAME A — Order the Ayat
  // ===========================================================================
  Widget _buildGameA() {
    final allCorrect = _orderChecked && _wrongIndices.isEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Drag the ayat into the correct order',
          style: GoogleFonts.inter(
            color: AppColors.emerald100.withValues(alpha: 0.50),
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ReorderableListView.builder(
            itemCount: _shuffledAyat.length,
            onReorder: _onReorder,
            buildDefaultDragHandles: false,
            scrollDirection: Axis.vertical,
            padding: EdgeInsets.zero,
            proxyDecorator: (child, index, animation) {
              return Material(color: Colors.transparent, child: child);
            },
            itemBuilder: (context, i) {
              final ayah = _shuffledAyat[i];
              final isWrong = _wrongIndices.contains(i);
              final borderColor = _orderChecked
                  ? (isWrong
                        ? Colors.redAccent.withValues(alpha: 0.60)
                        : AppColors.emerald400.withValues(alpha: 0.40))
                  : null;

              return Padding(
                key: ValueKey(ayah.number),
                padding: const EdgeInsets.only(bottom: 8),
                child: GlassPanel(
                  borderRadius: 14,
                  borderColor: borderColor,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      ReorderableDragStartListener(
                        index: i,
                        child: Icon(
                          Icons.drag_handle,
                          size: 20,
                          color: AppColors.emerald100.withValues(alpha: 0.30),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          ayah.arabic,
                          textDirection: TextDirection.rtl,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.scheherazadeNew(
                            color: Colors.white,
                            fontSize: 18,
                            height: 1.8,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),

        // Result banner
        if (_orderChecked && !allCorrect)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'Some ayat are out of order. Adjust and try again.',
              style: GoogleFonts.inter(
                color: Colors.redAccent.withValues(alpha: 0.80),
                fontSize: 13,
              ),
            ),
          ),
        if (allCorrect)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.check_circle,
                  color: AppColors.emerald400,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Perfect recall!',
                  style: GoogleFonts.inter(
                    color: AppColors.emerald400,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

        // Check button
        if (!allCorrect)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: SizedBox(
                width: double.infinity,
                child: GestureDetector(
                  onTap: _checkOrder,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: AppColors.emerald500,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.emerald500.withValues(alpha: 0.40),
                          blurRadius: 16,
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'Check Order',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ===========================================================================
  // GAME B — Next Ayah Challenge
  // ===========================================================================
  Widget _buildGameB() {
    if (_questions.isEmpty) {
      // Edge case: chunk with < 2 ayat.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ProgressController().markRecallCompleted(
            widget.surah.number,
            widget.chunk.index,
          );
          setState(() => _step = _RecallStep.complete);
        }
      });
      return const SizedBox.shrink();
    }

    final q = _questions[_questionIndex];

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Progress label
          Text(
            'Question ${_questionIndex + 1} of ${_questions.length}',
            style: GoogleFonts.inter(
              color: AppColors.emerald200.withValues(alpha: 0.50),
              fontSize: 12,
              fontWeight: FontWeight.w500,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 4),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: (_questionIndex + 1) / _questions.length,
              minHeight: 4,
              backgroundColor: Colors.white.withValues(alpha: 0.08),
              valueColor: const AlwaysStoppedAnimation(AppColors.emerald500),
            ),
          ),
          const SizedBox(height: 20),

          // Prompt card
          GlassPanel(
            borderRadius: 20,
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Text(
                  'What comes after this ayah?',
                  style: GoogleFonts.inter(
                    color: AppColors.emerald200.withValues(alpha: 0.50),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  q.prompt.arabic,
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.center,
                  style: AppTheme.quranTextStyle.copyWith(fontSize: 26),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Options
          ...List.generate(q.options.length, (i) {
            final option = q.options[i];
            final isSelected = _selectedOption == i;
            final isCorrectOption = option.number == q.correctAnswer.number;

            Color? borderColor;
            Color? bgColor;
            if (isSelected) {
              if (isCorrectOption) {
                borderColor = AppColors.emerald400.withValues(alpha: 0.60);
                bgColor = AppColors.emerald400.withValues(alpha: 0.10);
              } else {
                borderColor = Colors.redAccent.withValues(alpha: 0.60);
                bgColor = Colors.redAccent.withValues(alpha: 0.08);
              }
            }
            // If user got it wrong and this is the correct answer, highlight it.
            if (_selectedOption != null &&
                !_answered &&
                isCorrectOption &&
                _selectedOption != i) {
              borderColor = AppColors.emerald400.withValues(alpha: 0.40);
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GestureDetector(
                onTap: () => _selectOption(i),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: bgColor ?? Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color:
                          borderColor ?? Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Row(
                    children: [
                      // Letter badge
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.06),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          String.fromCharCode(65 + i), // A, B, C
                          style: GoogleFonts.inter(
                            color: AppColors.emerald200,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          option.arabic,
                          textDirection: TextDirection.rtl,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.scheherazadeNew(
                            color: Colors.white,
                            fontSize: 18,
                            height: 1.8,
                          ),
                        ),
                      ),
                      if (isSelected && isCorrectOption)
                        const Icon(
                          Icons.check_circle,
                          color: AppColors.emerald400,
                          size: 20,
                        ),
                      if (isSelected && !isCorrectOption)
                        Icon(
                          Icons.cancel,
                          color: Colors.redAccent.withValues(alpha: 0.70),
                          size: 20,
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

  // ===========================================================================
  // COMPLETE
  // ===========================================================================
  Widget _buildComplete() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
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
              Icons.psychology,
              size: 56,
              color: AppColors.emerald400,
            ),
          ),
          const SizedBox(height: 28),
          Text(
            'Recall Complete!',
            style: GoogleFonts.amiri(color: Colors.white, fontSize: 28),
          ),
          const SizedBox(height: 8),
          Text(
            '${widget.surah.name} — ${widget.chunk.rangeLabel}\n'
            'Both games finished successfully.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: AppColors.emerald100.withValues(alpha: 0.50),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 36),
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
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
                'Back to Surahs',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Helper model
// ---------------------------------------------------------------------------
class _NextAyahQuestion {
  final Ayah prompt;
  final Ayah correctAnswer;
  final List<Ayah> options;

  _NextAyahQuestion({
    required this.prompt,
    required this.correctAnswer,
    required this.options,
  });
}
